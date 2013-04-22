---
author: ctoestreich
date: '2013-01-17 10:00:00'
layout: post
comments: true
slug: wss4j-simple-security-using-wslite
status: publish
title: WSS4J Simple Security Using Groovy WSLite
categories:
- Technology
tags:
- groovy
- wss4j
- webservice
- soap
- wslite
- Groovy
- Grails
- grails
- cxf
- jaxrs
- ws-security
---

Recently I ran into an issue where using the builtin `HTTPBasicAuthorization` provided by [wslite][1] did not meet the needs of using a simple plain text username and password in the soap header of a soap service request.

<!-- more -->

I tried at first to use the basic authorization through `HTTPBasicAuthorization` realizing that I didn't need http security, but a soap header.  I was able to manually add this header to [wslite][1] in my test case by adding a header closure with the `Security` and `UsernameToken` attributes and children.

``` groovy
def username = "wsuser"
def password = "secret"

SOAPResponse response = client.send {
    envelopeAttributes "xmlns:test": 'http://test.cxf.grails.org/', "xmlns:soapenv":"soapenv"
    version SOAPVersion.V1_1
    header {
        'wsse:Security'('soapenv:mustUnderstand': "1", 'xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', 'xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd') {
            'wsse:UsernameToken'('wsu:Id':"UsernameToken-13") {
                'wsse:Username'(username)
                'wsse:Password'('Type':'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText',password)
                'wsse:Nonce'('EncodingType':'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',new String(password.bytes.encodeBase64().toString()))
                'wsu:Created'('2013-01-18T16:19:17.950Z')
            }
        }
    }
    body {
        'test:simpleMethod' {
            param('HELLO WORLD')
        }
    }
}
```

For more details you can see my usage in the [documentation][2] for the cxf plugin or in the [spock test directly][3].

   [1]: https://github.com/jwagenleitner/groovy-wslite (wslite github)
   [2]: https://github.com/thorstadt/grails-cxf#custom-security-interceptors (cxf plugin documentation)
   [3]: https://github.com/thorstadt/grails-cxf/blob/master/test/functional/org/grails/cxf/test/AnnotatedSecureServiceSpec.groovy (wslite security test)