---
layout: post
title: "Grails 2.x Deployed To Websphere 7ish"
slug: deploying-grails-2-to-websphere
date: 2012-10-20 12:00
comments: true
status: publish
categories: 
- Grails
- Groovy
- Technology
tags: 
- websphere
- ibm
- deploy
- Grails
- groovy
---
I have struggled a lot with getting our corporate-standard WebSphere container to play nicely with Grails in the past and when we moved to Grails 2.1.1 and WebSphere 7.0 it was no different.

<!-- more -->

#### EAR Script ####

The first thing you will want to do is add the Ear script to your project under `scripts`.

``` groovy
includeTargets << grailsScript("_GrailsWar")

target(ear: "Creates an EAR file from a Grails WAR") {
  war()
  event("StatusUpdate", ["Building EAR file"])
  generateApplicationXml()
  def warDest = new File(warName).parentFile
  def appVersion = metadata.getApplicationVersion()
  def earFile = "${projectTargetDir}/${contextRoot}-${appVersion}.ear"
  ant.ear(destfile: earFile, appxml: appXml, update: true) {
    fileset(dir: warDest, includes: "*.war")
  }
  event("StatusFinal", ["Done creating EAR $earFile"])
}
target(defineContextRoot: "defines the context root") {
  contextRoot = "${grailsAppName}"
}
target(generateApplicationXml: "Generates an application.xml file") {
  depends(defineContextRoot)
  def warDest = new File(warName)
  appXml = "${projectTargetDir}/application.xml"
  new File(appXml).write """<?xml version="1.0" encoding="UTF-8"?>
<application xmlns="http://java.sun.com/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="5" xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/application_5.xsd">
<display-name>${grailsAppName}</display-name>
<module>
    <web>
        <web-uri>${warDest.name}</web-uri>
        <context-root>${contextRoot}</context-root>
    </web>
 </module>
</application>"""
}

setDefaultTarget(ear)
```

#### Install Web.xml and JNDI ####

If, like us, you use JNDI for your database connection you will probably want to add it to the web.xml.  Just run the `grails install-templates` command and modify your web.xml with your jndi node similar to below.

``` xml
<web-app>
...
    <resource-ref id="ResourceRef_12345">
        <res-ref-name>jdbc/MyName</res-ref-name>
        <res-type>javax.sql.DataSource</res-type>
        <res-auth>Application</res-auth>
        <res-sharing-scope>Shareable</res-sharing-scope>
    </resource-ref>
</web-app>
```

You should have your DataSource.groovy set up similar to this for each environment you are using.

``` groovy
environments {
    ...
    production {
        dataSource {
            jndiName = "java:comp/env/jdbc/MyName"
            dialect = "org.hibernate.dialect.OracleDialect"
        }
    }
}
```

If you need this jndi available in dev (run-app local mode) you will need to add it to your Config.groovy.

``` groovy
environments {
    development {
        // this will create the JNDI entry in the tomcat plugin for local execution
        grails.naming.entries = [
                "jdbc/MyName": [
                        type: "javax.sql.DataSource", //required
                        auth: "Container", // optional
                        description: "Data source for Database", //optional
                        driverClassName: "com.mysql.jdbc.Driver",
                        url: "jdbc:mysql://server:3306/db?useOldAliasMetadataBehavior=true",
                        username: "blah",
                        password: "secret",
                        maxActive: "8",
                        maxIdle: "8",
                        poolPreparedStatements: "true"
                ]
        ]
    }
}
```

#### Additional WebSphere Web Xml Settings ####

There are two additional files you will probably need to create and put into your `web-app\WEB_INF` directory.

**ibm-web-bnd.xml**
``` xml
<?xml version="1.0" encoding="UTF-8"?>
<web-bnd xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://websphere.ibm.com/xml/ns/javaee"
         xsi:schemaLocation="http://websphere.ibm.com/xml/ns/javaee http://websphere.ibm.com/xml/ns/javaee/ibm-web-bnd_1_0.xsd" version="1.0">
    <virtual-host name="default_host"/>
    <resource-ref name="jdbc/MyName" binding-name="jdbc/MyName"/>
</web-bnd>
```

**ibm-web-ext.xml**
``` xml
<?xml version="1.0" encoding="UTF-8"?>
<web-ext xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://websphere.ibm.com/xml/ns/javaee"
         xsi:schemaLocation="http://websphere.ibm.com/xml/ns/javaee http://websphere.ibm.com/xml/ns/javaee/ibm-web-ext_1_0.xsd" version="1.0">
    <webApp href="WEB-INF/web_merged.xml#WebApp_ID"/>
    <jsp-attribute name="reloadEnabled" value="true"/>
    <jsp-attribute name="reloadInterval" value="10"/>
    <jsp-attribute name="jdkSourceLevel" value="16"/>
    <jsp-attribute name="trackDependencies" value="true"/>
    <jsp-attribute name="keepgenerated" value="true"/>
</web-ext>
```

#### WebSphere Settings ####

I am not even sure if these are needed, but I did them anyway. (from <http://grails.org/Deployment#Websphere 6.1>)

Server JVM settings:

* In "Application servers > server > Process Definition > Java Virtual Machine" set "Generic JVM arguments" to "-Xverify:none"
* In "Application servers > server > Process Definition > Java Virtual Machine > Custom Properties", add a custom property name: com.ibm.ws.classloader.getInputStream.enableIOException value: true
* In "Application servers > server > Web container > Custom Properties", add a custom property name: com.ibm.ws.webcontainer.invokeFiltersCompatibility value: true

Also you will need to make sure that your Enterprise Application > Class loading and update detection

* Classes loaded with local class loader first (parent last)
* Single class loader for application

#### War Settings ####

In the end you will probably have jar/lib hell and your application may not start correctly.  Make sure all your plugins and dependencies have appropriate excludes.  For example, we are using spring security (not the plugin) and here is one dependency exclude example:

``` groovy
compile('org.springframework.security:spring-security-core:3.0.7.RELEASE') {
    excludes 'spring-expression', 'spring-core', 'spring-context', 'spring-tx',
             'spring-aop', 'spring-jdbc', 'spring-web', 'spring-test', 'aspectjrt',
             'aspectjweaver', 'cglib-nodep', 'ehcache', 'commons-collections',
             'hsqldb', 'jsr250-api', 'log4j', 'junit', 'mockito-core', 'jmock-junit4',
             'spring-aop', 'spring-beans', 'spring-context', 'spring-core', 'spring-tx'
}
```

I currently am also telling grails to remove certain jars from the war in `BuildConfig.groovy` via

``` groovy
grails.war.resources = { stagingDir, args ->
    delete file: "${stagingDir}/WEB-INF/lib/geronimo-servlet_2.5_spec-1.2.jar"
    delete file: "${stagingDir}/WEB-INF/lib/geronimo-jms_1.1_spec-1.1.1.jar"
    delete file: "${stagingDir}/WEB-INF/lib/geronimo-commonj_1.1_spec-1.0.jar"
    delete file: "${stagingDir}/WEB-INF/lib/jta-1.1.jar"
    delete file: "${stagingDir}/WEB-INF/lib/ojdbc.jar"
    delete file: "${stagingDir}/WEB-INF/lib/antlr-2.7.6.jar"
    delete file: "${stagingDir}/WEB-INF/lib/geronimo-javamail_1.4_spec-1.7.1.jar"
}
```


#### Conclusion ####

Good Luck...
