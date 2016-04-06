---
title: Diagnosing MySQL AUTO-INC and Gap Locks
author: Aaron
layout: post
permalink: /diagnosing-mysql-autoinc-gap-locks-ideeli-tech-blog/
categories:
  - mysql
---
At ideeli, there is an asynchronous process that allows internal users to import SKUs into our MySQL database. As ideeli has grown, more people are doing more of the same thing at the same time and the SKU import process had become a pain point. At its core, it simply inserts records into a handful of tables from an uploaded file within a transaction. Subsequently, a cleanup process deletes some data from the same tables. Each import ordinarily takes a few minutes, but when multiple SKU imports are running simultaneously, everything grinds to a near-halt. If an internal user didn’t complain first, Technical Operations would get paged for multiple long running MySQL transactions in the several hour(!!) range. We would kill off the longest running SKU import and the other imports would eventually complete as the locks it held were released. This annoyed people at many levels of the business, but it was a reasonably manageable problem…until it wasn’t…

One day SKU imports were not completing even after running for several hours. Perhaps it was because of an upcoming very large sale - we’re really not sure - but there were over a dozen concurrently running imports and several multi-hour MySQL transactions all trying to insert into the same tables. It now was time to figure out what is actually going on.

`SHOW ENGINE INNODB STATUS` had this text for several transactions:
```
------- TRX HAS BEEN WAITING 42 SEC FOR THIS LOCK TO BE GRANTED:
TABLE LOCK table `db`.`table` trx id 4617 lock mode AUTO-INC waiting
------------------
TABLE LOCK table `db`.`table` trx id 4617 lock mode AUTO-INC waiting
```

Several transactions were waiting on the AUTO-INC lock. So, I went off to the [documentation](http://dev.mysql.com/doc/refman/5.1/en/innodb-auto-increment-handling.html) to read up on how auto increment values are handled…

The gist is that before 5.1.22, every INSERT took a table level auto-increment lock for the duration of the statement to make sure it got the next auto increment value and that everything was replication safe. That’s called “traditional auto-increment locking.” In 5.1.22 and after, the default behavior was changed so that if the number of rows inserted is known in advance (as is most often the case), InnoDB can instead grab a much lighter-weight mutex that is held for a much shorter period of time, thus increasing scalability. This is called “configurable auto-increment locking.” This behavior can be changed by setting [`innodb_autoinc_lock_mode`](http://dev.mysql.com/doc/refman/5.1/en/innodb-parameters.html#sysvar_innodb_autoinc_lock_mode). We had `innodb_autoinc_lock_mode` explicitly set to 0, which means to use the traditional locking. Consequently, all inserts into the same table were serialized, which is a scalability fail.

The locking problem can be reproduced very easily after setting `innodb_autoinc_lock_mode=0` in `my.cnf` and restarting MySQL:

```
#start a long running insert into table a from a big table, b.
session1> INSERT INTO a(a) SELECT a FROM b;   

#while the insert is running:
session2> INSERT INTO a (a) VALUES ('bbbb');
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction

session3> SHOW ENGINE INNODB STATUS\G
...
---TRANSACTION 4617, ACTIVE 2 sec setting auto-inc lock
mysql tables in use 1, locked 1
LOCK WAIT 1 lock struct(s), heap size 376, 0 row lock(s)
MySQL thread id 2, OS thread handle 0x130971000, query id 230 localhost root update
INSERT INTO a (a) VALUES ('bbbb')
------- TRX HAS BEEN WAITING 2 SEC FOR THIS LOCK TO BE GRANTED:
TABLE LOCK table `test`.`a` trx id 4617 lock mode AUTO-INC waiting
------------------
TABLE LOCK table `test`.`a` trx id 4617 lock mode AUTO-INC waiting
---TRANSACTION 4616, ACTIVE 12 sec inserting
mysql tables in use 2, locked 2
2149 lock struct(s), heap size 342456, 1188363 row lock(s), undo log entries 1186217
MySQL thread id 1, OS thread handle 0x12f93a000, query id 229 localhost root Sending data
INSERT INTO a(a) SELECT a FROM b
TABLE LOCK table `test`.`b` trx id 4616 lock mode IS
RECORD LOCKS space id 48 page no 4 n bits 624 index `PRIMARY` of table `test`.`b` trx id 4616 lock mode S
TABLE LOCK table `test`.`a` trx id 4616 lock mode AUTO-INC
TABLE LOCK table `test`.`a` trx id 4616 lock mode IX
...
```

Why would we set `innodb_autoinc_lock_mode=0`? Let’s pull out our Ancient Web History textbook and rewind to ideeli, circa 2009…

Using a combination of tickets carved in limestone and tribal knowledge handed down by the (CTO)racle, I discovered that back in 2009 ideeli had recently upgraded from a 5.0 release of MySQL to 5.1.34. Among the many changes was the addition of configurable auto-increment locking, which became the default. Shortly after our upgrade to 5.1 duplicate primary key errors started appearing. The DBA consulting service we worked with at the time recommended that we change innodb_autoinc_lock_mode back to 0, traditional locking, which we did. The duplicate primary key problems went away. Success!

### Back to Future of 2012 ([where is my hoverboard](http://vimeo.com/11968215)!?)…

The AUTO-INC lock was a clear scalability problem for us. Without re-architecting the SKU import process, there was no way to fix this problem unless we started using configurable auto increment locking (innodb_autoinc_lock_mode=1). After a bunch of research (and examining this very relevant, open bug), we determined that there should not be any problem with switching back to configurable auto-increment locking. A lot can change in 3 years, so we set `innodb_autoinc_lock_mode=1` late one night and anxiously awaited the results when business users started hammering the servers again.

There were no duplicate keys overnight (whew), but early on in the business day I started getting the same complaints…SKU imports were taking forever or never finishing. Back to SHOW ENGINE INNODB STATUS….

```
------- TRX HAS BEEN WAITING 20 SEC FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 45 page no 4 n bits 272 index `idx_someindex` of table `db`.`table` trx id 420A lock_mode X locks gap before rec insert intention waiting
```

Now we were seeing long blocking locks on a secondary index. After some Google time, I found these pages which helped explain the issue:

[InnoDB locking (MySQL @ Facebook)](https://www.facebook.com/note.php?note_id=479123255932)
[InnoDB Record, Gap, and Next-Key Locks](http://dev.mysql.com/doc/refman/5.1/en/innodb-record-level-locks.html)
[Tom Pinckney: MySQL Locking](http://www.tompinckney.com/2008/12/ive-spent-last-week-learning-about.html)

The TL;DR is that when using REPEATABLE READ (the default in InnoDB), locks are taken on the gaps between rows in a secondary index during DELETE operations. The exact reason for this is somewhat complex, but it is necessary in order to avoid phantom reads. (See here for the difference between READ COMMITTED and REPEATABLE READ)

I mentioned above that there was a cleanup process with the SKU import that deleted a bunch of rows. This particular problem was occurring when there was an import running concurrently with a cleanup. The issue can be reproduced very easily with the sample [MySQL Sakila database](http://dev.mysql.com/doc/sakila/en/sakila.html), which has a secondary index on the last_name field:

```
session1> BEGIN;
session1> SELECT * FROM actor WHERE last_name LIKE 'D%';
+----------+------------+-----------+---------------------+
| actor_id | first_name | last_name | last_update         |
+----------+------------+-----------+---------------------+
|       81 | SCARLETT   | DAMON     | 2006-02-15 04:34:33 |
|        4 | JENNIFER   | DAVIS     | 2006-02-15 04:34:33 |
...
|      188 | ROCK       | DUKAKIS   | 2006-02-15 04:34:33 |
|      106 | GROUCHO    | DUNST     | 2006-02-15 04:34:33 |
+----------+------------+-----------+---------------------+
21 rows in set (0.00 sec)

session1> DELETE FROM actor WHERE last_name LIKE 'D%';
session1> SELECT * FROM actor WHERE last_name LIKE 'D%';
Empty set (0.00 sec)

session2> BEGIN;
session2> INSERT INTO actor (first_name,last_name) VALUES ('Bob','Davis');
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction

session3> SHOW ENGINE INNODB STATUS\G
...
---TRANSACTION 420A, ACTIVE 20 sec inserting
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 376, 1 row lock(s), undo log entries 1
MySQL thread id 15, OS thread handle 0x128c71000, query id 249 localhost root update
INSERT INTO actor (first_name,last_name) VALUES ('Bob','Davis');
------- TRX HAS BEEN WAITING 20 SEC FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 45 page no 4 n bits 272 index `idx_actor_last_name` of table `sakila`.`actor` trx id 420A lock_mode X locks gap before rec insert intention waiting
------------------
TABLE LOCK table `sakila`.`actor` trx id 420A lock mode IX
RECORD LOCKS space id 45 page no 4 n bits 272 index `idx_actor_last_name` of table `sakila`.`actor` trx id 420A lock_mode X locks gap before rec insert intention waiting
---TRANSACTION 4209, ACTIVE 27 sec
3 lock struct(s), heap size 1248, 44 row lock(s), undo log entries 21
MySQL thread id 14, OS thread handle 0x128beb000, query id 243 localhost root
TABLE LOCK table `test`.`actor` trx id 4209 lock mode IX
RECORD LOCKS space id 45 page no 4 n bits 272 index `idx_actor_last_name` of table `sakila`.`actor` trx id 4209 lock_mode X
RECORD LOCKS space id 45 page no 3 n bits 272 index `PRIMARY` of table `test`.`actor` trx id 4209 lock_mode X locks rec but not gap
```

So, what can we do?

As it turns out, the gap lock is not taken when a transaction is run in READ COMMITTED isolation level. This makes sense, since with READ COMMITTED other transactions see the most recently committed version of a row and thus there is less overhead in maintaining different versions of each row. After looking at the import process with a developer to ensure that we did not need REPEATABLE READ, the transactions were changed to run in READ COMMITTED isolation level.

The change looked like this:

```
session1> SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
session1> BEGIN;
session1> DELETE FROM actor WHERE last_name LIKE 'D%';Query OK, 21 rows affected (0.07 sec)

session2> SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
session2> BEGIN;
session2> INSERT INTO actor (first_name,last_name) VALUES ('Bob','Davis');Query OK, 1 row affected (0.02 sec)

session1> COMMIT;
session2> COMMIT;
```

The deploy went out later that day, and voila…no more locks. SKU imports now took minutes instead of hours.

