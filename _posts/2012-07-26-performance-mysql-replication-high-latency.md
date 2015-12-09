---
title: Performance of MySQL Semi-Synchronous Replication Over High Latency Connections
author: Aaron
layout: post
permalink: /performance-mysql-replication-high-latency/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - mysql
tags:
  - aws
  - ec2
  - mysql
  - replication
  - sql
---
I have seen a few posts on <a href="http://dba.stackexchange.com" target="_blank">DBA.SE</a> (where I <a href="http://dba.stackexchange.com/users/3858/aaron-brown?tab=answers" target="_blank">answer a lot of questions</a>) recommending the use of <a href="http://dev.mysql.com/doc/refman/5.5/en/replication-semisync.html" target="_blank">semi-synchronous replication</a> in MySQL 5.5 over a WAN as a way to improve the reliability of replication. My gut reaction was that this is a very bad idea with even a tiny write load, but I wanted to test it out to confirm. Please note that I do not mean to disparage the author of those posts, a user whom I have great respect for.

## What is semi-synchronous replication?

The short version is that one slave has to acknowledge receipt of the binary log event before the query returns. The slave doesn&#8217;t have to execute it before returning control so it&#8217;s still an asynchronous commit. The net effect is that the slave should only miss a maximum of 1 event if the master has a catastrophic failure. It does not improve the reliability of replication itself or prevent data drift.

What about performance, though? Semi-synchronous replication causes the client to block until a slave has acknowledged that it has received the event. On a LAN with sub-millisecond latencies, this should not present much of a problem. But what if there is 85ms of latency between the master and the slave, as is the case between Virginia and California? **My hypothesis is that, with 85ms of latency, it is impossible to get better than 11 write queries (INSERT/UPDATE/DELETE) per second** &#8211; 1000ms / 85ms = 11.7.

Let&#8217;s test that out.

I spun up identical <a href="http://aws.amazon.com/ec2/instance-types/" target="_blank">m1.small</a> instances in EC2&#8217;s us-east-1 and us-west-1 regions using the latest Ubuntu 12.04 LTS AMI from <a href="http://alestic.com" target="_blank">Alestic</a> and installed the latest <a href="http://www.percona.com/software/percona-server/" target="_blank">Percona Server 5.5</a> from their <a href="http://www.percona.com/doc/percona-server/5.5/installation/apt_repo.html" target="_blank">apt repository</a>.

{% highlight bash %}
gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
gpg -a --export CD2EFD2A | apt-key add -
echo deb http://repo.percona.com/apt precise main > /etc/apt/sources.list.d/percona.list
apt-get update
apt-get install percona-server-server-5.5 libmysqlclient-dev
{% endhighlight %}

Although mostly irrelevant to the benchmarks, my.cnf is configured thusly (basically identical to support-files/my-huge.cnf shipped with the distribution):

{% highlight ini %}
[mysqld]
port          = 3306
socket          = /var/run/mysql/mysql.sock
skip-external-locking
key_buffer_size = 384M
max_allowed_packet = 1M
table_open_cache = 512
sort_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size = 32M
thread_concurrency = 8

server-id     = 1
log-bin=mysql-bin
binlog_format=mixed

innodb_data_home_dir = /var/lib/mysql
innodb_data_file_path = ibdata1:2000M;ibdata2:10M:autoextend
innodb_log_group_home_dir = /var/lib/mysql
innodb_buffer_pool_size = 384M
innodb_additional_mem_pool_size = 20M
innodb_log_file_size = 100M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 0
innodb_lock_wait_timeout = 50
{% endhighlight %}

Then, I wrote a very simple Ruby script to perform 10k inserts into a table, using the [sequel gem][1], which I love.

{% highlight bash %}
apt-get install rubygems
gem install sequel mysql2 --no-rdoc --no-ri
{% endhighlight %}

{% highlight ruby %}
#!/usr/bin/env ruby
# insertperf.rb

require 'logger'
require 'rubygems'
require 'sequel'

logger = Logger.new(STDOUT)
localdb = "inserttest"

db = Sequel.connect( :database => localdb,
                     :adapter  => 'mysql2',
                     :user     => 'root',
                     :logger   => logger )

db["DROP DATABASE IF EXISTS #{localdb}"].all
db["CREATE DATABASE #{localdb}"].all
db["CREATE TABLE IF NOT EXISTS #{localdb}.foo (
  id int unsigned AUTO_INCREMENT PRIMARY KEY,
  text VARCHAR(8)
) ENGINE=InnoDB"].all

n = 10000
t1 = Time.new
n.times do
  value = (0...8).map{65.+(rand(25)).chr}.join
  db["INSERT INTO #{localdb}.foo (text) VALUES (?)", value].insert
end
t2 = Time.new
elapsed = t2-t1
logger.info "Elapsed: #{elapsed} seconds. #{n/elapsed} qps"
{% endhighlight %}

With MySQL configured, let&#8217;s knock out a few INSERTs into the us-east-1 database, which has no slaves:

    # w/ no slaves
    ...
    INFO -- : (0.000179s) INSERT INTO test.foo (text) VALUES ('FKGDLOWD')
    ...
    INFO -- : Elapsed: 9.37364 seconds. 1066.82142689499 qps

My control is roughly **1000 inserts/sec** with each query taking less than .2ms.

Then, I set up a traditional, asynchronous MySQL slave on the server in us-west-1 and ran the test again:

    # w/ traditional replication
    ...
    INFO -- : (0.000237s) INSERT INTO test.foo (text) VALUES ('CVGAMLXA')
    ...
    INFO -- : Elapsed: 10.601943 seconds. 943.223331798709 qps

Somewhat inexplicably, the performance was slightly worse with the slave attached, but not by much. **~950 inserts/sec**

Next is semi-synchronous replication. First, I tested the latency between us-east-1 and us-west-1.

    # ping -c 1 184.72.189.235
    PING 184.72.189.235 (184.72.189.235) 56(84) bytes of data.
    64 bytes from 184.72.189.235: icmp_req=1 ttl=52 time=85.5 ms

Latency between us-east-1 and us-west-1 is 85ms, so I still predict 11 inserts/sec at most, which means my script will take 15 minutes instead of 10 seconds:

I set up semi-synchronous replication like this:

{% highlight sql %}
master> INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
master> SET GLOBAL rpl_semi_sync_master_enabled = 1;
slave> INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
slave> SET GLOBAL rpl_semi_sync_slave_enabled = 1;
slave> STOP SLAVE; START SLAVE;
{% endhighlight %}

I started the script and, as predicted, each insert was taking approximately 85ms. There was a screaming 2 month old in the next room so in the interest of brevity, I reduced the count from 10k to 1k. That should take about 90s:

    # w/ semi-sync replication
    ...
    INFO -- : (0.086301s) INSERT INTO test.foo (text) VALUES ('JKIJTUDO')
    ...
    INFO -- : Elapsed: 86.889529 seconds. 11.5088666207409 qps

Just as I suspected &#8211; **11 inserts/sec**.

In conclusion, the speed of light is a bitch, so don&#8217;t enable semi-synchronous replication over wide area or high latency networks.

 [1]: http://rubygems.org/gems/sequel
