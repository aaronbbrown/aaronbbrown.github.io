---
title: Mac Mini Media Center/HTPC
author: Aaron
layout: post
permalink: /mac-mini-media-center-htpc-boxee/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - Technology
tags:
  - htpc
  - mac
  - mac mini
  - media center
  - osx
  - Technology
---
[<img class="alignleft size-medium wp-image-125" title="Mac Mini & Remote" src="http://blog.9minutesnooze.com/wp-content/uploads/2009/12/IMG_4046-300x199.jpg" alt="Mac Mini & Remote" width="300" height="199" />][1]Christmas came a little early for me this year and I bought myself a Mac Mini and accessories to be used as a media center for my living room television. I have been wanting to build a home media center/HTPC for some time now and have hemmed and hawed over it. My basic requirements were that it would run something like Boxee, be easily administered remotely via SSH (read: UNIX), support Netflix and Hulu, and be usable by my non-technical (read: doesn&#8217;t work with computers for a living) wife. I basically wanted a set-it and forget-it machine that could be run from the couch with a simple remote control. Windows was not invited to my party, but for others would be completely capable for this task.

<div id="attachment_126" style="width: 310px" class="wp-caption alignright">
  <a href="http://blog.9minutesnooze.com/wp-content/uploads/2009/12/IMG_4708.jpg"><img class="size-medium wp-image-126" title="Mac Mini in Media Cabinet" src="http://blog.9minutesnooze.com/wp-content/uploads/2009/12/IMG_4708-300x199.jpg" alt="Mac Mini in Media Cabinet" width="300" height="199" /></a><p class="wp-caption-text">
    Mac Mini in Media Cabinet
  </p>
</div>

Originally, my plan was to purchase one of the many inexpensive ($200-300) media center PCs available or something like the [Dell Zino][2], which along with Linux, seemed like a perfect solution. However, after much research and with the advice of some helpful coworkers, I learned that Netflix doesn&#8217;t work under Linux. There may be some hacks out there to get it working, but honestly my day job is configuring and administering clusters of Linux machines and I really didn&#8217;t feel like giving myself headaches for my television. So, after much deliberation I mentally justified the Apple tax and ponied up for a Mac Mini (with Snow Leopard). Ok, it wasn&#8217;t *that* hard, given that I already own a 2006 15&#8243; MacBook Pro, a 24&#8243; iMac, and use a 15&#8243; MacBook Pro at work. Somehow, I turned into an Apple Fanboy over the last couple years. 

The configuration described below is the one I settled on based on my existing TV and sound system (both low-end, but adequate for me). I&#8217;ve provided a bunch of links down below that go into more elaborate setups, including using the Mini as an over-the-air HD tuner and DVR.

#### Hardware:

*   [Mac Mini (MC238LL) ][3] [$599.00]
The Mac Mini is a late-2009 model, with a 2.26 GHz Intel Core 2 Duo processor, 160GB Internal HD, and 2GB of RAM&#8230;the most basic model they offer. Because I have a corporateperks.com account, I was able to get this for $563.00. [Amazon][4] has them for a little cheaper [$574.95 and no sales tax] than the Apple Store.

*   [Apple Remote (MC377LL)][5] [$19.00]
It&#8217;s all aluminum and [very sexy][6]. Because of the corporateperks account, I was able to get this for $17.00.

*   [Western Digital Elements 1.5TB External HD (WDBAAU0015HBK) ][7][$99.99 via Holiday sale, regularly $119.99]

#### Cables/Adapters:

*   An HDMI Cable
[Monoprice][8] has several of them starting as [cheap as $3][9]. For short runs, as long as the cable is up to spec, there is no difference in visual and audio quality between a $3 [Monoprice][8] cable and a $130 Monster cable (P.T. Barnum would be proud).

*   [Mini-DVI to HDMI Adapter ][10] [$6.94]
*   [6FT 3.5mm Stereo Male to 2RCA Male Cable ][11][$3.24]
If you want digital audio to go over HDMI, you could get one of these instead of the MiniDVI->HDMI and 1/8&#8243;->RCA cables:

*   [Mini Displayport Male and USB Male Audio to HDMI Female Converting Adapter][12] [$37.94]

I stupidly purchased a MiniDVI->DVI adapter so I could plug my monitor into the Mac Mini for setup, but the Mac Mini comes with this adapter already. I was only a few bucks, but still&#8230;

#### Software:

*   [Boxee][13] or [Plex][14] [both FREE]
*   [Remote Buddy][15] [19.99 â‚¬ which is about $28] or [SofaControl][16] [$15]
*   [MacPorts][17] for all those missing standard UNIX command-line utilities that Apple forgot to include (wget, curl, watch, git, unrar, etc.)
*   [JollysFastVNC][18] (not necessary if your WiFi connection is better than mine)
*   [Candelair IR driver][19]

#### Remote Control:

[<img class="alignleft size-medium wp-image-120" title="Apple Remote" src="http://blog.9minutesnooze.com/wp-content/uploads/2009/12/IMG_4570-Edit-300x200.jpg" alt="Apple Remote" width="300" height="200" />][20]I chose to use the standard Apple Remote control since my primary usage of this machine will be to run [Boxee][21] and it doesn&#8217;t require a lot of functionality to use to the fullest. The Apple Remote has 7 buttons &#8211; up, down, left, right, center, Menu, and Play/Pause. If you want to completely live in the Boxee (or Plex) world, this is all you need, really. However, I wanted to be able to start a few applications, have a virtual mouse, and perform a few other system-related tasks without the assistance of SSH or VNC, so I installed [Remote Buddy][15]. It extends the functionality of the remote &#8211; you just hold the menu button for a second or so and a separate menu pops up that allows you to perform all sorts of tasks (called &#8220;Behaviours&#8221; in the Remote Buddy world&#8230;yes, they are British) such as opening applications, rebooting the system, adjusting the volume, and even operating the mouse cursor with the remote control. These functions are very helpful particularly when Boxee crashes (which it seems to do quite frequently). Remote Buddy has built in actions for many common media center applications, including Boxee, Plex, VLC, and even Firefox.

The Apple Remote supposedly doesn&#8217;t work very well with Snow Leopard, according to various reports and the Plex startup screen. Not wanting to learn the hard way, I just installed the recommended [Candelair][19] IR driver. This replaces the OSX IR Receiver driver and seems to work just great. I believe this was addressed in a Snow Leopard Service Pack (10.6.2), but I haven&#8217;t bothered testing since the Candelair driver works well, is free, and is made by the same people who make [Remote Buddy][15].

#### Remote Access:

<div id="attachment_111" style="width: 240px" class="wp-caption alignright">
  <a href="http://blog.9minutesnooze.com/wp-content/uploads/2009/12/Screen-shot-2009-12-29-at-5.34.44-PM.png"><img class="size-full wp-image-111" title="Screen Sharing" src="http://blog.9minutesnooze.com/wp-content/uploads/2009/12/Screen-shot-2009-12-29-at-5.34.44-PM.png" alt="Screen Sharing Settings" width="230" height="321" /></a><p class="wp-caption-text">
    Screen Sharing Settings
  </p>
</div>For remote access, I use a combination of SSH and VNC. Because I have a weak wireless 802.11g connection in the living room, the built-in Apple Screen Sharing.app wasn&#8217;t connecting properly to the Mac Mini. After a good deal of troubleshooting, I came to the conclusion that it was a client-based problem and not the fault of the built-in VNC server on the Mac Mini. Apple Screen Sharing is simply an extension on the VNC protocol, so I tried a number of VNC applications &#8211; 

[JollysFastVNC][18] was the best and even supported BonJour. I had to dial down the Color Depth to 16 bit for things to work, but now it runs reasonably smooth. To get JollysFastVNC to pass along all special characters (such as Cmd-Tab), I had to go to System Preferences->Universal Access and check &#8220;Enable access for assistive devices&#8221; on the Mini. On the client, I had to set Keyboard input to Immersive in JollysFastVNC. Now, VNCing to the Mini is mostly seamless, though still kind of slow due to my poor wireless signal.

To enable Screen Sharing, SSH, and File Sharing, go into Apple Menu->System Preferences->Sharing and check off Screen Sharing, File Sharing, and Remote login. Make sure to apply the permissions most relevant to your setting. It&#8217;s conveniences like this that lead me down the Mac Mini path versus a Linux-based solution. 

#### Storage:

The 160GB local disk included with the Mac Mini was simply not enough for a media center storing 720p and 1080p HD content. I looked into several options including the super-slick [miniStack][22] which is the same form factor as the Mini, but ultimately I decided that the form factor and faster hard drive was just not important enough to justify the extra expense. A co-worker sent me a deal at Dell.com for a bare-bones Western Digital Elements 1.5TB USB drive for $99 and I jumped on it. It is quiet and fast enough for me. Additionally, it doesn&#8217;t have any lights on it, so it is stealthy in my media cabinet.

#### Configuration:

Really, there was very little configuration involved. The Mini correctly identified my video resolution and looked great on the TV. All I had to do to get things working was plug everything in and install the software. To make sure everything started on boot, I went into the System Preferences->Accounts->Login Items pane and added Remote Buddy and Boxee as Login items. Now, when I restart the computer, everything comes up ready to go. I also enabled Automatic login in the Accounts->Login Options preferences pane. 

[<img src="http://blog.9minutesnooze.com/wp-content/uploads/2010/01/Screen-shot-2010-01-02-at-5.15.51-PM-300x102.png" alt="" title="Fixing Play/Pause Button" width="300" height="102" class="alignright size-medium wp-image-134" />][23]By default, the new Play/Pause button and the Select (middle) button on the new Apple Remote seem to have the exact same behavior. This was annoying in Boxee because I had to click twice to pause running media. After whining about it (and originally including it in the &#8220;Problems&#8221; section below), I discovered that Remote Buddy allows very granular control over the function of every button. I went into Remote Buddy->Preferences->Mapping and under &#8220;Behaviours&#8221;->Boxee, I set Play/Pause to the Pause action. This had the effect of working as both a Pause and an Un-pause button when watching media in Boxee. Problem solved!

#### Problems:

*   Fast Forward/Rewind Media &#8211; It&#8217;s difficult to fast forward or rewind media. Local media skips ahead at least 1 minute (or 10 minutes if you use the second of the two fast forward options in Boxee), but to smoothly fast-forward or skip ahead only a few seconds doesn&#8217;t seem to work very well. In streaming environments, such as Hulu and Netflix, fast-forwarding and rewinding is unreliable at best and just plain doesn&#8217;t work sometimes.
*   Boxee crashes. A lot. Mostly when using [Pandora][24]. It can be kind of annoying, but on the other hand, Boxee is free and still in Alpha. The beta is supposed to be released to the public on January 7, 2010 and I am anxious to give it a try.

#### Resources:

*   [Ultimate Mac mini HTPC Guide][25]
*   [Mac HTPC][26]
*   [123macmini.com &#8211; Mac Mini HTPC][27]
*   [Behold! My Mac mini media center][28]
*   [Howto: Building a Mac Mini Home Media Center][29]

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_12">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fmac-mini-media-center-htpc-boxee%2F&linkname=Mac%20Mini%20Media%20Center%2FHTPC" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fmac-mini-media-center-htpc-boxee%2F&linkname=Mac%20Mini%20Media%20Center%2FHTPC" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fmac-mini-media-center-htpc-boxee%2F&linkname=Mac%20Mini%20Media%20Center%2FHTPC" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://blog.9minutesnooze.com/wp-content/uploads/2009/12/IMG_4046.jpg
 [2]: http://www.dell.com/us/en/corp/desktops/inspiron-zino-hd/pd.aspx?refid=inspiron-zino-hd&s=corp
 [3]: http://www.apple.com/macmini/specs.html
 [4]: http://www.amazon.com/o/ASIN/B002QQ8AJY
 [5]: http://store.apple.com/us/product/MC377LL/A
 [6]: http://www.iospirit.com/blog/article/141/Review-Inside-the-new-Aluminum-Apple-Remote/
 [7]: http://accessories.us.dell.com/sna/products/System_Drives/productdetail.aspx?c=us&l=en&s=bsd&cs=04&sku=A3098103
 [8]: http://www.monoprice.com
 [9]: http://www.monoprice.com/products/product.asp?c_id=102&cp_id=10240&cs_id=1024007&p_id=4053&seq=1&format=2
 [10]: http://www.monoprice.com/products/product.asp?c_id=104&cp_id=10419&cs_id=1041912&p_id=4852&seq=1&format=2
 [11]: http://www.monoprice.com/products/product.asp?c_id=102&cp_id=10218&cs_id=1021804&p_id=5598&seq=1&format=2
 [12]: http://www.monoprice.com/products/product.asp?c_id=104&cp_id=10428&cs_id=1042802&p_id=5969&seq=1&format=2
 [13]: http://www.boxee.tv
 [14]: http://www.plexapp.com
 [15]: http://www.iospirit.com/products/remotebuddy/
 [16]: http://www.gravityapps.com/sofacontrol/
 [17]: http://www.macports.org
 [18]: http://www.jinx.de/JollysFastVNC.html
 [19]: http://www.iospirit.com/labs/candelair/
 [20]: http://blog.9minutesnooze.com/wp-content/uploads/2009/12/IMG_4570-Edit.jpg
 [21]: http://boxee.tv
 [22]: http://www.newertech.com/products/ministackv2_5.php
 [23]: http://blog.9minutesnooze.com/wp-content/uploads/2010/01/Screen-shot-2010-01-02-at-5.15.51-PM.png
 [24]: http://www.pandora.com
 [25]: http://www.tuaw.com/2009/08/21/ultimate-mac-mini-htpc-guide-software/
 [26]: http://www.machtpc.com/
 [27]: http://www.123macmini.com/forums/viewforum.php?f=64
 [28]: http://www.tuaw.com/2009/07/24/behold-my-mac-mini-media-center/
 [29]: http://karlo.org/2009/09/mac-mini-home-media-center.html