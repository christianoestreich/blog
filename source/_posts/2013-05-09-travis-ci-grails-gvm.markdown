---
author: ctoestreich
date: '2013-05-09 10:00:00'
layout: post
comments: true
slug: travis-ci-grails-gvm
status: publish
title: Travis CI & Grails GVM
categories:
- Technology
tags:
- groovy
- travis
- travis-ci
- gvm
- Groovy
- Grails
- grails
- version
- build
- continuous
---

For quite a while I have been stuck using grails 2.2.0 on a [Travis CI][1] build server due to any later version not being added to the groovy ppa on ubuntu.  This was done because of the move to the [GVM][2] tool.  I was able to cobble together a travis script and [GVM][2] hack to get this working.  This is great becuase not I can use Grails 2.2.1, 2.2.2, etc.

<!-- more -->

## The Hack

When setting up the script I noticed that it was failing due to a return code of 1.  I forked and inspected the [GVM][2] code and identified a fix.  It needed to return a 0 after it does the install.

I have submitted a [pull request][4] to fix the return issue in the gvm-install.sh script, but in the meantime you will need to keep the bit in the before-install block where it grabs my file and replaces the current one as seen in the script below.

## The Setup

Travis appears to come with a package called GVM already on the box for Go language management.  We have to remove that first via `rm -rf ~/.gvm`.  We are then free to install [GVM][2] as it will not fail the check for the ~/.gvm directory.

Travis doesn't like you to pipe commands back to bash as is suggested in the GVM docs via `curl -s get.gvmtool.net | bash` so we have to get the install script and stick it into local file to execute.  We do this via this code block.

```
curl -s get.gvmtool.net > ~/install_gvm.sh
chmod 775 ~/install_gvm.sh
~/install_gvm.sh
```

We then have to tell [GVM][2] to not prompt us defaults during install by appending to the config `echo "gvm_auto_answer=true" > ~/.gvm/etc/config`.

Then we hack the install with my pull (which can hopefully be removed later) via `curl -s https://raw.github.com/ctoestreich/gvm/master/src/main/bash/gvm-install.sh > ~/.gvm/src/gvm-install.sh`

After that we are golden to set up the source and install any version of grails we need.

```
source ~/.gvm/bin/gvm-init.sh
gvm install grails 2.2.1
gvm use grails 2.2.1
```

The rest of the build file is pretty vanilla.


## The Script

Here is the .travis.yml script that you will need for your project and a link to a [working example][3].

```
language: groovy

jdk:
- oraclejdk6

before_install:
- rm -rf ~/.gvm
- curl -s get.gvmtool.net > ~/install_gvm.sh
- chmod 775 ~/install_gvm.sh
- ~/install_gvm.sh
- echo "gvm_auto_answer=true" > ~/.gvm/etc/config
- curl -s https://raw.github.com/ctoestreich/gvm/master/src/main/bash/gvm-install.sh > ~/.gvm/src/gvm-install.sh
- source ~/.gvm/bin/gvm-init.sh
- gvm install grails 2.2.1
- gvm use grails 2.2.1

branches:
  only:
    - master

script: grails test-app --non-interactive
```

Once the pull request is complete you will be able to remove the line:

```
- curl -s https://raw.github.com/ctoestreich/gvm/master/src/main/bash/gvm-install.sh > ~/.gvm/src/gvm-install.sh
```

   [1]: https://travis-ci.org (Travis CI)
   [2]: http://gvmtool.net/ (the Groovy enVironment Manager)
   [3]: https://github.com/Grails-Plugin-Consortium/grails-filterpane-demo/blob/master/.travis.yml (Working Example)
   [4]: https://github.com/gvmtool/gvm/pull/167 (Pull Request)