---
title: Amazon EC2 Micro Instances (t1.micro)
author: Aaron
layout: post
permalink: /amazon-ec2-micro-instances-t1micro/
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
  - Linux nginx ec2 amazon systems
---
Amazon recently announced a new instance type &#8211; &#8220;micro instances.&#8221; Â They are wicked cheap ($54 + $0.007/hrÂ for a 1-year [reserved instance][1] + $.10/GB per month storage) and finally make Amazon accessible to the non-business user with a few low-traffic websites. Â For a typical Ubuntu 10.04 LTS (Lucid) installation with a 15GB root partition, that is only $133.32 a year for your very own server in the cloud! Â I&#8217;ve been with [Dreamhost][2] for a couple years because they are inexpensive and allow shell access and &#8220;unlimited&#8221; storage*. Â  However, as a professional Systems Engineer, I&#8217;ve been wanting to move to something that allowed me to &#8220;own&#8221; my server. Â There are many VPS (Virtual Private Server) providers out there, including [Dreamhost][3] and [Linode][4] (arguably the king of Linux VPS), but they never excited me very much. I&#8217;ll be honest and admit that I didn&#8217;t spend any time performing a detailed cost and feature analysis between the leading VPS providers, though. My day job is working with a couple hundred EC2 instances complete with dynamic spinup and spindown for capacity, so EC2 is a comfortable environment for me. Â I&#8217;ve been wanting to move into EC2 for a while, but could never justify the cost of a m1.small, though. Â Last week, I dived in and have moved all of my hosting over to a t1.micro (t for tiny?) instance.

Here is what Amazon [has to say][5] about the new Micro Instances (t1.micro):

&#8220;Instances of this family provide a small amount of consistentÂ CPUÂ resources and allow you to burstÂ CPUÂ capacity when additional cycles are available. They are well suited for lower throughput applications and web sites that consume significant compute cycles periodically.

*   Micro Instance 613 MB of memory, up to 2 ECUs (for short periodic bursts),Â EBSÂ storage only, 32-bit or 64-bit platform&#8221;

Amazon has a good deal of information in their [FAQ][6] and a very detailed view of usage models in their [User Guide][7].

After a few days with this new instance type, I&#8217;ve noticed CPU time is **very** limited. CPU bursts can only be very brief and it appears that you are penalized when you exceed your quota. Â I run a zenphoto gallery that brought my instance to a crawl when trying to batch resize a bunch of images with ImageMagick. It was so bad that php was unable to return simple pages before the 60 second fast cgi timeout on the nginx process. Â However, with appropriate caching strategies, these machines are more than capable of running a low traffic website. Using Apache Bench, I was able to get 1000 rpm out of the front page of this blog. That&#8217;s with the entire application stack residing on a single machine! I will elaborate more on my configuration in a future blog post.

There are a couple catches with this instance type. Storage is only EBS, which means you have to pay $0.10/GB per month above the cost of the instance time. Â Also, like all hosting within Amazon, the individual instances are completely unreliable. You need to make sure that you can recreate your nodes from scratch at any point. For me this means documentation, automation, monitoring, backups, and most of all keeping everything important on a separate EBS volume so it can be moved around easily in the event of an instance failure. Even though the root partition of t1.micro instances is EBS, it is a lot easier to move data around if you don&#8217;t have to terminate the old instance before bringing up a new one.

* * *

** That&#8217;s unlimited for web use &#8211; not for backups. Â They noticed my 300GB of photo backups and very politely asked me to move them to a backup account and even allowed me to keep the data there for a week while I migrated it.*</p> <div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_14">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Famazon-ec2-micro-instances-t1micro%2F&linkname=Amazon%20EC2%20Micro%20Instances%20%28t1.micro%29" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Famazon-ec2-micro-instances-t1micro%2F&linkname=Amazon%20EC2%20Micro%20Instances%20%28t1.micro%29" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Famazon-ec2-micro-instances-t1micro%2F&linkname=Amazon%20EC2%20Micro%20Instances%20%28t1.micro%29" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://aws.amazon.com/about-aws/whats-new/2009/03/12/amazon-ec2-introduces-reserved-instances/
 [2]: http://dreamhost.com
 [3]: http://www.dreamhost.com
 [4]: http://www.linode.com
 [5]: http://aws.amazon.com/ec2/instance-types/
 [6]: http://aws.amazon.com/ec2/faqs/#How_much_compute_power_do_Micro_instances_provide
 [7]: http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?concepts_micro_instances.html