---
title: 'Don&#8217;t reboot your t1.micro [EC2 epic fail]'
author: Aaron
layout: post
permalink: /reboot-t1micro-ec2/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - Technology
tags:
  - amazon
  - ec2
  - linux
  - Technology
  - ubuntu
---
If you have a t1.micro running an image of Ubuntu 10.04 LTS (Lucid Lynx), ***don&#8217;t reboot it.*** When I [first wrote about t1.micros][1] a few days ago, I forgot to mention that the first instance that I brought up failed, quite catastrophically, upon reboot. I didn&#8217;t actually think much of it at the time because I wasn&#8217;t that far into configuring the machine. But then, yesterday, Alestic released [this note][2] referencing [this bug report][3] saying that there is a bug where t1.micro instances running Lucid won&#8217;t come back up after a restart and that the bug has been fixed. It&#8217;s short, so I&#8217;ll let you read it, but basically the cloud-init package was broken and didn&#8217;t properly expose the ephemeral0 device causing reboots to fail. Alestic says that all you need to do is do an apt-get update && apt-get upgrade and you&#8217;re golden. 

Let me tell you first hand&#8230;that doesn&#8217;t work. This morning, feeling brave, I decided to test the theory out. I was running a t1.micro instance using the old Canonical Ubuntu AMI ami-1634de7f on which I performed an apt-get update and an apt-get upgrade. I saw that the cloud-init package was upgraded, as expected. I initiated a restart and my machine never came back. I initiated a reboot request with ec2-reboot-instances and no dice. Finally, I stopped the instance and then started it with ec2-stop-instances and ec2-start-instances and I still didn&#8217;t have any luck. If I were smart, I would have done this with a test instance first, but I was feeling brave and decided I should test my configuration documentation out anyhow. Mostly, I just wanted to make sure that, if my instance was unable to reboot, it did so at a moment when I had the time and ambition to fix it instead of failing at some inopportune time.

Because everything is EBS backed, using an elastic IP, and my documentation is decent, I was able to detach the volumes from the old instance, attach them to the new instance, and get everything running in less than 30 minutes. At some point when I&#8217;m feeling very ambitious, I intend to put all the configuration in [Puppet][4] to mostly automate the process of migrating to a new instance type, but I&#8217;m not quite there yet.

If you have a t1.micro instance running Lucid, my recommendation is to spin up a new instance with the most recent AMI (the most current AMI ID is available at [Alestic][5]) and move everything over instead of bothering to perform the apt-get upgrade, which clearly did not work in my case.

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_16">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Freboot-t1micro-ec2%2F&linkname=Don%E2%80%99t%20reboot%20your%20t1.micro%20%5BEC2%20epic%20fail%5D" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Freboot-t1micro-ec2%2F&linkname=Don%E2%80%99t%20reboot%20your%20t1.micro%20%5BEC2%20epic%20fail%5D" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Freboot-t1micro-ec2%2F&linkname=Don%E2%80%99t%20reboot%20your%20t1.micro%20%5BEC2%20epic%20fail%5D" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: /amazon-ec2-micro-instances-t1micro/
 [2]: http://alestic.com/2010/09/ec2-ami-canonical-http://alestic.com/2010/09/ec2-ami-canonical-t1micro
 [3]: https://bugs.launchpad.net/ubuntu/+source/cloud-init/+bug/634102
 [4]: http://www.puppetlabs.com
 [5]: alestic.com