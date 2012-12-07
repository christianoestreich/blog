---
layout: post
title: "Grails Cxf Client 1.2.7 Released"
slug: grails-cxf-client-http-client-policy
date: 2012-02-15 15:00
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
- interceptors
- jaxb
- plugin
- soap
---
The [Grails cxf-client plugin][1] has been updated to version 1.2.7.  I have added the ability to specify timeouts (connection and receive) and allow chunking separately through params and also provided another parameter to pass the client name of an HTTPClientPolicy bean to use instead of setting the params seperately.

<!-- more -->

#### Updated Parameter Documentation ####

The following partial documentation is available in full at [https://github.com/ctoestreich/cxf-client][2]

Property|Description|Required
:-----------|:------------|:------------
connectionTimeout|Specifies the amount of time, in milliseconds, that the client will attempt to establish a connection before it times out. The default is 30000 (30 seconds). 0 specifies that the client will continue to attempt to open a connection indefinitely. (default: 30000)|No
receiveTimeout|Specifies the amount of time, in milliseconds, that the client will wait for a response before it times out. The default is 60000. 0 specifies that the client will wait indefinitely. (default: 60000)|No
allowChunking|If true will set the HTTPClientPolicy allowChunking for the clients proxy to true. (default: false)|No
httpClientPolicy|Instead of using the seperate timeout, chunking, etc values you can create your own HTTPClientPolicy bean in resources.groovy and pass the name of the bean here. <B>This will override the connectionTimeout, receiveTimeout and allowChunking values.</b> (default: null)|No
 
 
#### Timeout And Chunking Parameters ####

Here is an example cxf client configuration block using the connectionTimeout, receiveTimeout and allowChunking parameters:

{% codeblock Config.groovy %}
cxf {
    installDir = "C:/apps/apache-cxf-2.4.2" //only used for wsdl2java script target
    client {
        simpleServiceClient {
            wsdl = "docs/SimpleService.wsdl" //only used for wsdl2java script target
            wsdlArgs = "-autoNameResolution"
            clientInterface = cxf.client.demo.simple.SimpleServicePortType
            serviceEndpointAddress = "${service.simple.url}"
            namespace = "cxf.client.demo.simple"
            receiveTimeout = 0 //no timeout
            connectionTimeout = 0 //no timeout
            allowChunking = false
        }
    }
}
{% endcodeblock %}

#### HTTPClientPolicy Parameter ####

Here is an example cxf client configuration block using the httpClientPolicy config parameter:

{% codeblock resources.groovy %}
beans = {
    customHttpClientPolicy(HTTPClientPolicy){
        connectionTimeout = 30000
        receiveTimeout = 60000
        allowChunking = false
        autoRedirect = false
    }
}
{% endcodeblock %}

{% codeblock Config.groovy %}
cxf {
    installDir = "C:/apps/apache-cxf-2.4.2" //only used for wsdl2java script target
    client {
        simpleServiceClient {
            clientInterface = cxf.client.demo.simple.SimpleServicePortType
            serviceEndpointAddress = "${service.simple.url}"
            httpClientPolicy = 'customHttpClientPolicy'
        }
}
{% endcodeblock %}

   [1]: http://www.grails.org/plugin/cxf-client (Grails Cxf Client Plugin)

   [2]: https://github.com/ctoestreich/cxf-client