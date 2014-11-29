---
title: Get Hulu working on Boxee (again)
author: Aaron
layout: post
permalink: /hulu-working-boxee/
ratings_users:
  - 0
ratings_score:
  - 0
ratings_average:
  - 0
categories:
  - Uncategorized
tags:
  - boxee
  - fools
  - htpc
  - hulu
  - idiots
  - media center
  - morons
---
<rant>In a move that defies any reason, the short-sighted bonehead executives at Hulu (or perhaps NBC, but really&#8230;who cares?) decided that they don&#8217;t want advertising dollars from the thousands of Boxee and Boxee Box users, and instead, would prefer that people simply pirate their media instead since it is higher quality, easier to get, and has no advertisements. Hey, guys at Hulu&#8230;wake up. It&#8217;s not 2000 anymore.</rant> 

Anyhow, [a very smart fellow][1] over at the Boxee Forums figured out how to work around the issue with a little bit of javascript&#8230;

**Disclaimer:** This might make your computer explode, your network implode, and format your nodes. I&#8217;m not responsible, nor is [jzongker][2] over on the Boxee Forums.

Simply save the following code as hulu.js ([download link][3]) and put it in the following location:

<table>
  <tr>
    <td>
      Mac
    </td>
    
    <td>
      /Applications/Boxee.app/Contents/Resources/ Boxee/system/players/flashplayer/hulu.js
    </td>
  </tr>
  
  <tr>
    <td>
      Linux
    </td>
    
    <td>
      [Boxeepath]/system/players/flashplayer/hulu.js
    </td>
  </tr>
  
  <tr>
    <td>
      Windows
    </td>
    
    <td>
      probably [Boxeepath]\system\players\flashplayer\hulu.js in Program Files
    </td>
  </tr>
  
  <tr>
    <td>
      Boxee Box
    </td>
    
    <td>
      Apparently this technique does not work
    </td>
  </tr>
</table>

* * *

<pre>boxee.browserWidth=1280;
boxee.browserHeight=720;
boxee.earlyTimers = true;
boxee.enableLog(true);

boxee.onInit = function() {
   browser.setConfigChar('general.useragent.override','Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/540.0 (KHTML, like Gecko) Ubuntu/10.10 Chrome/9.1.0.0 Safari/540.0');
}

if (boxee.getVersion() &lt; 5)
   boxee.renderBrowser = true;

boxee.parseBoxeeTags = false;
boxee.autoChoosePlayer = false;

var current    = 0;
var h_width    = 720;
var h_bottom   = 23;
var started    = false;
var active     = false;
var duration   = false;
var is_paused  = false;
var alt_player = false;

boxee.onBack = function()  { boxee.onEnter(); }
boxee.onLeft = function()  { boxee.onEnter(); }
boxee.onRight = function() { boxee.onEnter(); }
boxee.onUp = function()    { boxee.onEnter(); }
boxee.onDown = function()  { boxee.onEnter(); }

wmodeFix = setInterval(function() {
   boxee.getWidgets().forEach(function(widget) {
      zorder_id = widget.getAttribute("id");
      if (zorder_id == 'banner_c')
         browser.execute('document.getElementById("'+zorder_id+'").style.zIndex = 99999;');
   });
}, 500);

boxee.onDocumentLoaded = function() {
   boxee.setMode(1);
   boxee.showNotification("[B]Press Enter to view full screen[/B]", ".", 500);
}

boxee.onEnter = function()
{
   boxee.setMode(0);

   if (boxee.getVersion() &lt; 5)       browser.execute('window.scrollTo(0,50);');    clearInterval(wmodeFix);    boxee.showNotification("[B]Switching to full screen...[/B]", ".", 2);    playerTimer = setInterval(function(){       if (!active) locatePlayer();       else updateProgress();    }, 1000) } function playerReference() {    id = boxee.getActiveWidget().getAttribute('id');    if (id.length &gt; 0)
      return 'document.'+id+'.';

   else if (alt_player != false)
      return alt_player;

   else
   {
      var locateMe = "(function(){objects=document.getElementsByTagName('embed'); for (var i in objects) { if (objects[i].getAttribute('src') == '"+boxee.getActiveWidget().getAttribute('src')+"') return i; }})()";
      locateMe = browser.execute(locateMe);
      if (locateMe &gt; 0)
      {
         alt_player = 'document.getElementsByTagName("embed")['+locateMe+'].';
         return alt_player;
      }
      else
         return 'document.player.';
   }
}

function updateProgress()
{
   if (!duration)
      duration = parseInt(browser.execute(playerReference()+'getDuration()')) / 1000;

   if (duration)
      boxee.setDuration(duration);

   current = parseInt(browser.execute(playerReference()+'getCurrentTime()')) / 1000;
   if (isNaN(current))
      alt_player = false;

   if (current &gt; 0 && !started)
      started = true;

   progress = current / duration * 100;
   alert(progress);
   boxee.notifyCurrentTime(current);
   boxee.notifyCurrentProgress(progress);

   if (started && progress &gt; 99.9)
      boxee.notifyPlaybackEnded();
}

function locatePlayer()
{
   boxee.getWidgets().forEach(function(widget) {
      flashvars = widget.getAttribute("flashvars");
      if (flashvars.indexOf('hulu.com/watch') != -1 && flashvars.indexOf('bitrate=') != -1 && !active) {
         active = true;
         boxee.renderBrowser = false;
         var crop = (widget.width - h_width) / 2;
         widget.setCrop(crop, 0, crop, h_bottom);
         boxee.notifyConfigChange(widget.width-(crop*2),widget.height-h_bottom);
         widget.setActive(true);
      }
   });

   if (active)
   {
      boxee.setCanPause(true);
      boxee.setCanSkip(true);
      boxee.setCanSetVolume(true);
   }

   return active;
}

boxee.onPause = function()
{
   is_paused = true;
   browser.execute(playerReference() + 'pauseVideo()')
}

boxee.onPlay = function()
{
   is_paused = false;
   browser.execute(playerReference() + 'resumeVideo()')
}

boxee.onSkip = function ()
{
   if (is_paused) return;
   update = (duration &lt; 3000) ? (current + 60) : (current + 120);
   browser.execute(playerReference() + 'seekVideo('+update+')');
}

boxee.onBigSkip = function ()
{
   if (is_paused) return;
   update = (duration &lt; 3000) ? (current + 180) : (current + 360);
   browser.execute(playerReference() + 'seekVideo('+update+')');
}

boxee.onBack = function ()
{
   if (is_paused) return;
   update = (duration &lt; 3000) ? (current - 60) : (current - 120);
   browser.execute(playerReference() + 'seekVideo('+update+')');
}

boxee.onBigBack = function ()
{
   if (is_paused) return;
   update = (duration &lt; 3000) ? (current - 180) : (current - 360);
   browser.execute(playerReference() + 'seekVideo('+update+')');
}

boxee.onSetVolume = function(volume)
{
   browser.execute(playerReference() + 'setVolume('+volume/100+')');
}</pre>

<div class="addtoany_share_save_container addtoany_content_bottom">
  <div class="a2a_kit a2a_kit_size_32 addtoany_list a2a_target" id="wpa2a_17">
    <a class="a2a_button_facebook" href="http://www.addtoany.com/add_to/facebook?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fhulu-working-boxee%2F&linkname=Get%20Hulu%20working%20on%20Boxee%20%28again%29" title="Facebook" rel="nofollow" target="_blank"></a><a class="a2a_button_twitter" href="http://www.addtoany.com/add_to/twitter?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fhulu-working-boxee%2F&linkname=Get%20Hulu%20working%20on%20Boxee%20%28again%29" title="Twitter" rel="nofollow" target="_blank"></a><a class="a2a_button_google_plus" href="http://www.addtoany.com/add_to/google_plus?linkurl=http%3A%2F%2Fblog.9minutesnooze.com%2Fhulu-working-boxee%2F&linkname=Get%20Hulu%20working%20on%20Boxee%20%28again%29" title="Google+" rel="nofollow" target="_blank"></a><a class="a2a_dd addtoany_share_save" href="https://www.addtoany.com/share_save"></a>
  </div>
</div>

 [1]: http://forums.boxee.tv/showthread.php?t=22613
 [2]: http://forums.boxee.tv/member.php?u=47501
 [3]: http://9minutesnooze.com/download/hulu.js