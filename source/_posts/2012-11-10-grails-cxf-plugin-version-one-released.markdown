---
author: ctoestreich
date: '2012-11-10 10:52:02'
layout: post
comments: true
slug: grails-cxf-plugin-version-one-released
status: publish
title: Grails CXF Plugin Version 1.x Released
categories:
- Technology
tags:
- cxf
- Grails
- jaxb
- plugin
- soap
- wsdl2java
- rest
- rs
- jax-rs
- jax-rs
---

The [Grails Cxf Plugin][3] makes exposing classes (services and endpoints) as SOAP web services easy and painless.  Since version 1.0.0, it has been rewritten and enhanced to support more features including the migration to grails 2.x.

The current cxf version is [2.6.2](https://issues.apache.org/jira/secure/ReleaseNote.jspa?projectId=12310511&styleName=Html&Create=Create&version=12321668)

Some new things as of version 1.x are as follows:

* The plugin will autowire configured classes in the grails-app\endpoints\** AND the grails-app\services\** directories
* Endpoint creation scripts create-endpoint and create-endpoint-simple will create cxf artefacts in grails-app\endpoints
* Service creation scripts create-cxf-service and create-cxf-service-simple will create cxf artefacts in grails-app\services
* The suggested pattern to isolate cxf endpoints is to have endpoints live in grails-app/endpoints directory (or you can use grails-app/services for overlapping and shared services)
* Built in support for simple Map response type handling via `@XmlJavaTypeAdapter(GrailsCxfMapAdapter.class)` method annotation has been included to use or to kick start your own map adapter creation
* Many new examples to help with configuration can be found in the source via functional specs and test classes at <https://github.com/thorstadt/grails-cxf>
* Default plugin configuration is provided via `DefaultCxfConfig.groovy`.  Although usually not necessary, you can override in your project's Config.groovy
* The default url for wsdl viewing remains `http://.../[app name if not root]/services` as it was in previous versions.  Multiple cxf servlet endpoints can be configured or the default changed via Config.goovy
* Wsdl First services are now available to use
* Plugin should be *mostly* backwards compatible and work in grails 1.3.x

You can get more details at [https://github.com/thorstadt/grails-cxf][1]

There is also a demo project if you do not want to run the cxf plugin code inline at [https://github.com/ctoestreich/grails-cxf-test][2]

   [1]: https://github.com/thorstadt/grails-cxf (grails cxf plugin)
   [2]: https://github.com/ctoestreich/grails-cxf-test (grails cxf test project)
   [3]: http://grails.org/plugin/cxf (grails cxf plugin)

