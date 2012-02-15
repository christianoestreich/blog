---
layout: post
title: "Grails Cxf Client 1.2.7 Released"
slug: grails-cxf-client-http-client-policy
date: 2012-02-15 15:00
comments: true
status: publish
categories: 
- Technology
tags: 
- Grails
- Cxf
- Cxf-Client
- Plugin
- released
---
I added the ability to specify timeouts and chunking separately through params or through providing a client a name of an HTTPClientPolicy bean.

<!-- more -->

<table border=1>
<tr><td><b>Property</b></td><td><b>Description</b></td><td>Required</b></td></tr>
<tr><td>connectionTimeout</td><td>Specifies the amount of time, in milliseconds, that the client will attempt to establish a connection before it times out. The default is 30000 (30 seconds). 0 specifies that the client will continue to attempt to open a connection indefinitely. (default: 30000)</td><td>No</td></tr>
<tr><td>receiveTimeout</td><td>Specifies the amount of time, in milliseconds, that the client will wait for a response before it times out. The default is 60000. 0 specifies that the client will wait indefinitely. (default: 60000)</td><td>No</td></tr>
<tr><td>allowChunking</td><td>If true will set the HTTPClientPolicy allowChunking for the clients proxy to true. (default: false)</td><td>No</td></tr>
<tr><td>httpClientPolicy</td><td>Instead of using the seperate timeout, chunking, etc values you can create your own HTTPClientPolicy bean in resources.groovy and pass the name of the bean here. <B>This will override the connectionTimeout, receiveTimeout and allowChunking values.</b> (default: null)</td><td>No</td></tr>
</table>

    Note: If you incorrectly refer to your new beans name (spelling, etc) you will get an exception such as `...Caused by: org.springframework.beans.factory.NoSuchBeanDefinitionException: No bean named 'blahblah' is defined` error.

Here is an example cxf client configuration block using the connectionTimeout, receiveTimeout and allowChunking parameters:

``` groovy
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
```

Here is an example cxf client configuration block using the httpClientPolicy config parameter:

resources.groovy

``` groovy
beans = {
    customHttpClientPolicy(HTTPClientPolicy){
        connectionTimeout = 30000
        receiveTimeout = 60000
        allowChunking = false
        autoRedirect = false
    }
}
```

Config.groovy

``` groovy
cxf {
    installDir = "C:/apps/apache-cxf-2.4.2" //only used for wsdl2java script target
    client {
        simpleServiceClient {
            clientInterface = cxf.client.demo.simple.SimpleServicePortType
            serviceEndpointAddress = "${service.simple.url}"
            httpClientPolicy = 'customHttpClientPolicy'
        }
}
```
