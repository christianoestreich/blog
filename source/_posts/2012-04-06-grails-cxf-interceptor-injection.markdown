---
layout: post
title: "Grails Cxf Interceptor Injection"
slug: grails-cxf-interceptor-injection
date: 2012-04-06 12:00
comments: true
status: publish
categories: 
- Grails
- Groovy
- Technology
tags: 
- cxf
- cxf-client
- interceptor
- security
- Grails
- groovy
- soap fault
- jaxb
- plugin
- soap
---
In my [grails cxf-client-demo project][1] I needed a way to test if the simple username token authentication wss4j interceptors were working.  I looked around the web for help on how to inject an inbound security interceptor into the [grails cxf plugin][3].  I found some example on how to do this with cxf 2.3.x versions, but when I was recently helping update the [grails cxf plugin][3] to use cxf 2.5.2, I found out they changed the way that username token was done.

<!-- more -->

#### Apache Cxf Security ####

All I have to say is good luck with using the sample code from the [apache cxf security docs][4].  Their code for 2.5.x is lacking and the code provided didn't work and caused me a lot of ???? moments.

The [cxf plugin][3] wires up service factories that will match the name of your exposed service such as `secureService` with bean named `secureServiceFactory`.  You will want to inject any interceptors onto that factory during application boot.  For the following examples I use the BootStrap.groovy to inject these.

#### Grails Cxf Interceptor Injection 2.3.x ####

This is the "old" way of adding simple token authentication with 2.3.x.

``` groovy
import org.apache.cxf.ws.security.wss4j.WSS4JInInterceptor
import org.apache.ws.security.WSConstants
import org.apache.ws.security.WSPasswordCallback
import org.apache.ws.security.handler.WSHandlerConstants

import javax.security.auth.callback.Callback
import javax.security.auth.callback.CallbackHandler
import javax.security.auth.callback.UnsupportedCallbackException

class BootStrap {

    def secureServiceFactory

    def init = { servletContext ->

        Map<String, Object> inProps = [:]
        inProps.put(WSHandlerConstants.ACTION, WSHandlerConstants.USERNAME_TOKEN);
        inProps.put(WSHandlerConstants.PASSWORD_TYPE, WSConstants.PW_TEXT);
        inProps.put(WSHandlerConstants.PW_CALLBACK_REF, new CallbackHandler() {

            void handle(Callback[] callbacks) throws IOException, UnsupportedCallbackException {
                WSPasswordCallback pc = (WSPasswordCallback) callbacks[0]
                println pc.identifier
                println pc.password
                if(pc.identifier == "wsuser" && pc.password != "secret") {
                    println "error :: wrong password"
                    throw new IOException("wrong password")
                }
            }
        })
        secureServiceFactory.getInInterceptors().add(new WSS4JInInterceptor(inProps))
    }
}
```

#### Grails Cxf Interceptor Injection 2.4.x-2.5.x ####

Since the new apache cxf 2.4.x and 2.5.x use a Validator instead of the callback, here is how you would now inject that same check into the same service factory.  I am using an anonymous UsernameTokenValidator class just like the anonymous callback in the previous example.

``` groovy
import org.apache.cxf.ws.security.wss4j.WSS4JInInterceptor
import org.apache.ws.security.WSConstants
import org.apache.ws.security.WSSecurityEngine
import org.apache.ws.security.WSSecurityException
import org.apache.ws.security.handler.WSHandlerConstants
import org.apache.ws.security.validate.UsernameTokenValidator
import org.apache.ws.security.validate.Validator

import javax.xml.namespace.QName

class BootStrap {

    def secureServiceFactory

    def init = { servletContext ->

        Map<String, Object> inProps = [:]
        inProps.put(WSHandlerConstants.ACTION, WSHandlerConstants.USERNAME_TOKEN);
        inProps.put(WSHandlerConstants.PASSWORD_TYPE, WSConstants.PW_TEXT);
        Map<QName, Validator> validatorMap = new HashMap<QName, Validator>();
        validatorMap.put(WSSecurityEngine.USERNAME_TOKEN, new UsernameTokenValidator() {

            @Override
            protected void verifyPlaintextPassword(org.apache.ws.security.message.token.UsernameToken usernameToken, org.apache.ws.security.handler.RequestData data)
                throws org.apache.ws.security.WSSecurityException {
                if(data.username == "wsuser" && usernameToken.password == "secret") {
		    println "username and password are correct!"
		} else {
		    println "username and password are NOT correct..."
                    throw new WSSecurityException("user and/or password mismatch")
                }
            }
        });
        inProps.put(WSS4JInInterceptor.VALIDATOR_MAP, validatorMap);
        secureServiceFactory.getInInterceptors().add(new WSS4JInInterceptor(inProps))
    }

    def destroy = {
    }
}
```

#### Conclusion ####

My frustrations really only apply to the username token authentication issue, but I haven't tried getting the certificate or ldap authentication working on the server side in 2.5.2 yet.  In general if you need in or out logging or security interceptors on your [cxf plugin][3] exposed services, the above mentioned is a pretty good way to get them on there.  What you put into the properties of those interceptors to make them work is on you.  Good Luck!

[1]: https://www.github.com/ctoestreich/cxf-client-demo (Grails Cxf Client Demo)
[2]: https://www.github.com/ctoestreich/cxf-client (Grails Cxf Client Plugin)
[3]: http://www.grails.org/plugin/cxf (Grails Cxf Plugin)
[4]: http://cxf.apache.org/docs/ws-security.html (Apache Cxf Security Docs)
