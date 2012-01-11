---
author: ctoestreich
date: '2011-12-13 13:58:55'
layout: post
comments: true
slug: grails-cxf-client-custom-interceptors
status: publish
comments: true
title: Grails Cxf Client 1.2.3 Released
wordpress_id: '228'
categories:
- Grails
- Groovy
- Technology
tags:
- cxf
- cxf-client
- Grails
- groovy
- interceptors
- jaxb
- plugin
- soap
---

Based on a request from a user to add user defined logging and fault
interceptors, I have enhanced the [Grails cxf-client plugin][1]. I have
included these features in the new release version 1.2.3.

In the previous version (1.2.2) of the plugin I added the ability to override
the security interceptor. This was done to allow users to diverge from using
the standard WSS4J interceptor that I bundled with the plugin. I accomplished
this by adding an single out interceptor to the cxf client proxy.

In the latest version I have taken the interceptor injection one step further
and allowed users to configure any number of in, out or fault out interceptors
they want to add to the interceptor chain.  In addition I have provided a flag
to turn on or off the default logging in and out interceptors that I am auto
injecting for the users.

<!-- more  -->

The following partial documentation is available in full at
[https://github.com/ctoestreich/cxf-client][2]

To begin create the interceptor bean.

{% codeblock CustomLoggingInInterceptor.groovy %}
package com.cxf.demo.logging
import org.apache.cxf.common.injection.NoJSR250Annotations
import org.apache.cxf.interceptor.AbstractLoggingInterceptor
import org.apache.cxf.interceptor.Fault
import org.apache.cxf.interceptor.LoggingInInterceptor
import org.apache.cxf.message.Message
import org.apache.cxf.phase.Phase

@NoJSR250Annotations
public class CustomLoggingInInterceptor extends AbstractLoggingInterceptor
{
    def name
        
    public CustomLoggingInInterceptor() {
        super(Phase.RECEIVE);
        log "Creating the custom interceptor bean"
    }

    public void handleMessage(Message message) throws Fault {
        log "$name :: I AM IN CUSTOM IN LOGGER!!!!!!!"
    }
}
{% endcodeblock %}

Next you will want to wire up the interceptor bean in the resources.groovy.

{% codeblock resources.groovy %}
customLoggingInInterceptor(CustomLoggingInInterceptor) {
    name = "customLoggingInInterceptor"
}

verboseLoggingInInterceptor(VerboseCustomLoggingInInterceptor) {
    name = "verboseLoggingInInterceptor"
}

customLoggingOutInterceptor(CustomLoggingOutInterceptor) {
    name = "customLoggingOutInterceptor"
}
{% endcodeblock %}

Last you will need to define a list of interceptors in your config.groovy cxf
{client {...}} block for either in, out or out fault. The following defines
two custom inInterceptors named customLoggingInInterceptor and
verboseLoggingInInterceptor.

{% codeblock lang:groovy %}
simpleServiceInterceptorClient {
    wsdl = "docs/SimpleService.wsdl" //only used for wsdl2java script target
    clientInterface = cxf.client.demo.simple.SimpleServicePortType
    serviceEndpointAddress = "${service.simple.url}"
    inInterceptors = ['customLoggingInInterceptor', 'verboseLoggingInInterceptor'] //can use comma separated list or groovy list
    enableDefaultLoggingInterceptors = false
    namespace = "cxf.client.demo.simple"
}
{% endcodeblock %}

The flag enableDefaultLoggingInterceptors will turn on (true) the default
logging interceptors. You do not need to provide this property if you wish to
use the default logging as the default value is true. If you wish to turn
them off simply provide the property for your client bean config and set the
value to false similar to the above block.

See the docs at [https://github.com/ctoestreich/cxf-client][2] for more
details on further use of the cxf-client plugin and additional tips for wiring
up interceptors.

   [1]: http://www.grails.org/plugin/cxf-client (Grails Cxf Client Plugin)

   [2]: https://github.com/ctoestreich/cxf-client

