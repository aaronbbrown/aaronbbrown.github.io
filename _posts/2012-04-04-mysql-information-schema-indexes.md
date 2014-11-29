---
title: List MySQL Indexes With INFORMATION_SCHEMA
author: Aaron
layout: post
permalink: /mysql-information-schema-indexes/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - Technology
tags:
  - database
  - innodb
  - mysql
  - Technology
---
Have you ever wanted to get a list of indexes and their columns for all tables in a MySQL database without having to iterate over [SHOW INDEXES][1] FROM &#8216;[table]&#8217;? Here are a couple ways&#8230;

The following query using the [INFORMATION_SCHEMA][2] [STATISTICS][3] table will work prior to MySQL GA 5.6 and Percona Server 5.5. 

<pre>SELECT table_name AS `Table`,
       index_name AS `Index`,
       GROUP_CONCAT(column_name ORDER BY seq_in_index) AS `Columns`
FROM information_schema.statistics
WHERE table_schema = 'sakila'
GROUP BY 1,2;
</pre>

This query uses the [INNODB\_SYS\_TABLES][4], [INNODB\_SYS\_INDEXES][5], and [INNODB\_SYS\_FIELDS][6] tables from INFORMATION_SCHEMA and is [only available in MySQL 5.6][7] or Percona Server 5.5. However, it is much much faster than querying the STATISTICS table. It also **only shows InnoDB tables.**

<pre>SELECT t.name AS `Table`,
       i.name AS `Index`,
       GROUP_CONCAT(f.name ORDER BY f.pos) AS `Columns`
FROM information_schema.innodb_sys_tables t 
JOIN information_schema.innodb_sys_indexes i USING (table_id) 
JOIN information_schema.innodb_sys_fields f USING (index_id)
WHERE t.schema = 'sakila'
GROUP BY 1,2;</pre>

Assuming that all your tables are InnoDB, both queries will produce identical results. If you have some MyISAM tables in there, only the first query will provide complete results.

<pre>+---------------+-----------------------------+--------------------------------------+
| Table         | Index                       | Columns                              |
+---------------+-----------------------------+--------------------------------------+
| actor         | idx_actor_last_name         | last_name                            |
| actor         | PRIMARY                     | actor_id                             |
| address       | idx_fk_city_id              | city_id                              |
| address       | PRIMARY                     | address_id                           |
| category      | PRIMARY                     | category_id                          |
| city          | idx_fk_country_id           | country_id                           |
...
| rental        | rental_date                 | rental_date,inventory_id,customer_id |
| staff         | idx_fk_address_id           | address_id                           |
| staff         | idx_fk_store_id             | store_id                             |
| staff         | PRIMARY                     | staff_id                             |
| store         | idx_fk_address_id           | address_id                           |
| store         | idx_unique_manager          | manager_staff_id                     |
| store         | PRIMARY                     | store_id                             |
+---------------+-----------------------------+--------------------------------------+
42 rows in set (0.04 sec)
</pre>

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_25">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fmysql-information-schema-indexes%2F&linkname=List%20MySQL%20Indexes%20With%20INFORMATION_SCHEMA" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fmysql-information-schema-indexes%2F&linkname=List%20MySQL%20Indexes%20With%20INFORMATION_SCHEMA" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fmysql-information-schema-indexes%2F&linkname=List%20MySQL%20Indexes%20With%20INFORMATION_SCHEMA" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://dev.mysql.com/doc/refman/5.5/en/show-index.html
 [2]: http://dev.mysql.com/doc/refman/5.1/en/information-schema.html
 [3]: http://dev.mysql.com/doc/refman/5.1/en/statistics-table.html
 [4]: http://dev.mysql.com/doc/refman/5.6/en/innodb-sys-tables-table.html
 [5]: http://dev.mysql.com/doc/refman/5.6/en/innodb-sys-indexes-table.html
 [6]: http://dev.mysql.com/doc/refman/5.6/en/innodb-sys-fields-table.html
 [7]: http://dev.mysql.com/tech-resources/articles/whats-new-in-mysql-5.6.html