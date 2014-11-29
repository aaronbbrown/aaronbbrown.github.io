---
title: 'ANALYZE TABLE is replicated.  RTFM.'
author: Aaron
layout: post
permalink: /analyze-table-replicated-rtfm/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - Technology
  - Uncategorized
tags:
  - ideeli
  - innodb
  - mysql
  - outage
---
Sometimes, I make mistakes. It&#8217;s true. That can be difficult for us Systems Engineering-types to say, but I try to distance myself from my ego and embrace the mistakes because I often learn the most from them. ..Blah, blah, school of hard knocks, blah, blah&#8230;. Usually my mistakes aren&#8217;t big enough to cause any visible impact, but this one took the site out for 10 minutes during a period of peak traffic due to a confluence of events.

Doh!

Here is how it went downâ€¦

We have an issue where MySQL table statistics are occasionally getting out of whack, usually after a batch operation. This causes bad explain plans, which in turn cause impossibly slow queries. An ANALYZE TABLE (or even SHOW CREATE INDEX) resolves the issue immediately, but I prefer not get woken up at 4AM by long running query alerts when my family and I are trying to sleep. As a way to work around the issue, we decided to disable InnoDB automatic statistic calculations by setting [innodb\_stats\_auto_update=0][1]. Then, we would run ANALYZE TABLE daily (via cron) during a low traffic period to force MySQL to update table statistics. This creates more stable and predictable query execution plans and reduces the number of places where we have to add explicit USE/FORCE/IGNORE INDEX clauses in the code to work around the query optimizer.

To accomplish this, I wrote a very simple shell script that runs ANALYZE TABLE against all InnoDB tables. After testing it in a non-production environment, it was pushed out to our passive (unused) master database with puppet. Because it was going to execute in the middle of the night for the first time, I decided to run it by hand once on our passive master database just to make sure everything was kosher. Call me a wimp, but I don&#8217;t like getting up in the middle of the night because my script took the site down (see comment about family and sleeping). We run our master/master databases in active/passive mode, so testing this on the passive server was a safe move.

Theoretically.

A little background on ANALYZE TABLE on InnoDB tables: All it really does is force a recalculation of table statistics and flush the table. A read lock is held for the duration of the statement, so you want to avoid running this on a customer-facing server that is taking traffic. Because the table is flushed, the next thread that needs to access the table will have to open it again. On our servers with FusionIO cards, it takes about 5 seconds to run ANALYZE TABLE on over 250 tables. All this was fine in Myopia City, because I was running this on the passive server. 

Meanwhile, in another zip code, someone was testing out a SELECT against a production data set&#8230;

While I was testing my ANALYZE TABLE script, I receive an ominous, &#8220;yt?&#8221; message in Skype.

(Sidebar: In the history of Operations, has an engineer ever received a &#8220;yt?&#8221; message that lead to something awesome? Like, &#8220;yt? We&#8217;re going to send you a batch of fresh baked cookies every day for the next month.&#8221; That never happens.)

So, now I&#8217;m in a call. SITE DOWN! OMFGWTFBYOB!!! (No, it wasn&#8217;t like that. Really, we&#8217;re pretty cool-headed about stuff like this). This outage appeared to be database related. I logged in and checked the process list to see what was running:

<noscript>
  <pre><code class="language-sql sql">mysql&gt; SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE INFO &lt;&gt; 'NULL' ORDER BY TIME;
*************************** 1. row ***************************
           ID: 19210373
         USER: me
         HOST: localhost
           DB: production
      COMMAND: Query
         TIME: 0
        STATE: executing
         INFO: SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE INFO &lt;&gt; 'NULL' ORDER BY TIME
      TIME_MS: 0
*************************** 2. row ***************************
           ID: 19210713
         USER: user
         HOST: 10.x.x.x:59900
           DB: production
      COMMAND: Query
         TIME: 1
        STATE: Waiting for table
         INFO: SELECT * FROM `table` WHERE (`table`.`l_id` IN (3,11,15,7)) AND (`table`.s_id = 1234)
      TIME_MS: 1474
*************************** 3. row ***************************
           ID: 19154978
         USER: user
         HOST: 10.x.x.x:45915
           DB: production
      COMMAND: Query
         TIME: 1
        STATE: Waiting for table
         INFO: SELECT count(*) AS count_all FROM `table` WHERE (`table`.sku_id = 2345)                                        
      TIME_MS: 3737

&hellip; 180 more queries in "Waiting for table" state &hellip;
*************************** 181. row ***************************
           ID: 19203223
         USER: user
         HOST: 10.x.x.x:34299
           DB: production
      COMMAND: Query
         TIME: 607
        STATE: Waiting for table
         INFO: SELECT * FROM `table` WHERE (`table`.s_id = 4567)                                                                                                         
      TIME_MS: 606530
*************************** 182. row ***************************
           ID: 19203223
         USER: user
         HOST: 10.x.x.x:34299
           DB: production
      COMMAND: Query
         TIME: 607
        STATE: Waiting for table
         INFO: SELECT * FROM `table` WHERE (`table`.s_id = 4567)                                                                                                         
      TIME_MS: 606530
*************************** 182. row ***************************
           ID: 19198325
         USER: user
         HOST: 10.x.x.x:56399
           DB: production
      COMMAND: Query
         TIME: 712
        STATE: Sending data
         INFO: SELECT RUN_LONG_TIME FROM `table`
      TIME_MS: 711545
</code></pre>
</noscript>

(queries modified to protect the guilty)

That&#8217;s&#8230;strange. The RUN\_LONG\_TIME query seems to be blocking all the other queries on that table. But it&#8217;s just a SELECT. I looked at SHOW ENGINE INNODB STATUS and it didn&#8217;t have anything interesting in it. There were no row or table locks, no UPDATE/INSERT/DELETE, or SELECT FOR UPDATE queries, and innodb\_row\_lock_waits was not incrementing. A colleague noted that there were a lot of entries in the MySQL error log, so I looked at that and found (amongst the clutter): 

<noscript>
  <pre><code class="language- ">83109   production.table Locked - write        High priority write lock
83109   production.table Locked - read         Low priority read lock
</code></pre>
</noscript>

We were in an outage and the most important thing at this point was to resume selling shoes, dresses, and lingerie, so I collected as much data as I could for later review, dumped it into Evernote and killed the RUN\_LONG\_TIME query. Bam, the queries in &#8220;Waiting for table&#8221; state finished and the site came back online. Had that not solved the problem, another team member had his finger on the &#8220;fail over to the other server&#8221; button. 

Outage over. Phew.

But, as my toddler likes to say &#8212; &#8220;What just happened?&#8221; The RUN\_LONG\_TIME query was expensive, but it shouldn&#8217;t have been blocking other queries from completing. First step, I went to a reporting server and tried to reproduce it:

<noscript>
  <pre><code class="language-sql sql">session1&gt; SELECT RUN_LONG_TIME FROM table;
session2&gt; SELECT * FROM table WHERE id = 123
</code></pre>
</noscript>

All copasetic. What&#8217;s next, chief?

Time to look at some graphs. Because we have the complete output of SHOW GLOBAL STATUS logging to Graphite every few seconds, it is easy see what the server is doing at any given time. (You should do that, too. It&#8217;s incredibly valuable.) I started poking around at the charts on the active server and noticed a few oddities:

There was a lot of InnoDB buffer pool activity &#8211; several graphs looked like this:  
<a href="http://blog.9minutesnooze.com/analyze-table-replicated-rtfm/innodb_buffer_pool_read_requests/" rel="attachment wp-att-434"><img src="http://blog.9minutesnooze.com/wp-content/uploads/2012/02/innodb_buffer_pool_read_requests.jpg" alt="" title="innodb_buffer_pool_read_requests" width="585" height="306" class="aligncenter size-full wp-image-434" /></a>

That made sense, as the RUN\_LONG\_TIME query was sifting through a lot of data. A lot of data. A lot. 14 quadrillion rows, in my estimate.

After seeing that pattern across a number of other stats, I started poking through the Com\_* variables. Com\_analyze looked like this:  
<a href="http://blog.9minutesnooze.com/analyze-table-replicated-rtfm/com_analyze/" rel="attachment wp-att-435"><img src="http://blog.9minutesnooze.com/wp-content/uploads/2012/02/com_analyze.jpg" alt="" title="com_analyze" width="586" height="307" class="aligncenter size-full wp-image-435" /></a>

What fool ran ANALYZE TABLE a bunch of times at peak traffic on the active database!? This is where I contracted a case of the RTFMs. As it turns out, ANALYZE TABLE statements are written to the binary log and thus replicated unless you supply the LOCAL key word (ANALYZE LOCAL TABLE). 

I had not supplied that keyword.

As a result of my missing keyword, the ANALYZE TABLE statements replicated to the active server during peak traffic periods while a very long running query was in progress. Intuitively that still shouldn&#8217;t have caused this behavior. ANALYZE TABLE takes less than a second on each table. But that isn&#8217;t the whole story&#8230;

Back to the reporting server to attempt to reproduce the behavior:

<noscript>
  <pre><code class="language-sql sql">session1&gt; SELECT RUN_LONG_TIME FROM table;
session2&gt; ANALYZE TABLE table;
session3&gt; SELECT * FROM table WHERE id=123; 
</code></pre>
</noscript>

The statement in session3 hung and was in &#8220;Waiting for table&#8221; status. Success (at failure)!

What happened is the ANALYZE TABLE flushed the table, which tells InnoDB to close all references before allowing access again. Because there was a query running while ANALYZE TABLE was executing, MySQL had to wait for the query to complete before allowing access from another thread. Because that query took so long, everything else hung out in &#8220;Waiting for table&#8221; state. The [documentation][2] on this point sort of explains the issue, though it is a little muddy:

> The thread got a notification that the underlying structure for a table has changed and it needs to reopen the table to get the new structure. However, to reopen the table, it must wait until all other threads have closed the table in question.
> 
> This notification takes place if another thread has used FLUSH TABLES or one of the following statements on the table in question: FLUSH TABLES tbl_name, ALTER TABLE, RENAME TABLE, REPAIR TABLE, ANALYZE TABLE, or OPTIMIZE TABLE. 

I explained the sequence of events and root cause to our team and also publicly flogged myself a bit. As it turns out, this issue only happened because of the combination of two different events happening simultaneously. The ANALYZE TABLE alone wouldn&#8217;t have been a big deal had there not also been a very long running query going at the same time.

I have a few take-aways from this:

*   If you make a mistake, fess up. That&#8217;s a lot better than covering it up and having someone find out about it later. People understand mistakes.
*   Mistakes are the best chances for learning. I can assure you, that I will never, ever forget that ANALYZE TABLE writes to the binary log.
*   Measure everything that you can, always. Without the output of SHOW GLOBAL STATUS being constantly charted in Graphite, I would have been blind to any abnormalities.
*   During an outage, resist the temptation to just &#8220;fix it&#8221; before grabbing data to analyze later. Pressure is on and getting things running is very high priority, but it is even worse if you fix the problem, don&#8217;t know why it occurred, and end up in the same situation again a week later.
*   Try not to perform seemingly innocuous tasks on production servers at peak times.
*   RTFM. Always. Edge cases abound in complex software.

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_22">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fanalyze-table-replicated-rtfm%2F&linkname=ANALYZE%20TABLE%20is%20replicated.%20%20RTFM." title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fanalyze-table-replicated-rtfm%2F&linkname=ANALYZE%20TABLE%20is%20replicated.%20%20RTFM." title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fanalyze-table-replicated-rtfm%2F&linkname=ANALYZE%20TABLE%20is%20replicated.%20%20RTFM." title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://www.percona.com/doc/percona-server/5.1/diagnostics/innodb_stats.html?id=percona-server:features:innodb_stats&redirect=1
 [2]: http://dev.mysql.com/doc/refman/5.1/en/general-thread-states.html