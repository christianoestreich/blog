---
layout: post
title: "Grails Docs Helper Script"
slug: grails-script-docs-helper
date: 2012-02-24 15:00
comments: true
status: publish
categories: 
- Grails
- Groovy
- Technology
tags:
- Grails
- groovy
- scripts
- doc
- documentation
- helper
- soap
---
I am creating a hello world grails project for internal use here at our company.  The project encapsulates both the source code and the documentation in gdoc format.  When a new user comes onboard, they get the project from the source repository and then run the `grails doc` target to generate the guide locally with a tutorial on building a simple application.  In the project I have already included a full test suite that should pass when the tutorial is completed.

I needed a way to have my version control ignored domain, service, and controllers that I was using be added in a way that kept them out of the base grails-app directory so the user could generate them.  At the same time I really wanted to put a link to what the finished classes would look like in the docs somewhere to help users along during the process if needed.  During this process I only wanted to have one master file and not have to maintain the code blocks in the gdoc files separately from actual code.

<!-- more -->

#### Background ####

As I wrote the hello world tutorial I was in effect writting a simple application at the same time.  As I want the user to create all their own artifacts, I added them to my ignore list in version control.  This worked great and allowed me to build the docs and grab snippets of code for the gdoc and still maintain a shell of a project for users to be able to add these artifacts on their own when they followed the guide.

Alas, I really didn't want to just throw away these objects I was creating or leave them on my machine only.  I came up with a way for me to have the best of both worlds by using a Grails script that executes a few simple ant tasks.  I figured I would backup the files into another directory that was checked in as well as generate gdocs out of the code directly at the same time.

#### Creating A Backup Script ####

I created a script in the `scripts` directory of the project named `GenerateDocs.groovy` which would allow me to copy the sources (in my case a directory named `answers` at the project root), generate the gdoc, and run the docs task in one command by invoking the target:

    grails generate-docs

First I added the following block to the code to do the backup and run the grails doc target.

{% codeblock GenerateDocs.groovy %}
includeTargets << grailsScript("_GrailsDocs")

target(main: "Copy controllers, services, domain and views from svn excluded grails-app dirs to the answers dir and create gdoc from them in ref sidebar") {
    //make sure they all compile
    depends(compile)

    //closure to include or exclude certain file types
    def filesetToInclude = {directory ->
        fileset(dir: directory) {
            include(name: '**/*.groovy')
            include(name: '**/*.gsp')
            include(name: '**/*.xml')
            include(name: '**/*.properties')
        }
    }

    def initCopyDirs = ['grails-app/controllers', 'grails-app/domain', 'grails-app/services', 'grails-app/views']

    ant.sequential {
        //add the conf dir for now
        (initCopyDirs + ['grails-app/conf']).each { directory ->
            println "copying $directory to answers/$directory"
            copy(todir: "answers/${directory}") {
                filesetToInclude(directory)
            }
        }
        println "completed copying files"
    }

    depends(docs)
}

setDefaultTarget(main)
{% endcodeblock %}

This would take all the directories in my app that matched the path in the list initCopyDirs and copy then into the answers directory with identical pathing relative to grails-app.  I also only wanted to copy a subset of the files so I used the fileset include parameter to limit the files I copy.  I then added all the files under the answers directory into version control for safe keeping knowing if and when they changed in the original grails-app directory my script would overwrite these backups and they would be added for update in my next commit.  If I created any new files they would have to be manually added to version control.  Not really all that exciting but at least now I would know that my source code wasn't going to disappear since it was being ignored.

#### Creating Answers From Code ####

I wanted to take all the same files we were backing up and create a viewable code item on the Quick Reference sidebar.  To accomplish this I had to transform the .groovy files into .gdoc files and put them into the `src/docs/ref/Answers` directory.  I added the following ant build task to my script above to accomplish that:

{% codeblock GenerateDocs.groovy %}
 initCopyDirs.each { directory ->
    ant.fileScanner {
        filesetToInclude(directory)
    }.each {File file ->
        println "wrapping file ${file.name}"
        echo(file: "src/docs/ref/Answers/${file.name}.gdoc", """
            {code}
                ${file.getText()}
            {code}
        """)
    }
}
{% endcodeblock %}

What that code block accomplishes is to create a gdoc file for all matched files with the file's contents wrapped in `{code}` blocks.  For example it would take a Person.groovy file in the grails-app/domain directory and copy it answers/grails-app/domain an then create a file at src/docs/ref/Ansers/Person.groovy.gdoc with the following code snippet:

``` groovy
{code}
package grails.hello.world

class Person {

    String name
    Integer age
    Date createdDate

    static constraints = {
        name(nullable: false, blank: false)
        age(nullable: false, range: 0..150)
    }
}
{code}
```

That would show up in the generated doc pages as the following:

{% img /images/docs/script.jpg %}

#### The Whole Script ####

{% gist 1902796 GenerateDocs.groovy %}

#### Conclusion ####

Maybe this will be useful for you in some or all of it's entirety in the future!?
