---
author: ctoestreich
date: '2013-07-02 10:00:00'
layout: post
comments: true
slug: grails-plugin-template-override
status: publish
title: Grails Plugin Template Override
categories:
- Technology
tags:
- groovy
- Groovy
- Grails
- grails
- plugin
- override
- overriding
- templates
- template
---

Recently in the [Grails Filterpane Plugin][1] I had to figure out a way to allow users to selectively override the bundled template files that were rendered in the filterpane taglib.  I was able to achieve this through a bit of simple code that may be helpful to plugin authros in the future.

<!-- more -->

## The Code

The bit of magic in the code below is the line `groovyPageLocator.findTemplateInBinding(path, pageScope)`.  This equates to is asking grails to find a template for the path in the project scope.  I then check if the result of the call is null and append the filterpane plugin to the resulting map causing the render to use the plugin vs the local template.  This works well because apparently you can specify `plugin: null` in the render block which is the same as saying "use the current project scope".

{% codeblock FilterPaneTagLib.groovy %}
 def filterButton = { attrs, body ->
    //do some work here
    //...
    //...

    Map template = getTemplatePath('filterButton');
    out << render(template: template.path, plugin: template.plugin, model: renderModel)
}

public LinkedHashMap<String, String> getTemplatePath(String templateName) {
    def path = appendPiecesForUri("/_filterpane", templateName) //create the url path
    def template = [path: path] //add it to the map
    def override = groovyPageLocator.findTemplateInBinding(path, pageScope) //check if template exists in project scope
    if(!override) {
        template.plugin = 'filterpane' //looks like no, so use default plugin version instead
    }
    template  //return map
}
{% endcodeblock %}

   [1]: http://grails.org/plugin/filterpane (Grails Filterpane Plugin)
