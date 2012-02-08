---
author: ctoestreich
date: '2011-05-06 09:33:10'
layout: post
comments: true
slug: testing-grails-rest-services
status: publish
title: Testing Grails REST Services
wordpress_id: '118'
categories:
- Technology
tags:
- cache
- ehcache
- gpars
- Grails
- groovy
- melody
- performance
- script
- springcache
---

Recently I needed to run a simulated load test on some rest services to see
what the memory footprint would be as I varied my cache size and strategy.  I
looked for a good tool to do this and couldn't really find anything that fit
my need easily.  I liked the SOAP UI test runner, but I couldn't quite get it
working like I wanted.

I ended up writing a script that I can run from the grails shell to invoke the
REST service using an xml data file to hold the IDs of the objects I wanted to
load.   I played around with the idea of just grabbing the items from the DB,
but I really wanted to minimize the impact on the application during the
loading so I grabbed all the data from dbvis and exported it into an XML file
that I slurp in through groovy.

I took the script one step farther and implemented gpars as well to try and
speed up the load.  There were some issues with the server becoming inundated
with too many requests so I added a 100ms sleep to every request.  I still
need to tune that to get the best throughput without causing the server to
throw exceptions from having unavailable listener threads.

_**Note**: I changed some of the data in these scripts to use dummy names and
paths as to not violate any corp policies._

I created a script and put it under scripts\performance\MyScript.groovy
(obviously not called MyScript, but you get the point).  By wrapping the
script in a closure with the .call() at the end, this will run the default
method when we execute load.  There might be better ways to do this, but I
found it to work quite nicely.  I would suggest moving the thread size to the
config file as it would be easier to change on the fly that way without
recompiling the script.  The grails shell isn't as hot-swap friendly as the
running grails tomcat/jetty instance.  I had some profiling around the code
execution, but when I had to add the sleep, I took it out.  I can see cases
for these scripts where adding it back would be useful.

The script contains the following code.

``` groovy
    import static groovyx.gpars.GParsPool.withPool
    import org.codehaus.groovy.grails.commons.ConfigurationHolder as CH

    def blahStressTest = {
        String path = CH.config.dataDir + File.separator + "mydata.xml"

        println "Loading ${path}.."

        def theData = new XmlSlurper().parseText(new File(path).text)
        def size = theData.ROWSET.ROW.size()

        withPool(3) {
                medData.ROWSET.ROW.eachWithIndexParallel { object, index ->
                        try{
                                def url = new URL("${CH.config.grails.serverURL}/resturl/${object}").text
                    if (index % 100 == 0) println "${Thread.currentThread().name} - ${index} of ${size}"
                                Thread.sleep(100)
                        } catch(Exception e){
                                println "exception ${e.message}"
                        }
                }
        }

        println "completed"
    }.call()
```

I added the following to the config and put a different path under each
environment section as the directory structure is a bit different in each. I
really have no need to run this in prod for now, but I might in the future.

``` groovy
    environments {
      production {
        grails.serverURL = "https://url"
        logDirectory = "/unix/path/logs"
        dataDir = "/unix/projects/myproject/scripts/performance"
     }

      development {
        grails.serverURL = "http://localhost:8080/${appName}"
        logDirectory = "/windows/path/log"
        dataDir = "c:/projects/myproject/scripts/performance"
      }

      test {
        grails.serverURL = "http://testserver:8080/${appName}"
        logDirectory = "/unix/path/logs"
        dataDir = "/unix/projects/myproject/scripts/performance"
      }
    }
```

My xml file is in the same directory as the scripts for now.  It just has some
data that looks like this (as exported directly from dbvis).

``` xml
    <MyData>
    <ROWDATA>
    <ROW>
    <ID>123</ID>
    </ROW>
    <ROW>
    <ID>1234</ID>
    </ROW>
    ...
    </ROWDATA>
    </MyData>
```

I really just wanted to load up all the objects in cache without any object
misses.  I tried doing a 1..100000 type operation, but the IDs of the data I
am using are not very sequential and skip around a bit.

I launched the grails shell using (use which ever env you want to run it for):


    grails dev shell

Once launched I simply type

    load scripts\performance\MyScript.groovy

This technique could come in handy for testing other types of rest/url actions
as well.  I originally had created another controller that would use the rest
plugin's withHttp method to invoke the site, but found that to be a bit clunky
and I didn't like being forced to use up one of my browser tabs to run the
script. :)

I used the [grails melody plugin][1] to see the cache sizes and memory foot
print.  Definitely an awesome plugin!

FYI: To configure the spring cache plugin manually you need to add a file
under the cong\spring folder called resources and add some code like the
following:

``` groovy
    import grails.plugin.springcache.web.key.WebContentKeyGenerator
    import org.springframework.cache.ehcache.EhCacheFactoryBean

    // Place your Spring DSL code here
    beans = {
       MyCache(EhCacheFactoryBean) { bean ->
        cacheManager = ref("springcacheCacheManager")
        cacheName = "MyCache"
        eternal = true
        diskPersistent = false
        memoryStoreEvictionPolicy = "LRU"
        maxElementsInMemory = 100000
      }
    }
```

Anywhere you use the @Cachable("MyCache") it will use this configuration
instead of the default.

Good Luck.

   [1]: http://www.grails.org/plugin/grails-melody (Grails Melody Plugin)

