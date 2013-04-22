---
author: ctoestreich
date: '2011-10-12 12:56:54'
layout: post
comments: true
slug: grails-cxf-client-plugin
status: publish
title: Grails Cxf Client Plugin Released
wordpress_id: '154'
categories:
- Technology
tags:
- apache
- cxf
- cxf-client
- Grails
- jaxb
- plugin
- soap
- web service
- web services
---

I am happy to announce that I have released the version 1.0 of the cxf client
plugin.  The plugin can be found here:  [http://grails.org/plugin/cxf-
client][1].

There are a few different plugins for consuming SOAP web services with grails,
but none currently deal with the issue of caching port references. The ws-
client plugin works, but its limitations are in how it creates and consumes
the wsdl. It relies on real time creation of proxy classes and services which
can be very processor and memory (time) consuming with a large or complex
service contract. We need a way to speed up service invocation so this plugin
was created to facilitate that need when consuming SOAP services using cxf.

The Cxf Client plugin will allow you to use existing (or new) apache cxf
wsdl2java generated content and cache the port reference to speed up your soap
service end point invocations through an easy configuration driven mechanism.

A big thanks to Brett Borchardt and Stefan Armbruster for helping out with the
plugin coding/review and the wsdl2java script.

The source can be found here:  [https://github.com/Grails-Plugin-Consortium/cxf-client][2]


   [1]: http://grails.org/plugin/cxf-client (cxf client plugin)

   [2]: https://github.com/Grails-Plugin-Consortium/cxf-client (cxf client source)

