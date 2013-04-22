---
layout: post
title: "Grails Cxf Client 1.2.9 Released"
slug: grails-cxf-client-soap-exceptions
date: 2012-03-01 12:00
comments: true
status: publish
categories: 
- Grails
- Groovy
- Technology
tags: 
- cxf
- cxf-client
- Grails
- groovy
- soap fault
- checked exceptions
- jaxb
- plugin
- soap
---
The [Grails cxf-client plugin][1] has been updated to version 1.2.9.  When I first deployed the plugin I overlooked allowing checked exceptions and soap faults to bubble out of the client proxy appropriately.  I modified the plugin to allow this now.  In addition I added a configuration parameter for proxyFactoryBindingId to allow soap 1.2 (set to "http://schemas.xmlsoap.org/wsdl/soap12/").

#### Updated Parameter Documentation ####

The following partial documentation is available in full at [https://github.com/Grails-Plugin-Consortium/cxf-client][2]

Property|Description|Required
:-----------|:------------|:------------
proxyFactoryBindingId|The URI, or ID, of the message binding for the endpoint to use. For SOAP the binding URI(ID) is specified by the JAX-WS specification. For other message bindings the URI is the namespace of the WSDL extensions used to specify the binding. If you would like to change the binding (to use soap12 for example) set this value to "http://schemas.xmlsoap.org/wsdl/soap12/". (default: "")|No

[1]: http://www.grails.org/plugin/cxf-client (Grails Cxf Client Plugin)
[2]: https://github.com/Grails-Plugin-Consortium/cxf-client