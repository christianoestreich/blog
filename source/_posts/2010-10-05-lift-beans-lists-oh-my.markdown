---
author: ctoestreich
date: '2010-10-05 14:43:31'
layout: post
comments: true
slug: lift-beans-lists-oh-my
status: publish
title: Lift & Beans & Lists... OH MY!
wordpress_id: '33'
categories:
- Technology
tags:
- framework
- Java
- Sample
- Scala
---

So during a recent exercise at work to prototype some currently functionality
from Java/JSP to Scala/Lift we needed to support loading some beans from the
spring context and support lists; two things that we were intimately familiar
with in Java but were lost in the weeds with in Lift.  We found that it was
relatively simple, but it took a while to come to that conclusion.  Here is
what we ended up doing.

First we created a helper class to load the context from Spring which turned
out to be as simple as the following:

``` scala
    package hsr.model
    import net.liftweb.http.{LiftRules, S, SHtml}
    import org.springframework.web.context.ContextLoader
    import com.demo.app.icue.helloworld.businesslogic.HelloWorld
    import com.demo.app.common.reference.businesslogic.Reference
    import org.springframework.validation.{MapBindingResult,BindingResult,FieldError,ObjectError}

    /**
     * Some utils for integrating Lift and Spring.
     * http://wordpress.rintcius.nl/post/a-recipe-to-integrate-lift-in-an-existing-spring-based-web-application
     * http://camel.465427.n5.nabble.com/Scala-and-Spring-config-td474898.html
     * http://berlinbrowndev.blogspot.com/2008/02/accessing-spring-framework-from-liftweb.html
     */
    object LiftUtils {
     val context = ContextLoader.getCurrentWebApplicationContext()
     def getHelloWorld: HelloWorld = context.getBean("com.demo.app.icue.helloworld.businesslogic.HelloWorld").asInstanceOf[HelloWorld]
     def getReference: Reference = context.getBean("com.demo.app.common.reference.businesslogic.Reference").asInstanceOf[Reference]
    }
```

The places we found some sample code from are listed in the object javadoc.
Essentially this is loading the [Class]Impl files from the spring context.  So
in this case it loads HelloWorldImpl and ReferenceImpl.

For the next set of code we have a method to turn the List<ReferenceCode> from
the ReferenceImpl into a Map so we can use it more efficiently in Scala.  We
first call the getReference and load up a list of pojo objects from the
database.  We then convert the list into buffer, convert the buffer to a list
and iterate over it and create a map that contains just the data we wanted for
our demonstration.  This code could certainly be condensed more.  We were
unsure when we wrote this prototype of going through the conversion of
Java.List -> Buffer -> Scala.List-> Map was the best approach for this, but it
worked and it served the purpose for the prototype and might be useful for
more people in the future.  Cheers!

``` scala
    def getReference(referenceName: String) = {
     val values = scala.collection.JavaConversions.asBuffer(LiftUtils.getReference.list(referenceName))
     values.toList.map(v => (v.getReferenceCode, v.getReferenceDesc))
     }
```
