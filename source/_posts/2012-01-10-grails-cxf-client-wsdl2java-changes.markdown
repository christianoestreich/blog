---
layout: post
title: "Grails Cxf Client 1.2.5 Changes"
slug: grails-cxf-client-wsdl2java
date: 2012-01-10 10:17
comments: true
status: publish
categories: 
- Technology
tags: 
- Grails
- Cxf
- Plugin
---
Based on a user request, I have added the ability to pass the wsdl2java script a wsdlArgs param in which you can use to pass custom args into the client creation process.  I have also modified the name of the **bindingFile** parameter as the name **binding** was in conflict with groovy reserved keywords.

<!-- more -->

<table border="1">
<tr><td><b>Property</b></td><td><b>Description</b></td><td>Required</b></td></tr>
<tr><td>wsdl</td><td>Location of the wsdl either locally relative to project home dir or a url. (default: "")</td><td>No</td></tr>
<tr><td>wsdlArgs</td><td>A custom list of args to pass in seperated by space such as ["-autoNameResolution","-validate"].  This can also be a single string value such as "-autoNameResolution", but when using multiple custom params you must specify each in a list ["-one val","-two","-three val"] due to limitations with ant. (default: "")</td><td>No</td></tr>
<tr><td>namespace</td><td>Specifies package names to use for the generated code. (default: "use wsdl provided schema")</td><td>No</td></tr>
<tr><td>client</td><td>Used to tell wsdl2java to output sample clients, usually not needed. (default: false)</td><td>No</td></tr>
<tr><td>bindingFile</td><td>Path of binding file to pass to wsdl2java. (default: "")</td><td>No</td></tr>
<tr><td>outputDir</td><td>Password to pass along with request in wss4j interceptor when secured is true. (default: "src/java")</td><td>No</td></tr>
</table>

Here is an example cxf client configuration block using the new wsdlArgs param.

``` groovy
cxf {
    installDir = "C:/apps/apache-cxf-2.4.2" //only used for wsdl2java script target
    client {
        simpleServiceClient {
            //used in wsdl2java
            wsdl = "docs/SimpleService.wsdl" //only used for wsdl2java script target
            wsdlArgs = ['-autoNameResolution', '-validate']
            //wsdlArgs = '-autoNameResolution' //single param style
            namespace = "cxf.client.demo.simple"
            client = false //defaults to false
            bindingFile = "grails-app/conf/bindings.xml"
            outputDir = "src/java"

            //used for invoking service
            clientInterface = cxf.client.demo.simple.SimpleServicePortType
            serviceEndpointAddress = "${service.simple.url}"
        }
    }
}
```
