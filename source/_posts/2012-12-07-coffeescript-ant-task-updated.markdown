---
author: ctoestreich
date: '2012-12-07 10:00:00'
layout: post
comments: true
slug: coffeescript-ant-task-updated
status: publish
title: CoffeeScript Ant Task Updated
categories:
- Technology
tags:
- coffeescript
- coffee
- javascript
- ant
- build
---

In one of our projects at work I really wanted to use CoffeeScript as a tool to create better scoped and JSLint friendly JavaScript.  The problem I ran into was that we are using Apache Ant and getting the .coffee to .js was a bit of a chore.

<!-- more -->

I played around with using the coffee.exe from [github][1].  This approach worked, but as our conversion of files and lines grew so did the compile time.  We needed something smarter that could inspect files and skip unmodified files.

I found the CoffeeScript compiling ant task project out on [github][3].  This worked well, but was on an older version of CoffeeScript 0.9.0 and would output all the .js files under a single destination directory.  Meaning all the cs/**/*.coffee files would output to one single directory.  We really wanted to inherit the directory structure and keep the compiled JavaScripts neatly tucked into their respective directory structures.

I decided to [fork and update the project][2].  In doing so I also learned a bit about creating custom ant tasks.  Hopefully anyone else out there who is using ant and wants to use CoffeeScript finds this helpful.  A huge thanks to [Patrick Mueller][6] for creating this project.  With a few small tweaks it has become essential in our JS->CS migration.

Here is the 0.1.6 Change Log:

**0.1.6 - 2012/11/26**

* Updated to CoffeeScript 1.4.0
* Changed Task for `CoffeeScriptC` to inherit `Task` instead of `MatchingTask` so we can add a boolean flag to optionally inherit directory nesting. The new flag is called `nesting`.
* Changed `noWrap` to the new `bare` param for coffee-script compiler.
* Added download directory containing versioned jars.

You can get more details at [https://github.com/ctoestreich/CoffeeScriptAntTasks][2].  The latest 0.1.6 jar can be found in the [downloads][4] directory of the project or the [downloads][5] section of github.

   [1]: https://github.com/alisey/CoffeeScript-Compiler-for-Windows (windows coffescript compiler executable)
   [2]: https://github.com/ctoestreich/CoffeeScriptAntTasks (CoffeeScriptAntTasks fork)
   [3]: https://github.com/pmuellr/CoffeeScriptAntTasks (CoffeeScriptAntTasks fork)
   [4]: https://github.com/ctoestreich/CoffeeScriptAntTasks/tree/master/downloads (0.1.6 download)
   [5]: https://github.com/ctoestreich/CoffeeScriptAntTasks/downloads (0.1.6 download)
   [6]: https://github.com/pmuellr (Patrick Meuller)

