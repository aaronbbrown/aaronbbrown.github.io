---
title: 'INSERT, Don&#8217;t DELETE'
author: Aaron
layout: post
permalink: /insert-delete/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - mysql
  - Technology
  - Uncategorized
tags:
  - database
  - mysql
  - sql
  - Technology
---
I&#8217;ve been working on a data archival project over the last couple weeks and thought it would be interesting to discuss something a bit counter-intuitive. Absolutes are never true, but when getting rid of data, it&#8217;s usually more efficient to insert the data being kept into a new table rather than deleting the old data from the existing table. 

Here is our example table from the <a href="http://imdbpy.sourceforge.net/docs/README.sqldb.txt  " target="_blank">IMDB database</a>. 

<pre>mysql> show create table title\G
*************************** 1. row ***************************
       Table: title
Create Table: CREATE TABLE `title` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` text NOT NULL,
  `imdb_index` varchar(12) DEFAULT NULL,
  `kind_id` int(11) NOT NULL,
  `production_year` int(11) DEFAULT NULL,
  `imdb_id` int(11) DEFAULT NULL,
  `phonetic_code` varchar(5) DEFAULT NULL,
  `episode_of_id` int(11) DEFAULT NULL,
  `season_nr` int(11) DEFAULT NULL,
  `episode_nr` int(11) DEFAULT NULL,
  `series_years` varchar(49) DEFAULT NULL,
  `md5sum` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_title` (`title`(10)),
  KEY `idx_pcode` (`phonetic_code`),
  KEY `idx_epof` (`episode_of_id`),
  KEY `idx_md5` (`md5sum`),
  KEY `title_kind_id_exists` (`kind_id`),
  CONSTRAINT `title_episode_of_id_exists` FOREIGN KEY (`episode_of_id`) REFERENCES `title` (`id`),
  CONSTRAINT `title_kind_id_exists` FOREIGN KEY (`kind_id`) REFERENCES `kind_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2172322 DEFAULT CHARSET=latin1
</pre>

It has about 2.2 million rows

<pre>mysql> SELECT COUNT(*) FROM title;
+----------+
| count(*) |
+----------+
|  2172320 |
+----------+
1 row in set (1.35 sec)
</pre>

To make this a fair test, let&#8217;s say that we want to get rid of half the records. In this contrived example, &#8216;g&#8217; is the median starting letter. So, we&#8217;re going to get rid of everything that matches /^[0-9a-gA-G]/. The title column is indexed, so building the result set should be reasonably efficient.

<pre>mysql> SELECT COUNT(*) FROM title WHERE title &lt;= 'g';
+----------+
| count(*) |
+----------+
|  1085426 |
+----------+
1 row in set (2.48 sec)

mysql> SELECT COUNT(*) FROM title WHERE title > 'g';
+----------+
| count(*) |
+----------+
|  1086894 |
+----------+
1 row in set (2.60 sec)
</pre>

We&#8217;ll do it my way first and insert the records to keep into a new table:

<pre>mysql> CREATE TABLE new_title LIKE title;
Query OK, 0 rows affected (0.15 sec)

mysql> INSERT INTO new_title SELECT * FROM title WHERE title > 'g';
Query OK, 1086894 rows affected (1 min 5.18 sec)
Records: 1086894  Duplicates: 0  Warnings: 0

mysql> RENAME TABLE original_title TO old_title, new_title TO title
Query OK, 0 rows affected (0.08 sec)

mysql> DROP TABLE old_title;
Query OK, 0 rows affected (0.26 sec)
</pre>

The total time is about 1min 5secs. There are a caveats:

1.  You must be able to stop all writes to the table. This can be done by operating on a slave with the slave threads stopped.
2.  The DROP TABLE statement can take a long time on ext filesystems, though it is nearly instant on xfs.
3.  DROP TABLE can cause stalls on a very active server due to InnoDB buffer pool purging and filesystem activity. Percona Server has a global variable that helps with this, <a href="http://www.percona.com/docs/wiki/percona-server:features:misc_system_variables" target="_blank">innodb_lazy_drop_table</a> and MySQL 5.6 will implement a similar solution. Ovais from Percona compared the performance of these options in their <a href="http://www.mysqlperformanceblog.com/2012/06/22/drop-table-and-stalls-lazy-drop-table-in-percona-server-and-the-new-fixes-in-mysql/" target="_blank">blog</a>.

Now let&#8217;s look at the performance of deleting the unneeded records:

<pre>mysql> DELETE FROM title WHERE title &lt;= 'g';
Query OK, 1085426 rows affected (1 min 26.27 sec)
</pre>

1min, 26secs is a little slower, but not too bad. The thing is, you're probably deleting these records to save some disk space. The table on disk is still the same size.

<pre>anders:imdb root# ls -lh title.* 
-rw-rw----  1 _mysql  wheel   8.8K Jun 26 18:09 title.frm
-rw-rw----  1 _mysql  wheel   572M Jun 26 18:23 title.ibd
</pre>

To reclaim the space, we need to run OPTIMIZE TABLE

<pre>mysql> OPTIMIZE TABLE title;
+-------------+----------+----------+-------------------------------------------------------------------+
| Table       | Op       | Msg_type | Msg_text                                                          |
+-------------+----------+----------+-------------------------------------------------------------------+
| title       | optimize | note     | Table does not support optimize, doing recreate + analyze instead |
| title       | optimize | status   | OK                                                                |
+-------------+----------+----------+-------------------------------------------------------------------+
2 rows in set (1 min 23.72 sec)

anders:test root# ls -lh title.*
-rw-rw----  1 _mysql  wheel   8.8K Jun 26 18:19 title.frm
-rw-rw----  1 _mysql  wheel   304M Jun 26 18:21 title.ibd
</pre>

The space is reclaimed, but it took a total of 2min 50s to get to the same point as in the INSERT example which was nearly 3x faster. This is only relevant with innodb\_file\_per_table set or when using MyISAM. Without <a href="http://dev.mysql.com/doc/refman/5.5/en/innodb-multiple-tablespaces.html" target="_blank">innodb_file_per_table</a>, there is no way to reclaim the space without rebuilding the entire database from a mysqldump.

I picked 1/2 of the table to make this a fair example. As the number of records being removed gets smaller, deleting becomes a more efficient way to get rid of the rows. DELETE can also be done online, where the INSERT technique requires some down time.

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_27">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Finsert-delete%2F&linkname=INSERT%2C%20Don%E2%80%99t%20DELETE" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Finsert-delete%2F&linkname=INSERT%2C%20Don%E2%80%99t%20DELETE" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Finsert-delete%2F&linkname=INSERT%2C%20Don%E2%80%99t%20DELETE" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>