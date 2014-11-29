---
title: 'REPEATABLE READ  vs READ COMMITTED'
author: Aaron
layout: post
permalink: /repeatable-read-read-committed/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - Uncategorized
tags:
  - innodb
  - mysql
  - sql
---
There are four SQL transaction isolation levels [supported by InnoDB][1]: REPEATABLE READ, READ COMMITTED, READ UNCOMMITTED, and SERIALIZABLE. Because READ UNCOMMITTED and SERIALIZABLE are rarely used, I am going to outline the distinction between READ COMMITTED and REPEATABLE READ. Perhaps I will follow up with SERIALIZABLE and READ UNCOMMITTED if there is interest.

**REPEATABLE READ:**  
The state of the database is maintained from the start of the transaction. If you retrieve a value in <tt>session1</tt>, then update that value in <tt>session2</tt>, retrieving it again in <tt>session1</tt> will return the *same* results. *Reads are repeatable*. Repeatable Read.

<pre>session1&gt; BEGIN;
session1&gt; SELECT firstname FROM names WHERE id = 7;
Aaron

session2&gt; BEGIN;
session2&gt; SELECT firstname FROM names WHERE id = 7;
Aaron
session2&gt; UPDATE names SET firstname = 'Bob' WHERE id = 7;
session2&gt; SELECT firstname FROM names WHERE id = 7;
Bob
session2&gt; COMMIT;

session1&gt; SELECT firstname FROM names WHERE id = 7;
Aaron
</pre>

**READ COMMITTED:**  
Within the context of a transaction, you will always retrieve the most recently committed value. If you retrieve a value in <tt>session1</tt>, update it in <tt>session2</tt>, then retrieve it in <tt>session1</tt> again, you will get the value as modified in <tt>session2</tt>. *It reads the last committed row*. Read Committed.

<pre>session1&gt; BEGIN;
session1&gt; SELECT firstname FROM names WHERE id = 7;
Aaron

session2&gt; BEGIN;
session2&gt; SELECT firstname FROM names WHERE id = 7;
Aaron
session2&gt; UPDATE names SET firstname = 'Bob' WHERE id = 7;
session2&gt; SELECT firstname FROM names WHERE id = 7;
Bob
session2&gt; COMMIT;

session1&gt; SELECT firstname FROM names WHERE id = 7;
Bob
</pre>

Make sense?

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_23">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Frepeatable-read-read-committed%2F&linkname=REPEATABLE%20READ%20%20vs%20READ%20COMMITTED" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Frepeatable-read-read-committed%2F&linkname=REPEATABLE%20READ%20%20vs%20READ%20COMMITTED" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Frepeatable-read-read-committed%2F&linkname=REPEATABLE%20READ%20%20vs%20READ%20COMMITTED" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://dev.mysql.com/doc/refman/5.0/en/set-transaction.htm