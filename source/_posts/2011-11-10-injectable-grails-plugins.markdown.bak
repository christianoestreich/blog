---
author: ctoestreich
date: '2011-11-10 18:44:23'
layout: post
comments: true
slug: injectable-grails-plugins
status: publish
title: Allowing Users To Inject Custom Beans Into Your Grails Plugin
wordpress_id: '188'
categories:
- Technology
tags:
- apache
- cxf
- cxf-client
- Grails
- plugin
- spring
- wsdl
---

Recently with my [cxf-client][1] plugin I wanted to give users a way to inject
custom beans into the auto-wired client services. At first I was having a
little trouble figuring out how to get each configured service to have a
uniquely injected security interceptor. Burt Beckwith does something similar
with the [spring-security-core][2] plugin. I borrowed heavily on his method
for using [filters][3].

The key to getting this working was knowing that the service client factory I
use is a singleton as are each unique instance of the service that is
configured. Given the way I have the apache cxf code wrapped, any clients
created hand off their actual creation of the service proxy to the service
client factory. The security interceptor that is injected to the client has
to be a unique bean as it will be wired up as a singleton as well and be
handed off to the factory during creation. What this ultimately means is that
I can't just have one global property that can be overridden by a common bean
name as this would be shared across clients and not give each client the
flexibility to define it's own unique security interceptor property values
such as username and password

<!-- more -->

Here is a snippet of the code from my plugin's doWithSpring block. This code
is within a loop that iterates all the clients set up with in the
application's Config.groovy (see [plugin configuration][4] in the docs).

``` groovy
    if(client?.secured && !client?.securityInterceptor) {
        "securityInterceptor${cxfClientName}"(com.grails.cxf.client.security.DefaultSecurityOutInterceptor) {
            username = client?.username ?: ""
            password = client?.password ?: ""
        }
    }

    "${cxfClientName}"(DynamicWebServiceClient) {
        webServiceClientFactory = ref("webServiceClientFactory")
        if(client?.secured || client?.securityInterceptor) {
            if(client?.securityInterceptor) {
                securityInterceptor = ref("${client.securityInterceptor}")
            } else {
                securityInterceptor = ref("securityInterceptor${cxfClientName}")
            }
        }

        clientInterface = client.clientInterface ?: ""
        serviceName = cxfClientName
        serviceEndpointAddress = client?.serviceEndpointAddress ?: ""
        secured = (client?.secured || client?.securityInterceptor) ?: false
    }
```

With the code above the security interceptor is either referenced by name
directly from the client config block if provided or the default one is used
if the service is marked as secure. A default interceptor is created for each
client as the username and password will most likely be different per
configured client.

For creating a mock custom interceptor I am just modifying the default one
slightly below and using a different name for the user and password fields to
keep it simple. As a convenience to the user, I created an interface to
inherit from that allows you to customize the specifics of the interceptor
without having to inherit all the contract methods for a cxf interceptor. You
simply have to inherit from SecurityInterceptor in the
com.grails.cxf.client.security package and use an existing interceptor type
and return it in the create method. Here is the custom interceptor I created
for the [demo project][5].


``` groovy
    package com.cxf.demo.security

    import com.grails.cxf.client.security.SecurityInterceptor
    import javax.security.auth.callback.Callback
    import javax.security.auth.callback.CallbackHandler
    import javax.security.auth.callback.UnsupportedCallbackException
    import org.apache.cxf.ws.security.wss4j.WSS4JOutInterceptor
    import org.apache.ws.security.WSPasswordCallback
    import org.apache.ws.security.handler.WSHandlerConstants
    
    class CustomSecurityInterceptor implements SecurityInterceptor {
        def pass
        def user
        WSS4JOutInterceptor create() {
            Map<String, Object> outProps = [:]
            outProps.put(WSHandlerConstants.ACTION, org.apache.ws.security.handler.WSHandlerConstants.USERNAME_TOKEN)
            outProps.put(WSHandlerConstants.USER, user)
            outProps.put(WSHandlerConstants.PASSWORD_TYPE, org.apache.ws.security.WSConstants.PW_TEXT)
            outProps.put(WSHandlerConstants.PW_CALLBACK_REF, new CallbackHandler() {
                void handle(Callback[] callbacks) throws IOException, UnsupportedCallbackException {
                    WSPasswordCallback pc = (WSPasswordCallback) callbacks[0]
                    pc.password = pass
                }
            })

            new WSS4JOutInterceptor(outProps)
        }
    }
```

You have to make sure your create method returns an object that already
inherits from the appropriate cxf interceptor classes such as the
WSS4JOutInterceptor I used here. It is technically possible for your
interceptor to extend something like SoapHeaderInterceptor, but by doing so
you will be responsible for overriding all the appropriate interceptor methods
yourself.

To see how to setup security with the cxf plugin you can see the [following
example][6] on how to define a basic authentication in interceptor on the
server side for testing your clients. More specifically refer to [this
file][7] for sample code on create your own in interceptor or to the [demo
project file][8] that injects a server side in interceptor.  Perhaps the
**best documentation** on writing a complex interceptor can be found at the
[Apache CXF][9] site.

These in interceptors are what handle the security request that comes to the
server.  Most likely if you are dealing with secured service, an in
interceptor already exists on the server and you only care about creating a
custom out interceptor to use with your client.

In the case of the above CustomSecurityInterceptor, you would then place the
following in your projects resources.groovy.

``` groovy
    beans = {
        myCustomInterceptor(com.cxf.demo.security.CustomSecurityInterceptor){
            user = "wsuser"
            pass = "secret"
        }
    }
```

The last step to hooking up the custom interceptor is to define the
securityInterceptor for the client config block. The myCustomInterceptor bean
can be hooked up by adding the line in the config below.

``` groovy
    cxf {
        client {
            customSecureServiceClient {
                wsdl = "docs/SecureService.wsdl" //only used for wsdl2java script target
                namespace = "cxf.client.demo.secure"
                clientInterface = cxf.client.demo.secure.SecureServicePortType
                //secured = true //implied when you define a value for securityInterceptor
                securityInterceptor = 'myCustomInterceptor'
                serviceEndpointAddress = "${service.secure.url}"
            }
        }
    }
```

This is added as a 'string' as the plugin will essentially use this as the
name of the bean it will use for injecting into the client.  I suppose if the
bean wasn't found the code might hiccup when trying to run it.  I will have to
check that out! :)

I hope this can help anyone wanting to write more extensible plugins in the
future overcome the challenges I faced.  It wasn't that much code in the end,
but putting all the pieces of the puzzle together was a bit challenging.

   [1]: http://grails.org/plugin/cxf-client
   [2]: https://github.com/grails-plugins/grails-spring-security-core/blob/master/SpringSecurityCoreGrailsPlugin.groovy
   [3]: http://grails-plugins.github.com/grails-spring-security-core/docs/manual/guide/16%20Filters.html
   [4]: https://github.com/Grails-Plugin-Consortium/cxf-client
   [5]: https://github.com/Grails-Plugin-Consortium/cxf-client-demo
   [6]: http://www.technipelago.se/content/technipelago/blog/basic-authentication-grails-cxf
   [7]: http://chrisdail.com/download/BasicAuthAuthorizationInterceptor.java
   [8]: https://github.com/Grails-Plugin-Consortium/cxf-client-demo/blob/master/grails-app/conf/BootStrap.groovy
   [9]: http://cxf.apache.org/docs/interceptors.html

