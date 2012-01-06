---
author: ctoestreich
date: '2011-05-02 16:51:08'
layout: post
comments: true
slug: gmetrics-codenarc-for-grails
status: publish
title: Gmetrics & Codenarc Script For Grails
wordpress_id: '103'
categories:
- Technology
tags:
- build
- codenarc
- coverage
- gmetrics
- Grails
- jenkins
- scripts
- static analysis
- violations
---

I really wanted to get our project working with sonar and grails.  After some
searching I found very few people that had this working.  Actually I only
found one [here][1].  I tried doing this by adding the pom.xml and invoking
the mvn sonar:sonar target.  Maven got to the end and threw an exception.  I
spent the better part of a day working on this and poking around at the pom
file and finally gave up.

## Setting Up The Environment

All the [source code][2] for this can be found at GitHub.  You can pull it
down via the command:


    git clone git@github.com:ctoestreich/jenkins-sandbox.git

I decided to go with using cobertura, [gmetrics][3] and [codenarc][4] for
reporting on the code.  You need to first add the plugins to your project
using the following commands


    grails install-plugin coverage

    grails install-plugin gmetrics

    grails install-plugin codenarc

I ran the default targets for gmetrics and codenarc and they both produced
html... ugly html.  I was hoping the default output would be a little more
like the sonar dashboard; perhaps a little more web 2.0-ish.  Luckily I ran
across a couple [blog posts][5] by [Herbert Ikkink (mrhaki)][6].  The posts
had some nice xslt to html transformation and style sheets attached to them.
I took the work mrhaki had done and went one step further and created a grails
build target to generate the output for both gmetrics and codenarc and publish
the results through Jenkins.

## Creating The Script

I had first tried to consume the codenarc xml using the violations plugin for
Jenkins, but that was puking all over itself, so I opted for making both
reports simple HTML reports.

First I needed to create a script in grails by running


    grails create-script CodeReports

Then I added the following code to the grails-app\scripts\CodeReports.groovy
file


    includeTargets << grailsScript('Init')

    includeTargets << new File("${codenarcPluginDir}/scripts/Codenarc.groovy")

    includeTargets << new File("${gmetricsPluginDir}/scripts/Gmetrics.groovy")

    configClassname = 'Config'

    target(main: "Add some style to the gmetrics report") {

      depends(compile, codenarc, gmetrics)

      stylizeGmetrics()

      stylizeCodenarc()

    }

    private void stylizeGmetrics() {

      println "add some style to the gmetrics report"

      ant.mkdir(dir: 'target/gmetrics')

      ant.xslt style: "reports/gmetrics.xslt", out:
"target/gmetrics/gmetrics.html", in: 'target/gmetrics.xml'

      ant.copy(todir: 'target/gmetrics') {

        fileset(dir: 'reports') {

          include name: 'default.css'

          include name: '*.png'

          include name: '*.gif'

        }

      }

    }

    private void stylizeCodenarc() {

      println "Add some style to the codenarc report"

      ant.mkdir(dir: 'target/codenarc')

      ant.xslt style: "reports/codenarc.xslt", out:
"target/codenarc/codenarc.html", in: 'target/codenarc.xml'

      ant.copy(todir: 'target/codenarc') {

        fileset(dir: 'reports') {

          include name: 'default.css'

          include name: '*.png'

          include name: '*.gif'

        }

      }

    }

    setDefaultTarget(main)

This new script can be called at the command line by running


    grails code-reports

Some interesting caveats to note.  The paths to the plugins won't resolve
until you run compile at least one time.  So make sure you invoke the compile
target directly or through another script like test-app to get the paths all
set up in grails _**before **_calling code-reports.  I also had some issues
with out-of-date plugins and had to blow away the grails 1.3.6 working
directory to get this to work on local machine and ubuntu (build server) for
my demo project.  It worked no problem on another project... go figure.  Just
go to C:\Documents and Settings\[your user]\.grails\[grails
version]\projects\[project name] and remove the [project name] dir (where
[project name] if the name of your project, etc).  On my build box the dir is
/usr/share/tomcat6/.grails/1.3.6/projects/[project name].

## Additional Required Settings

Add the code below at the end of _grails-app\conf\Config.groovy. _ This will
set up gmetrics and codenarc to produce xml instead of HTML and set the output
for the xml files.  Also I didn't want to scan my test code.  You might want
scan your integration and unit test code to so you can remove those lines or
set them to true.  I am also using a custom codenarc.properties file to
exclude certain patterns.


    gmetrics.reportType = 'org.gmetrics.report.XmlReportWriter'

    gmetrics.outputFile = 'target/gmetrics.xml'

    gmetrics.processTestUnit = false

    gmetrics.processTestIntegration = false

    codenarc.reportType='xml'

    codenarc.reportName='target/codenarc.xml'

    codenarc.processTestUnit = false

    codenarc.processTestIntegration = false

    codenarc.propertiesFile = 'codenarc.properties'

I added the codenarc.properties at the root of the project folder (same dir as
application.properties).  It has one line.


    GrailsStatelessService.ignoreFieldNames=dataSource,scope,sessionFactory,tr
ansactional,*Service,messageSource,s3Credential,applicationContext,expose,prof
iled

Add the code below to the end of _grails-app\conf\BuildConfig.groovy. _This
sets the coverage report to xml for Jenkins to process and excludes the tests.


    coverage {

        xml = true

        exclusions = ["**/*Tests*"]

    }

I created a directory at the root of the application called reports to hold my
report artifacts and xslt files.  These are the files that were provided by
[mrhaki][7].  You can change the logo to whatever you want or muddle with the
css as it suits you.  There are few image files that you can grab from my
[github][8] in addition to the following.

[reports\codenarc.xslt][9]

[reports\gmetrics.xslt][10]

[reports\default.css][11]

So with the script created I ran the following scripts locally to test the
output


    grails test-app -coverage

    grails code-reports

You should get some output in your target dir like the following

[![][12]][13]

Once all that is working we can get to setting up Jenkins.

## Setting Up Jenkins

I am assuming you are at least a bit familiar with Jenkins and are already
building your grails application with it.  You will need to add the following
two plugins

[Cobertura Plugin][14]

[][14][HTML Publisher plugin][15]

You will then need to go to the project admin screen and add code-reports to
your target for your grails build.  Here is mine: _clean "test-app -coverage
--non-interactive" code-reports_

_ _

_[![][16]][17]_

You will then need to add the following to the html report output section and
coverage configuration to get the reports to show up on the home page of the
build.

[![][18]][19]

You should see the areas marked in the red boxes show up on your build

[![][20]][21]

I really like the output format that [mrhaki][7] produced.  Until there is a
better integrated solution with sonar, this is golden.

Here are the report samples

[![][22]][23]


[![][24]][25]


The actual source code that I wrote I neither claim to be useful or
entertaining, use at your own enjoyment.

All the [source code][2] for this can be found at GitHub.  You can pull it
down via the command:


    git clone git@github.com:ctoestreich/jenkins-sandbox.git


   [1]: http://blog.octo.com/en/analyzing-groovy-grails-code/

   [2]: https://github.com/ctoestreich/jenkins-sandbox (Source Code)

   [3]: http://www.grails.org/plugin/gmetrics (Gmetrics Plugin)

   [4]: http://www.grails.org/plugin/codenarc (Codenarc Plugin)

   [5]: http://mrhaki.blogspot.com/2011/01/groovy-goodness-create-codenarc-
reports.html (mrhaki)

   [6]: http://www.mrhaki.com/about/

   [7]: http://mrhaki.blogspot.com

   [8]: https://github.com/ctoestreich/jenkins-sandbox/tree/master/reports

   [9]: https://github.com/ctoestreich/jenkins-
sandbox/blob/master/reports/codenarc.xslt

   [10]: https://github.com/ctoestreich/jenkins-
sandbox/blob/master/reports/gmetrics.xslt

   [11]: https://github.com/ctoestreich/jenkins-
sandbox/blob/master/reports/default.css

   [12]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/code_reports_output.png (code_reports_output)

   [13]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/code_reports_output.png

   [14]: http://wiki.hudson-ci.org/display/HUDSON/Cobertura+Plugin

   [15]: http://wiki.hudson-ci.org/display/HUDSON/HTML+Publisher+Plugin

   [16]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/build_target.png (Build Target)

   [17]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/build_target.png

   [18]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/report_target.png (Report Target)

   [19]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/report_target.png

   [20]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/jenkins_dashboard.png (Jenkins Dashboard)

   [21]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/jenkins_dashboard.png

   [22]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/report_sample1.png (Report Sample Gmetrics)

   [23]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/report_sample1.png

   [24]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/report_sample2.png (Report Sample Codenarc)

   [25]: http://www.christianoestreich.com/wp-
content/uploads/2011/05/report_sample2.png

