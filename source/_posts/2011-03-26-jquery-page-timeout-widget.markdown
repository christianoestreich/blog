---
author: ctoestreich
date: '2011-03-26 20:24:24'
layout: post
comments: true
slug: jquery-page-timeout-widget
status: publish
title: jQuery Timeout Dialog Widget
wordpress_id: '3'
categories:
- Technology
tags:
- Ajax
- dialog
- Javascript
- jquery
- js
- json
- session
- timeout
- widget
---

The code for the plugin is available over on [Github - jQuery Timeout Dialog
Widget][1].

I was looking into what was available for making a browser idle timer that
would redirect the user to a logoff page.  I really liked the work that was
done by [Paul Irish][2] on his [idleTimer plugin][3] as well as [Eric Hynd][4]
on his [Idle Timeout Plugin][5].  The first thing I did was put their code
onto our site.   It was pretty easy to hook up and get working.

We are running WebSphere 6.1 (hopefully moving to JBoss) and the global server
session timeout is 30 minutes.  After all was said and done, I decided that
what they had was probably overkill for what we were requiring.  The portion
of the idleTimer script the detects whether you are idle binds to the
following document events.


    events = 'mousemove keydown DOMMouseScroll mousewheel mousedown'; //
activity is one of these events

What this translates to is listeners bound to almost every user interactive
DOM events.  While this probably won't kill the browser performance by itself,
given that we have other dom events being listened to and our users are on IE6
*sigh*, I felt this was very heavy for just timing the user out of a session.

There were also a few features from the Idle Timeout Plugin that we didn't
need such as having to ping the server via ajax unless they reach some
threshold time before the timeout.  Essentially we only want to call the
server refresh session via ajax if the user invokes it via the "keep-me-alive"
dialog.

We also didn't need the timer to loop every second.  We set ours for a minute.
I almost justified having the timer look on a algorithm based on a combination
of the alert and timeout values, but that might also be overkill for what we
were doing.

For the widget to work you will need to include jQuery and jQuery-ui.


    <div id="timeoutDialog" style="display:none;">

     <p>[Some message here]</p>

     <p>

     You will time out in <span id="countdownTargetSpan" style="font-
weight:bold"></span>

     </p>

    </div>


    $(function() {

       $("#timeoutDialog").timeoutdialog({

           idleTimeout: 5,

           idleAlert: 1,

           keepAliveURL: "ajax.html",

           validResponseText: 'OK',

           countdownTarget: 'countdownTargetSpan',

           buttonContinueText: 'Ok',

           buttonSignoffText: 'Sign Off',

           onTimeout: function() {

              window.location = "timeout.html";

           },

           onSignoff: function(){

              window.location = "signoff.html";

           }

        });

     });

The code for the plugin is available over on [Github - jQuery Timeout Dialog
Widget][1].  I have both the minimized and uncompressed files in the source so
you can make any changes you feel necessary to the widget.

This is just a simpler implementation of some pre-existing widgets with a
simpler and less taxing code base and can hopefully be useful to those people
who do not need a complex solution to keep a session active and timeout
dialog.  The only real advantage to this over just doing a simple javascript
timer and alert is the more elegant jQuery dialog box...  we liked the look of
this over the alert box better.

**Value**

**Description**

**Default**

_idleTimeout_

Value in minutes that the session will timeout.

30

_idleAlert_

Value in minutes that the alert dialog will be shown

25

_keepAliveURL_

URL for the ajax to invoke to keep the session alive

''

_validResponseText_

Response from the ajax call in plain text (html) that signifies a valid
session renewed

'OK'

_countdownTarget_

span where the seconds remaining will be placed

'countdownTargetSpan'

_buttonContinueText_

Text for the Continue session button

'Ok'

_buttonSignoffText_

Text for the Sign Off session button

'Sign Off'

_onTimeout_

Action when timeout happens, usually a redirect to timeout url

function(){}

_onSignoff_

Action when timeout happens, usually a redirect to signoff url

function(){}

The code for the plugin is available over on [Github - jQuery Timeout Dialog
Widget][1].

   [1]: https://github.com/ctoestreich/jquery-timeoutdialog (jquery
timeoutdialog widget)

   [2]: http://paulirish.com/ (Paul Irish)

   [3]: http://paulirish.com/2009/jquery-idletimer-plugin/ (idle timer)

   [4]: http://www.erichynds.com/ (Eric Hynd)

   [5]: http://www.erichynds.com/jquery/a-new-and-improved-jquery-idle-
timeout-plugin/ (Idle Timeout Plugin)

