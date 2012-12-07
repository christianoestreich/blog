---
author: ctoestreich
date: '2011-03-07 08:39:03'
layout: post
comments: true
slug: exploring-jquery-ui-widgets
status: publish
title: Exploring jQuery UI Widgets
wordpress_id: '37'
categories:
- Technology
tags:
- Ajax
- controller
- data-attribute
- html
- html5
- Javascript
- jquery
- js
- json
- lazy-load
- model
- mvc
- spring
- Spring mvc
- view
- widget
- widget factory
---

Recently at work I was seeing a pattern with JavaScript that was causing me a
little concern.  Every time someone wanted to do an ajax call on an object
they would write some code using jQuery to load up the object with every call.
The first attempt to correct this pattern was to create a reusable method that
we could invoke as needed.  We came up with the following:


``` javascript
    function getAjaxJson(actionUrl, params, spinDiv, args) {
        args = (!args) ? {} : args;
        jQuery('#' + spinDiv).show();
        jQuery.ajax({
            cache: true,
            url: actionUrl,
            contentType: "application/json; charset=utf-8",
            dataType: 'json',
            data: params,
            error: function(xhr, status, error) {
                jQuery('#' + spinDiv).hide();
                if(args.onError) {
                    args.onError(xhr, status, error);
                }
            },
            success: function(obj) {
                jQuery('#' + spinDiv).hide();
                if(obj) {
                    if(args.onPostBack) {
                        args.onPostBack(obj);
                    }
                }
            }
        });
    }
```

This was an okay approach and worked for quite a while but we were still
having to do things like this all over the site where we wanted to use this
method:

``` javascript
    var spinDiv = 'ajax_spin';
    var targetField = 'someField';
    jQuery('#' + targetField).html("");
    var params = "foo=bar";
    var actionUrl = "url/url.url";
    getAjaxJson(actionUrl, params, spinDiv, {onPostBack:function(obj) {
       if(obj.fullDescription) {
          jQuery('#' + targetField).html(obj.fullDescription);
       }
    }});
```

We went on for a year in happy bliss of our new "easy" approach to get ajax to
work with our site. None of us were really considered to be UI or UX experts
on the team and we just kept adding more and more JavaScript to set up ajax on
a component.

I started drinking the jQuery Kool-Aid a while back and was doing some
prototyping and trying to find more intricate solutions to help reduce the
amount of script we had littered across the site.  I had my ah-ha moment while
doing some research into the [jQuery Widget][1] framework.

I wanted to create a widget that would allow us to load content via ajax
without having to write a lot of additional script code.  I needed a way to be
able to indicate what url, params and target div to render the content to in
the event that we want the load of some thing to trigger ajax to be loaded
into another div.  To solve the first problem I started looking into is
jQuery's support of the HTML 5 [data attributes][2].

By adding items such as <div id="..." **data-controller**="..." **data-
params**="..." **data-action**="..." **data-target**="..." /> and using the
jQuery.attr("data-controller") I am able to retrieve the value.  We played
around with just using the jQuery.data("controller"), but jQuery seemed to
only like to find the data-controller attribute when it was added via the
jQuery.data("controller","value") (This is something I want to play around
with more going forward).

The ui.lazyload.js Widget:

``` javascript
    (function ($) {
        // no logging errors from ie6
        var clickName = 'click.lazyload';
        window.console || (console = {},console.log = function() {});
        $.widget("ui.lazyload", {
            _init: function () {
                var self = this, o = self.options, el = self.element, ops = this.options;
                (function (o, url, actn, args) {
                    if(url && actn) {
                        actn = (!args) ? actn : actn + "&" + args;
                        o = (!o) ? el : (o.indexOf("#") < 0 ? "#" + o : o);
                        $(o).html("loading...");
                        if(ops.before && $.isFunction(ops.before)) eval(ops.before());
                        $.ajax({
                            url: url,
                            cache: true,
                            dataType: 'html',
                            data: actn,
                            error: function(xhr, status, error) {
                                $(o).html('Error processing request.').addClass("error");
                                if(ops.error && $.isFunction(ops.error)) eval(ops.error());
                            },
                            complete: function(html){
                                if(ops.complete && $.isFunction(ops.complete)) eval(ops.complete());
                            },
                            success: function(html) {
                                el.removeClass("lazy-load").unbind(clickName);
                                $(o).remove(".loading-img").html(html);
                                if(ops.success && $.isFunction(ops.success)) eval(ops.success());
                            }
                        });
                    } else {
                        console.log("You must provide a data-controller and a data-action on the object.")
                    }
                })($(el).attr("data-target"), $(el).attr("data-controller"), "action=" + $(el).attr("data-action"), $(el).attr("data-params"));
            },
            destroy: function() {
                $.Widget.prototype.destroy.apply(this, arguments); // default destroy
                // now do other stuff particular to this widget
            }
        });
        $(function() {
            $('.lazy-load').each(function() {
                $(sec).lazyload();
            });
        });
    })(jQuery);
```

This basically takes any item with a class of "lazy-load" and attempts to load
the content via ajax.  The only requirement is that you define the data
objects in the html tag such as the following:

``` html
    <div id="one" class="lazy-load"
         data-controller="/url/url.url"
         data-action="doWork" />

    <div id="two"
         data-controller="/url/url.url"
         data-action="doMoreWork" />
```

Since we use Spring MVC we are invoking our urls like the  following
/url/url.url?action=doWork.  This could all be combined into the data-
controller attribute, but for clarity of invocation we split them up as
separate items.  The target of "this" is assumed if the data-target isn't
provided.  If we needed to add params to the ajax call we could add a data-
params="foo=bar" and the resulting url would be invoked as
/url/url.url?action=doWork&foo=bar where foo=bar is passed to the jQuery ajax
method in the data parameter.

We modified our JSTL tags to take the 4 new params to set.  Getting content
wired up to load via ajax requires the users to no longer write any JavaScript
code, just simply define the parameters and invoke .lazyload().  Of course
there are special cases in which eventing is required so I went back and added
support for the following:

``` javascript
    $("#one").lazyload({before: [function], complete: [function], success: [function], error: [function]});
```

**before **- execute the [function] before calling the ajax method on the
object **complete **- execute the [function] after calling the ajax method on
the object regardless of status **success **- execute the [function] after
calling the ajax method on the object on success **error **- execute the
[function] after calling the ajax method on the object on error

Also if people really want to customize how the item loads they could skip
adding the class of lazy-load and the ajax call will not happen on load.
Instead they can do something like:

``` javascript
    $(function() {
        $("#one").bind('click.lazyload', function() {
            $("one").lazyload();
        });
    });
```

This will bind a click event with a name-space of lazy-load (which will be
auto unbound after click via widget) to the object with id="one".  I wanted to
unbind the click event so I used the name-space, but if the user were to
simply bind('click',...); instead, it would not unbind the event and the ajax
would get invoked on every click.

When we are crossing multiple object boundaries and controls we have to be
conscious as to which object we add the data attributes to and which objects
have events that invoke the lazy-load.  The object with the .lazyload()
invoked must have the data attributes on it.  You can bind an even to another
object, but it will not get unbound unless you added support for that via the
complete event.

``` javascript
    //Untested code
    $(function() {
        $("#two").bind('click.lazyload', function() {
            $("one").lazyload({complete:function(){$("#two").unbind('click.lazyload');}});
        });
    });
```

That code would lazy-load id="one" when clicking on id="two" and unbind the
click event after complete.  Perhaps using the before event would be better to
stop the multiple invocation of the ajax get.

I have learned a lot and am actively re-writing all our copy-paste JavaScript
where we do the same thing in multiple places.  I will post more as I create
them and hopefully they can be leveraged or rewritten to support your needs.

   [1]: http://docs.jquery.com/UI_Developer_Guide#The_widget_factory (jQuery Widgets)
   [2]: http://api.jquery.com/data/ (jQuery Data Attribute Support)