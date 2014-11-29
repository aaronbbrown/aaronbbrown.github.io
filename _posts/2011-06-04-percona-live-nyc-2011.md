---
title: Percona Live NYC 2011
author: Aaron
layout: post
permalink: /percona-live-nyc-2011/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - Uncategorized
---
A couple weeks back, I had the fortune of co-speaking at [Percona Live NYC 2011][1] with Mark Uhrmacher, CTO of [ideeli][2] on the subject of running an E-commerce site with MySQL in the cloud. Interestingly, and a sign of the times, this was also the first time that I had ever met Mark, despite having worked for him for close to a year since I telecommute from home.

[Here are the slides][3] from that talk.

What I wanted attendees to get out of our talk was that you have to expect and plan for all sorts of failure situations when your database is in the cloud. Relative to conventional hosting or datacenters, things in the cloud break more frequently and in ways that are out of your control. AWS gives you the tools to plan and recover from these failures much more easily than having to put redundant physical servers in multiple geographic locations, but they also fail more often.

So, here are a few take-aways, mentioned in the slides

*   RAID 1 or RAID 10 (1+0) your EBS volumes  
    Yes, EBS volumes are redundant on the back end, in a data center controlled by Amazon. However, the great EBS outage of 2011 (#ec2pocalypse) proves that you cannot entrust your data to a single technology that is out of your control. Had we RAID0&#8217;d our data set, we would have been in much worse shape, because we would have to completely rebuild many of our data sets from backup. So, no, you should not RAID0 (which should rightfully be called AID0, since the R is a fallacy). Yes, you take a performance hit, and you have to deal with lowest-common-denominator performance of the EBS volumes, but the ability to remove a failed or poorly performing EBS volume without losing your data more than makes up for that compromise. With 10 EBS volumes in a RAID 10 configuration, we max out at around 1200-1500 iops. Poor performance relative to physical hardware, but it is manageable.
    
    If you care about your data, never ever use RAID0. You might as well just point it at <tt>/dev/null</tt>, which as we know is [webscale][4]. **Friends don&#8217;t let friends RAID0**

*   Make sure your important data lives in multiple availability zones and multiple regions.</p> 
    During #ec2pocalypse, several instances were able to be recovered by simply pointing the application at data that already existed in another zone. 

*   Don&#8217;t cross availability zones and regions between your ultimate master and your disaster recovery node.</p> 
    If so, (and we were bit by this), you may end up with out of date disaster recovery nodes if your distribution slave is in an affected availability zone. Keep replication chains short and all in one zone/region, except for the DR node, which should be somewhere outside of the master&#8217;s zone/region. </li> 

AWS snapshot backups are awesome. But they don&#8217;t help if the API is down. Make sure your data lives in multiple places where you can get at it in an emergency. </li> </ul> 
Also, I&#8217;d just like to say that Percona Live was a great conference. There were some incredibly informative talks. My favorite, by far, was Baron Schwartz&#8217;s discussion on using tcpdump to analyze server performance and predict scalability. I was honored to speak in front of a crowd where the average person in the room knows far more about MySQL than I do.

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_18">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fpercona-live-nyc-2011%2F&linkname=Percona%20Live%20NYC%202011" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fpercona-live-nyc-2011%2F&linkname=Percona%20Live%20NYC%202011" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fpercona-live-nyc-2011%2F&linkname=Percona%20Live%20NYC%202011" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://www.percona.com/live/nyc-2011/
 [2]: http://ideeli.com
 [3]: http://9minutesnooze.com/download/Percona_Live_NYC_2011_MySQL_Cloud.pdf
 [4]: http://www.xtranormal.com/watch/6995033/mongo-db-is-web-scale