---
author: ctoestreich
date: '2011-03-30 07:39:36'
layout: post
comments: true
slug: jenkins-upgrade-script
status: publish
title: Jenkins Upgrade Script
wordpress_id: '69'
categories:
- Technology
tags:
- apache
- auto
- bash
- ci
- continuous integration
- jenkins
- script
- tomcat
- war
---

I got really tired of manually upgrading [Jenkins][1] on my build server so I
wrote a little bash script to do it for me.

```
    #!/bin/bash
     echo "stopping tomcat"
     sh /etc/init.d/tomcat6 stop
     cd /var/lib/tomcat6/webapps
     echo "removing jenkins"
     rm -rf jenkins
     rm -rf jenkins.war
     echo "downloading latest jenkins"
     wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war
     echo "starting tomcat"
     sh /etc/init.d/tomcat6 start
     cd ~
     echo "done"
```

I call mine upgrade.sh.  Make sure to set the permissions on the file to
something executable; I set mine to chmod 775.  Then you can run this by
typing the following line.  It should be run with elevated permissions so it
can interact with processes like starting and stopping the server.

    $  sudo ./upgrade.sh

You may have to tweak the locations to suit your needs.  Another thing you may
want to do is move your jenkins folder instead of removing it, but since
config is stored else where you should be okay to just remove the web app and
put the new war in it's place.

This script assumes you are running [Jenkins][1] under [Tomcat][2] and not
standalone.

   [1]: http://jenkins-ci.org/ (Jenkins CI)
   [2]: http://tomcat.apache.org/ (Apache Tomcat)