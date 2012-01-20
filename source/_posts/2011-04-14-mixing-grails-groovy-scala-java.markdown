---
author: ctoestreich
date: '2011-04-14 11:59:14'
layout: post
comments: true
slug: mixing-grails-groovy-scala-java
status: publish
title: Mixing Grails, Groovy, Scala & Java
wordpress_id: '74'
categories:
- Technology
tags:
- Grails
- groovy
- idea
- intellij
- Java
- Scala
---

As I have mentioned earlier, I am a huge fan of grails and would love to ditch
our existing java/spring/custom code framework and move to grails
holistically.  A few of our senior people on the team really want to move to
scala to get rid of a lot of the clutter code we write in our java stacks.  To
further the grails cause, I decided to see if I could get the [scala
plugin][1] for grails working and see how deeply I could integrate the scala
code into the application.  While I was at it I decided that I might as well
throw in java as well for giggles.  I really like both [groovy][2] and
[scala][3].  Each language has its advantages, but there is a general
consensus on the team at work that the statically typed scala would be better
for our inline conversion of existing java code.

## Setting Up The Environment

All the [source code][4] for this can be found at GitHub.  You can pull it
down via the command:

    git clone git@github.com:ctoestreich/grails-scala.git

I am assuming you will be using IntelliJ (as it is my favorite IDE).  If you
are using Eclipse you will be on your own for a lot of the set up pieces.  I
am also assuming you have grails already setup on your machine correctly.  The
first thing to do is install the scala plugin for grails via the following
grails command:

    grails install-plugin scala

If you are using [IntelliJ][5], you should also install the scala plugin for
IDEA

[![Install Scala Plugin][6]][7]


## Starting The Coding

I started the coding and realized that I needed to be conscious about what
type of objects inherited from what type of interfaces/traits.  I initially
tried having everything inherit from a Java Interface.  This solution compiled
and worked okay.  I then moved to trying to get everything to extend a groovy
interface.  The code exploded.  It was immediately obvious that the scalac
command was run first and compiling the scala and java sources before groovy.
Having the java and scala extend a groovy interface wasn't going to work.  In
the end I decided to go with a scala trait due to its enhanced functionality
and support in scala and standard java interface usage.  I spent the majority
of my time fuddling with this compilation order problem and getting the three
languages to compile nicely together.

[![][8]][9]

First I defined a scala trait.

``` scala
    package com.far.scape.scala
    trait Cast {
      def race():String
      def actor():String
      def save()
    }
```

Then I created the following objects.

**Java Object**

``` java
    package com.far.scape;
    import com.far.scape.scala.Cast;

    //public class Kadargo implements JavaCast {
    public class Kadargo implements Cast {
        private String name;
        
        public String getName() {
            return name;
        }
        
        public void save(){
            System.out.println("in java save");
        }

        public void setName(String name) {
            this.name = name;
        }

        public String race() {
            return "I am Luxan";
        }

        public String actor() {
            return "Anthony Simcoe";
        }
    }
```

**Scala Object**

``` scala
    package com.far.scape.scala
    //import com.far.scape.JavaCast
    //class Crichton extends JavaCast  {
    class Crichton extends Cast  {
      var name = ""

      def save() {
        println("in scala save")
      }

      def race():String = {
        "Frelling Human!"
      }

       def actor():String = {
        "Ben Browder"
      }
    }
```

**Groovy Object**

``` groovy
    package com.far.scape
    
    import com.far.scape.scala.Cast
    //class Chiana implements JavaCast {
    class Chiana implements Cast {
      String name

      String race() {
        "I am Nebari"
      }

      String actor() {
        "Gigi Egdley"
      }

      void save() {
        println "in groovy save"
      }
    }
```

One thing to note is that the directory structure matters.  There is a bug
with the scala grails plugin at the time I wrote this post with grails 1.3.5+
and scala plugin 0.5.  I had to go into the scala plugin Events.groovy code
and comment out the following line:

_**//addScalaToCompileSrcPaths(compileBinding)**_

I found the following note on the now-depreciated plugin page (not sure why
this is gone now since the version didn't change).

> NOTES: current 0.5 version seems incompatible with **Grails** 1.3 As quick
and dirty fix we do the following to the installed script
scala-0.5/scripts/Events.groovy: 1) **comment**
**out**//**addScalaToCompileSrcPaths**(compileBinding)
    * then we have to put scala sources under src/java (src/scala is not
usable)

I have all my scala code under src/java/com/far/scape/scala.  I decided to put
it in a dir under the package named scala so it was easier to differentiate.

I created a regular grails service under grails-app/services/[package-
name]/GrailsService.groovy.  I mocked up a save method on the interface and
put an implementation in each class.  Ideally I will be able to actually
persist the objects, but for now I just used save on the interface to see how
well the trait worked across java, scala and groovy.

``` groovy
    package com.far.scape

    import com.far.scape.scala.Cast

    class GrailsService {
        static transactional = true

        def saveObject(Cast cast) {
          println "Grails Service saving object ${cast.class.name}"
          cast.save()
          true
        }
    }
```

## Testing The Code

I wrote a really simply integration test to pass all the object types to the
grails service saveObject method.

``` groovy
    package com.far.scape

    import grails.test.GrailsUnitTestCase
    import com.far.scape.scala.Crichton

    class GrailsServiceTests extends GrailsUnitTestCase {
      def grailsService

      protected void setUp() {
        super.setUp()
      }

      protected void tearDown() {
        super.tearDown()
      }

      void testSaveGroovyObject() {
        def chiana = new Chiana(name: "Chiana")
        assertTrue grailsService.saveObject(chiana)
      }

      void testSaveJavaObject() {
        def kadargo = new Kadargo(name: "Ka'Dargo")
        assertTrue grailsService.saveObject(kadargo)
      }

      void testSaveScalaObject() {
        def crichton = new Crichton(name: "Crichton")
        assertTrue grailsService.saveObject(crichton)
      }
    }
```

To run the integration tests execute the command below.  The -echoOut is to
show the output from any print statements you have in your tests.

    grails test-app -echoOut

Here is the result

[![Testing Mock Save][10]][11]

I played around a bit with creating a scala service.  I was able to get it
working as a standard manually created bean, but didn't get the auto-
wiring/injection of the scala service working in the integration tests.
Granted, I didn't try that hard as I wanted to make that a topic of another
post.

## Client Side Code

I also added a simple controller and view to test adding different objects to
gsp page.

``` groovy
    package grails.scala

    import com.far.scape.Chiana
    import com.far.scape.scala.Crichton
    import com.far.scape.Kadargo

    class MoyaController {
        def index = {
          def characters = [new Chiana(), new Kadargo(), new Crichton()].asList()
          [view:"index","characters":characters]
        }
    }
```

Then I created an index.gsp under grails-app/views/moya.

``` html
    <html>
    <body>
    <g:each in="${characters}" var="character">
    ${character.class.name}<br>
    ${character.race()}<br>
    ${character.actor()}<br>
    <p></p>
    </g:each>
    </body>
    </html>
```

This should render the following:

[![Output View][12]][13]

All the [source code][4] for this can be found at GitHub.

Happy Coding.

   [1]: http://grails.org/plugin/scala (Grails Scala Plugin)

   [2]: http://groovy.codehaus.org/ (Groovy)

   [3]: http://www.scala-lang.org/ (Scala)

   [4]: https://github.com/ctoestreich/grails-scala (Source Code)

   [5]: http://www.jetbrains.com/idea/ (IntelliJ IDE)

   [6]: http://build.christianoestreich.com/wp-content/uploads/2011/04/install_scala_plugin.png (Install Scala Plugin)

   [7]: http://build.christianoestreich.com/wp-content/uploads/2011/04/install_scala_plugin.png

   [8]: http://build.christianoestreich.com/wp-content/uploads/2011/04/save_interface.png (Save Interface)

   [9]: http://build.christianoestreich.com/wp-content/uploads/2011/04/save_interface.png

   [10]: http://build.christianoestreich.com/wp-content/uploads/2011/04/test_output_save.png (Testing Mock Save)

   [11]: http://build.christianoestreich.com/wp-content/uploads/2011/04/test_output_save.png

   [12]: http://build.christianoestreich.com/wp-content/uploads/2011/04/groovy-scala-view.png (Output View)

   [13]: http://build.christianoestreich.com/wp-content/uploads/2011/04/groovy-scala-view.png

