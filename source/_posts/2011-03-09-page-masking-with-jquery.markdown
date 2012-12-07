---
author: ctoestreich
date: '2011-03-09 10:01:08'
layout: post
comments: true
slug: page-masking-with-jquery
status: publish
title: Page Masking With jQuery
wordpress_id: '42'
categories:
- Technology
tags:
- ext
- extjs
- Javascript
- jquery
- mask
- masking
---

As I mentioned in my last post we are trying to move to [jQuery][1] as a
scripting solution over ExtJS or straight JavaScript.  When we wrote our
application we were using ExtJS to do a mask on the page during a form
submission so the user could have some useful feedback as to what was
happening.

Here is the code that we wrote to do page masking.  In the form tag we simply
put an onsubmit="doLoadingMask()" and the mask is rendered to the page into
the div with id="loading-mask" that wraps all of the page content.  This stops
the user from trying to click around and lets them know that something really
happened when they clicked the button as not all users look to the browser
icons spinning or status bar for details.

``` javascript
    function doLoadingMask() {
        doLoadingMaskText('Loading...');
    }

    function doLoadingMaskText(loadingText) {
        Ext.get("loading-mask").mask(loadingText, 'x-mask-loading');
    }
```

We ran into a problem that occurred very infrequent that would cause the form
submit to hang for a long time... or indefinitely.  With the mask remaining on
the screen the entire time and having the user blocked from interacting with
the page, this was a problem.  So I rewrote the code to be "error/timeout"
friendly in that it disappears after 30 seconds and the user can either
reattempt the action of leave the page and come back.  The 30 second timeout
does not stop the form submission from attempting to continue so given they
leave it alone long enough it still might complete after the mask disappears.

``` javascript
    function doLoadingMask() {
        doLoadingMaskText('Loading...');
    }

    var maskInterval;
    var maskTimeout = 30;
    var maskLoop = 1;

    function doLoadingMaskText(loadingText) {
        Ext.get("loading-mask").mask(loadingText, 'x-mask-loading');
        maskLoop = 1;
        maskInterval = window.setInterval(maskUpdater, 1000);
    }

    function undoLoadingMask() {
        Ext.get("loading-mask").unmask();
        clearInterval(maskInterval);
    }

    function maskUpdater() {
        if(maskLoop >= maskTimeout) {
            undoLoadingMask();
        } else {
            if(maskLoop % 5 === 0) {
                Ext.get("loading-mask").mask("Waiting... " + (maskTimeout - maskLoop), 'x-mask-loading');
            }
        }
        maskLoop++;
    }
```

This simply adds a 1 second interval call to invoke the maskUpdater and when
the timeout is reached it just unloads the mask.  It also updates the mask
with a "Waiting... [time]" every 5 seconds.

This solved the "infinite" mask problem and was, IMHO, a pretty simple
solution.  After looking at the overall size of our ExtJS vs jQuery base +
extensions, it was immediately clear that we wanted to get rid of as much of
ExtJS as possible.  The 175k min file ext-all isn't even the whole ExtJS
library.  It is only the components we are using while the jQuery is the full
caboodle.  The partial archaic file names are due to us using a JavaScript
file compressor.

[![][2]][3]

Every time I come across code written in ExtJS I rewrite it in jQuery.  Here
is the same code as above using jQuery and jQuery UI to accomplish the same
thing. We use a slightly different setup for the div as it doesn't have to
encompass the while page content. I just put this after the body tag

``` html
    <div id="loadingMask" style="display:none"><p align="center"><img src="/icue/images/loading.gif">&nbsp;<span id="message">submitting data...</span></p></div>
```

with this JavaScript

``` javascript
            var maskInterval;
            var maskTimeout = 30;
            var maskLoop = 1;
            function maskUpdater() {
                if(maskLoop >= maskTimeout) {
                    undoLoadingMask();
                } else {
                    if(maskLoop % 5 === 0) {
                        $("#loadingMask").find("#message").html("waiting... " + (maskTimeout - maskLoop));
                    }
                }

                maskLoop++;
            }

            function doLoadingMask() {
                $("#loadingMask").dialog({
                    modal: true,
                    width: 200,
                    height: 110,
                    position: [(window.width / 2),100],
                    closeOnEscape: false,
                    resizable: false,
                    open: function(event, ui) {
                        $(".ui-dialog-titlebar-close").hide();
                        $(".ui-dialog-titlebar").hide();
                        maskLoop = 1;
                        maskInterval = setInterval(maskUpdater, 1000);
                    }
                });
            }

            function undoLoadingMask() {
                clearInterval(maskInterval);
                $("#loadingMask").dialog("close");
            }
```

The setup for the dialog is a little more lengthy than the ExtJS version, but
we have more control around the look and feel of the message box.  The open
event override is setting the timer and also hiding the title and close bars.

For this jQuery to work you will need to include both jQuery base and the UI
javascript with at least the dialog and base ui in it.

The old mask (content blacked/grayed out for security reasons)

[![][4]][5]The new mask both off and on

[![][6]][7]

[![][8]][9]

   [1]: http://www.jquery.com (jquery)
   [2]: http://www.christianoestreich.com/wp-content/uploads/2011/03/js_size.png (Javascript File Size)
   [3]: http://www.christianoestreich.com/2011/03/page-masking-with-jquery/js_size/
   [4]: http://www.christianoestreich.com/wp-content/uploads/2011/03/js_oldmask.png (Old Mask)
   [5]: http://www.christianoestreich.com/2011/03/page-masking-with-jquery/js_oldmask/
   [6]: http://www.christianoestreich.com/wp-content/uploads/2011/03/js_maskoff.png (Mask Off)
   [7]: http://www.christianoestreich.com/2011/03/page-masking-with-jquery/js_maskoff/
   [8]: http://www.christianoestreich.com/wp-content/uploads/2011/03/js_maskon.png (Mask On)
   [9]: http://www.christianoestreich.com/wp-content/uploads/2011/03/js_maskon.png