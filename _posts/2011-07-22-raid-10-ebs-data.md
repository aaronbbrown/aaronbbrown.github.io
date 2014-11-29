---
title: RAID 10 your EBS data
author: Aaron
layout: post
permalink: /raid-10-ebs-data/
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
  - amazon
  - aws
  - cloud
  - ebs
  - ec2
  - syseng
---
When I spoke at [Percona Live][1] ([video here][2]) on running an E-commerce database in Amazon EC2, I briefly talked about using RAID 10 for additional performance and fault tolerance when using EBS volumes. At first, this seems counter intuitive. Amazon has a robust infrastructure, EBS volumes run on RAIDed hardware, and are mirrored in multiple availability zones. So, why bother? Today, I was reminded of just how important it is. Please note that all my performance statistics are based on direct experience running a MySQL database on a m2.4xlarge instance and not on some random bonnie or orion benchmark. I have those graphs floating around on my hard drive in glorious 3D and, while interesting, they do not necessarily reflect real-life performance.

### Why? Part 1. Performance

Let&#8217;s get to the point. EBS is cool and very very flexible, but nominal performance is poor and highly variable with average latencies (svctime in iostat) in the 2-10ms range . At its heart, EBS is Network Attached Storage and shares bandwidth with your instance NIC. At best, I see 1.5ms svctime and 10ms await, and at worst&#8230;well, at worst you don&#8217;t need ms precision to measure it. On top of that, a single EBS volume seems to peak out at around 100-150 iops, which is about what one would expect from a single SATA drive. That&#8217;s fine if you&#8217;re running a low-traffic website with very little disk activity, but once the requests start to come in, things get a little squirrelly. Add in multi-tenancy and a noisy neighbor can really beat your disk into submission.

So, what&#8217;s a lowly Systems Engineer to do when the iowait time starts to pile up? Well, it turns out that those IOPs are initially bound by the disk on the backend and not local NIC traffic, so you can use Linux Software RAID to significantly improve the I/O capacity of your disk (but not the latency or variability&#8230;more on this later). For a performance boost, there is a lot of bad advice on the Internet saying you should RAID 0 your disk (because &#8220;it&#8217;s redundant on the back end&#8221;), but to the the discriminating SysEng, that should scream bad idea.

### Why? Part 2. Redundancy

Right, so EBS is RAIDed and mirrored in multiple availability zones on the back end, so why do I need to worry about redundancy? That&#8217;s great and all, but with the EBS cool factor comes additional complexity and new and unexpected failure modes. The first and most obvious was #ec2pocalypse, otherwise known as the Great Reddit Fail of 2011. If you&#8217;re not aware of what happened (and the details are somewhat irrelevant), but a couple months back someone pressed the wrong button at Amazon and a significant percentage of EBS volumes became &#8220;stuck&#8221; showing 100% utilization and no iops. This failure lasted several days and took out a large number of websites that based their infrastructure on EBS. Most of the data itself was recovered, but a small percentage of people were SOL. So much for redundancy.

Enter RAID10. Yes, it&#8217;s slower than RAID0 because you have to write twice. Yes, you are bound by the worst performing disk in the array. But, you can get nearly 1:1 increase in IOPs (up to a point) and gain the ability to recover your data when Amazon drops the ball.

You need proof? &#8220;Give me an example,&#8221; you say? Let&#8217;s talk about what happened to me today. Everything was just peachy all day &#8211; performance was within parameters and then at 3:15PM, all of a sudden the database started having random query pile ups. Being in EC2, this was not unexpected, but it kept happening. Traffic was on a decline, but we were expecting big traffic in an hour or so. So, I started looking at the disk. We have a 10-drive RAID10 array on our master DB and 1 of those disks was showing svctime in the 30-100ms range, vs 2-10ms on all the others. BINGO!

I didn&#8217;t save the actual iostat output, but sar showed this:

<pre>03:15:01 PM DEV       tps avgqu-sz  await svctm %util
03:35:01 PM dev8-133 7.78     0.11  13.49  2.28  1.77
03:35:01 PM dev8-130 6.54     0.09  14.14  2.27  1.48
03:35:01 PM dev8-149 8.34     0.11  12.62  2.08  1.74
03:35:01 PM dev8-132 7.67     0.10  13.29  1.98  1.52
03:35:01 PM dev8-131 8.66     0.11  12.27  1.91  1.65
03:35:01 PM dev8-147 7.13     0.10  13.77  2.13  1.52
03:35:01 PM dev8-129 7.58     0.08  10.56  1.73  1.31
03:35:01 PM dev8-148 8.47     4.30 506.96 54.77 46.36
03:35:01 PM dev8-146 8.17     0.08   9.28  1.38  1.13
03:35:01 PM dev8-145 6.70     0.26  39.36  6.87  4.60
</pre>

dev8-148 sure looks fishy, eh? (Oh, side note&#8230;to align this data all pretty-like, I used the aptly named [align][3], a great tool from the [Aspersa Toolkit][4])

Had this been a single volume EBS or RAID0 volume, we would have been forced to perform a database failover to a secondary master and redirect the application, which would have interrupted sales briefly during an active time. Instead, thanks to RAID10, we have options. Instead of a failover during a period of relatively high traffic, we simply failed out the problem drive. Now we were running on 9 drives and with reduced redundancy, but performance immediately recovered and the stalls stopped. We can replace the drive later and resync the array when traffic is low.

### How?

First, you need to create and attach &#8220;a bunch&#8221; of volumes to your instance. How many? I&#8217;ve seen diminishing returns after 8-10 disks, but your mileage (and instance size) may vary. Typical RAID10 rules apply here&#8230;you need 2x the total capacity and each disk has to equal 2*(capacity)/(num disks), so if you need 1TB usable and want to use 8 disks, you will need each disk to be 256GB.

Here&#8217;s some code to do that. It creates 8x256GB volumes in the us-east-1a zone and then attaches them to instance i-1a2b3c4d

<pre>for x in {1..8); do \
  ec2-create-volume --size 256 --zone us-east-1a; \
done &gt; /tmp/vols.txt

(i=0; \
for vol in $(awk '{print $2}' /tmp/vols.txt); do \
  i=$(( i + 1 )); \
  ec2-attach-volume $vol -i i-1a2b3c4d -d /dev/sdh${i}; \
done)
</pre>

Then, you need to install Linux Software RAID. On Debian or Ubuntu:  
`apt-get install mdadm`

Then, create a new RAID 10 (-l10) volume from 8 disks (-n8):  
`mdadm --create -l10 -n8 /dev/md0 /dev/sdh*`

With any luck, you&#8217;ll get a message saying that the array was started. You can verify this by looking at /proc/mdstat and you should see something like this (the numbers in this example are probably off. I pulled them together from some random machines)

<pre>cat /proc/mdstat
Personalities : [raid10] 
md0 : active raid10 sdh6[5] sdh5[4] sdh4[3] sdh3[2] sdh2[1] sdh1[0]
      1048575872 blocks 64K chunks 2 near-copies [6/6] [UUUUUU]
      [==>..................]  resync = 13.3% (431292736/3221225280) finish=7721.9min speed=6021K/sec
</pre>

Your disk will spend a lot of time and IOPs resyncing, but you can format /dev/md0 and mount it right away.

This wasn&#8217;t meant as a complete guide to Linux Software RAID &#8211; if you want to know more, check out [The Software-RAID HOWTO][5].

### The Bad

Ok, so the observant among you will realize that by having 8 or 10 disks in the array, all with the potential to have severe performance degradation like this, I have drastically increased the variability of latency. Well, you would be right, but&#8230;

1.  I can&#8217;t get IOPs any other way in EC2
2.  It is easy to recover from the most common failure mode with this setup
3.  If you care about your data at all, RAID0 (or no RAID) is doing it wrong

Remember, kids&#8230;Friends don&#8217;t let friends RAID0.

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_19">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fraid-10-ebs-data%2F&linkname=RAID%2010%20your%20EBS%20data" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fraid-10-ebs-data%2F&linkname=RAID%2010%20your%20EBS%20data" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fraid-10-ebs-data%2F&linkname=RAID%2010%20your%20EBS%20data" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://blog.9minutesnooze.com/percona-live-nyc-2011/
 [2]: http://www.percona.tv/percona-live/running-an-e-commerce-database-in-the-cloud
 [3]: http://aspersa.googlecode.com/svn/html/align.html
 [4]: http://aspersa.googlecode.com/svn/html/index.html
 [5]: http://tldp.org/HOWTO/Software-RAID-HOWTO.html