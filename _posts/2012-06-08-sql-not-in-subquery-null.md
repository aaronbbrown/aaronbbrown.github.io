---
title: NOT IN with NULLs in the Subquery
author: Aaron
layout: post
permalink: /sql-not-in-subquery-null/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - mysql
tags:
  - mysql
  - sql
  - Technology
---
A coworker came to me with a perplexing issue. He wanted to know why these two queries were not returning the same results:

<pre>mysql> SELECT COUNT(*) 
    -> FROM parent
    -> WHERE id NOT IN (SELECT parent_id FROM child);
+----------+
| count(*) |
+----------+
|        0 |
+----------+
1 row in set (7.84 sec)
</pre>

<pre>mysql> SELECT COUNT(*)
    -> FROM parent p
    -> WHERE NOT EXISTS(SELECT 1 
    ->                  FROM child c
    ->                  WHERE p.id = c.parent_id);
+----------+
| count(*) |
+----------+
|     5575 |
+----------+
1 row in set (2.95 sec)
</pre>

At first (and second, and third) glance these two queries look identical. It obviously is an <a href="http://www.xaprb.com/blog/2005/09/23/how-to-write-a-sql-exclusion-join/" target="_blank">exclusion join</a> and because the MySQL optimizer is what it is, I decided to rewrite it as a LEFT JOIN to see what results came back:

<pre>mysql> SELECT COUNT(*) FROM parent p
    -> LEFT JOIN child c ON p.id = c.parent_id
    -> WHERE c.id IS NULL;
+----------+
| COUNT(*) |
+----------+
|     5575 |
+----------+
1 row in set (2.90 sec)
</pre>

The LEFT JOIN returned the same results as the NOT EXISTS version. Why did the NOT IN query return 0 results? Since it was a beautiful day and I am completely unable to solve problems while sitting at the computer, I went for a walk.

After I returned and changed my thunderstorm-soaked clothes, I had a thought of something&#8230;

<pre>mysql> SELECT COUNT(*)FROM child WHERE parent_id IS NULL;
+----------+
| count(*) |
+----------+
|     3686 |
+----------+
1 row in set (0.20 sec)
</pre>

There are NULLs in the pseudo-foreign key (this database does not have explicit foreign key constraints). What if the NULLs are excluded from the dependent subquery in the NOT IN clause?

<pre>mysql> SELECT COUNT(*)
    -> FROM parent
    -> WHERE id NOT IN (SELECT parent_id 
    ->                  FROM child 
    ->                  WHERE parent_id IS NOT NULL);
+----------+
| count(*) |
+----------+
|     5575 |
+----------+
1 row in set (7.67 sec)
</pre>

Sure enough, the NULLs were the issue. But, why? Let&#8217;s think about a simpler case with constant values instead of subqueries. These two queries (using the sakila database) are logically equivalent:

<pre>mysql> SELECT COUNT(*) FROM actor WHERE actor_id NOT IN (1,2,3,4);
+----------+
| COUNT(*) |
+----------+
|      199 |
+----------+
1 row in set (0.13 sec)

mysql> SELECT COUNT(*) FROM actor 
    -> WHERE actor_id &lt;> 1 
    ->   AND actor_id &lt;> 2
    ->   AND actor_id &lt;> 3
    ->   AND actor_id &lt;> 4;
+----------+
| COUNT(*) |
+----------+
|      199 |
+----------+
1 row in set (0.06 sec)
</pre>

What if there is a NULL in there?

<pre>mysql> SELECT COUNT(*) FROM actor
    -> WHERE actor_id &lt;> 1
    ->   AND actor_id &lt;> 2
    ->   AND actor_id &lt;> 3
    ->   AND actor_id &lt;> 4
    ->   AND actor_id &lt;> NULL ;
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
1 row in set (0.00 sec)
</pre>

The reason why this returns 0 results is that <tt>column <> NULL</tt> (or <tt>column = NULL</tt>, for that matter) always evaluates to NULL. NULL doesn&#8217;t **equal** anything. It is just NULL. <tt>TRUE AND TRUE AND TRUE AND <strong>NULL</strong></tt> always evaluates to NULL. An illustration:

<pre>mysql> SELECT TRUE AND FALSE;
+----------------+
| TRUE AND FALSE |
+----------------+
|              0 |
+----------------+
1 row in set (0.00 sec)

mysql> SELECT TRUE AND TRUE;
+---------------+
| TRUE AND TRUE |
+---------------+
|             1 |
+---------------+
1 row in set (0.00 sec)

mysql> SELECT TRUE AND NULL;
+---------------+
| TRUE AND NULL |
+---------------+
|          NULL |
+---------------+
1 row in set (0.00 sec)

mysql> SELECT 1=NULL;
+--------+
| 1=NULL |
+--------+
|   NULL |
+--------+
1 row in set (0.00 sec)
</pre>

Here&#8217;s the final proof of the NULL problem:

<pre>mysql> SELECT COUNT(*) FROM actor WHERE actor_id NOT IN (1,2,3,4,NULL);
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
1 row in set (0.00 sec)
</pre>

The moral of the story is, if you use NOT IN with a dependent subquery, make sure you exclude NULLs. This problem would also go away if there had been explicit foreign key constraints, which would enforce referential integrity. Additionally, as you can see from the performance differences above, NOT IN with a subquery is horribly optimized in MySQL pre-5.6, so just don&#8217;t do this at all on MySQL and use one of the other two derivations instead.

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_26">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fsql-not-in-subquery-null%2F&linkname=NOT%20IN%20with%20NULLs%20in%20the%20Subquery" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fsql-not-in-subquery-null%2F&linkname=NOT%20IN%20with%20NULLs%20in%20the%20Subquery" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fsql-not-in-subquery-null%2F&linkname=NOT%20IN%20with%20NULLs%20in%20the%20Subquery" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>