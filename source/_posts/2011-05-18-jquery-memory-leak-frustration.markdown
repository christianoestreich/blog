---
author: ctoestreich
date: '2011-05-18 21:45:55'
layout: post
comments: true
slug: jquery-memory-leak-frustration
status: publish
title: jQuery Memory Leak Frustration
wordpress_id: '102'
categories:
- Technology
tags:
- ie6
- jquery
- memoryleak
- widget
---

Recently at work we ran into a hard to track down issue with Internet Explorer
6. Every page load we were seeing about 10mb of memory being retained in the
browser. We had no idea where to start and since there were several hundreds
of commits to the code and data structures we had a tough time finding the
culprit.

We initially thought the problem was the Sencha ExtJS Grid we were using.
Between the four of us working on it we finally reverted the jQuery 1.5.1
upgrade we had made and found the problem disappeared. Initially we reverted
to 1.4.3, but found that 1.5 also didn't cause the problem. All future version
from 1.5.1 to 1.6.1 caused the same issue.

We found some information about how IE6 didn't like the modal: true of the
ui.dialog widget. We set that boolean to false and it seemed to clear up the
issue with 1.5.1, but we were duped by IE6 for a short time as the problem
only seemed to disappear until after we deployed to production. We reverted
the modal setting and went back to jQuery 1.5 and all was cleared up.

I am a huge fan of jQuery and love how amazingly simple doing really cool
stuff is, but I was a bit erked that something so non-trivial was introduced
and remains through another major release of the framework.

I understand that testing all browsers, and especially IE6, might be
difficult... but the "write less do more" only goes so far when your end users
can't use your application after 15 minutes.  When sites like Google stop
supporting IE6, you know that your platform is old. Perhaps my frustration
over jQuery is better vetted against the ridiculous corporate oppression of
adopting technology newer than 10 years old.

I did write another widget today that extends the autocomplete box which
supports invoking both urls with normal data params or in a restful style with
very little effort... so I guess I am over it.

