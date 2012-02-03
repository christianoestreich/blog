---
layout: post
title: "Groovy AST Transformations - Part 1"
slug: groovy-ast-transform-part-1
date: 2012-02-03 17:00
comments: true
status: publish
share: true
published: true
categories: 
- Technology
tags: 
- Grails
- Groovy
- grails
- groovy
- ast
- transform
- transformation
---

Grails Redis Plugin Memoization Annotation Transformation (A Retrospective on Groovy AST) - Recently while developing a prototype application for performance testing using [redis][redis] and [jesque][jesque] (see [post][post]) I got to thinking "why doesn't the grails redis plugin currently have support for annotation based memoization like spring cache?"  I figured I would set out to add that support and learn to write [Groovy AST Transformations][ast] at the same time.  The process was long and arduous and I learned a lot during my several weeks of coding.

<!-- more -->

## First Steps

I started off by reading articles on AST and found many great examples of existing AST transformations, blogs, and tests already written that I could leverage.  Here are some if you are looking for additional resources:

* [Memoization AST Transformation Source Code][github]
* [AST Builder Examples][ast1]
* [Lessons Learnt Developing Groovy AST Transformations][lessons]
* [Local AST Transformations][localast]
* [Building AST Guide][buildingastguide]
* [Groovy AST Transformations by Example: Adding Methods to Classes][example1]
* [AST Transformations: Creating a Complex AST Transformation][transform1]
* [AST Transformations: Compiler Phases and Syntax Trees][transform2]
* [AST Transformations: The transformation itself][transform3]
* [Unit Testing AST][unit]

There are a lot more out there in the world and you can find plenty [here][lmgtfy].

## The End Goal

The end goal was pretty simple; to transform an annotated method like the first below during compile time into something that looked like the second method below at runtime.  Using an annotation with a key, expire, etc. and injecting code that would wrap all the method contents into a call to an appropriate redisService.memoize method.  I would then create memoize annotations for each type of memoize to be performed (domain, list, hash, set, etc).

Turn this:
``` groovy
    @Memoize(key = '#{text}')
    def method(String text, Date date) {
        return "$text $date"
    }
```

Into this:
``` groovy
    def method(String text, Date date) {
        return redisService.memoize(text) {
            return "$text $date"
        }
    }
```

## Start Coding - Issue 1

Getting started was easy.  I created the annotation class Memoize.groovy and the actual transformation MemoizeASTTransformation.groovy as follows:

``` groovy
    @Retention(RetentionPolicy.SOURCE)
    @Target([ElementType.METHOD])
    @GroovyASTTransformationClass(['grails.plugin.redis.ast.MemoizeASTTransformation'])
    @interface Memoize {
        Class value() default {true};
        String key() default '';
        String expire() default '';
    }
```

``` groovy
    @GroovyASTTransformation(phase = CompilePhase.CANONICALIZATION)
    class MemoizeASTTransformation implements ASTTransformation {
        void visit(ASTNode[] astNodes, SourceUnit sourceUnit) {
            println 'in transformation'
        }
    }
```

Easy enough right?!  When trying to decorate a service method in the project with the `@Memoize` method I ran into my first big hurdle... it didn't work.  I scratched my head for a long time.  Errors during compile?  No.  Printing 'in transformation' during compile?  No.

I will cut to the chase and give you the solution to this issue.  Having another project using the AST annotations that pointed to the grails-redis plugin (AST annotation source) inline fixed this issue.  Why? Well it appears that the AST Transformation classes themselves are compiled along with everything else so during the actual `CompilePhase.CANONICALIZATION` there are no ASTs available to apply yet since they aren't compiled.  When a project was consuming the source as a plugin, it would compile the plugin code first and then compile the new project and the correct statement would print out.  I am not sure if I was doing something wrong or if there is another way around this, but for me this solution worked like a charm.

## Write More Code - Issue 2

I was able to move beyond those issues and start adding a bunch of code to the MemoizeASTTransformation.groovy class.  Everything was humming along nicely.  On a side note, I did have a bit of a hard time deciding between using the AstBuilder or the more verbose statements and expressions to build up the code and opted for the more verbose usage of the direct *Statements and *Expressions.

I had built up a fair amount of AST code that seemed to be working as expected until it came time to create the method closure to hand to the redisService.  If we look at the redis service method definition we can see that it takes a closure as the code to execute if the key isn't found.

``` groovy
    def memoize(String key, Map options = [:], Closure closure)
```

There is a very convenient `ClosureExpression` available in the code to create a closure block of code and it's usage is rather simple.   The following two blocks of code attempts to create the arguments for the memoize method, including the closure, and wrap the existing method code of the annocated method in the closure.  There is a lot to the code here that I am not covering, but I don't want to dumb down the code too much in explaining the issue so I can try and help you avoid it.

``` groovy
    protected void addRedisServiceMemoizeInvocation(BlockStatement body, MethodNode methodNode, Map memoizeProperties) {
        ArgumentListExpression argumentListExpression = makeRedisServiceArgumentListExpression(memoizeProperties)
        argumentListExpression.addExpression(makeClosureExpression(methodNode))

        body.addStatement(
                new ReturnStatement(
                        new MethodCallExpression(
                                new VariableExpression('redisService'),
                                new ConstantExpression('memoize'),
                                argumentListExpression
                        )
                )
        )
    }

    protected ClosureExpression makeClosureExpression(MethodNode methodNode) {
        ClosureExpression closureExpression = new ClosureExpression(
                [] as Parameter[],
                new BlockStatement(methodNode.code.statements as Statement[], new VariableScope())
        )
        closureExpression.variableScope = new VariableScope()
        closureExpression
    }
```

This code failed and failed and failed to run (but did compile) in many different rewrites.  It usually errored at runtime telling me that some variables I referenced in the parent method like $text was not in scope in the closure.  I figured from some earlier troubles with VariableScopes that It was something to do with how the variable scopes were inherited.  I could also see a drastic difference in the decompiled code using [JD-GUI][jdgui] in that the closure created didn't pass into themselves the variables used inside the actual method call.

Again to save headache I discovered, through a miracle I think, the following code:

``` groovy
    VariableScopeVisitor scopeVisitor = new VariableScopeVisitor(sourceUnit);
    sourceUnit.AST.classes.each {
        scopeVisitor.visitClass(it)
    }
```

Running this at the end of the main visit method caused all the variable scopes to be correct propagated down to the newly created objects I was using, including the ClosureExpression.

* [API Docs][api]
* [Sample Usage][sample]

Having inspected the source, I can best describe what it does as _aligning the correct variable scope inheritance in your class_.  There is an explicit visitClosureExpression method that does the magic and injects the scoped variables into the closure.  Following code that uses the visitor pattern is a bit tedious at times, but that is the best I can surmise from digging through that code.  Here is a snippet from the VariableScopeVisitor.java class:

``` java
    public void visitClosureExpression(ClosureExpression expression) {
        pushState();

        expression.setVariableScope(currentScope);

        if (expression.isParameterSpecified()) {
            Parameter[] parameters = expression.getParameters();
            for (Parameter parameter : parameters) {
                parameter.setInStaticContext(currentScope.isInStaticContext());
                if (parameter.hasInitialExpression()) {
                    parameter.getInitialExpression().visit(this);
                }
                declare(parameter, expression);
            }
        } else if (expression.getParameters() != null) {
            Parameter var = new Parameter(ClassHelper.OBJECT_TYPE, "it");
            var.setInStaticContext(currentScope.isInStaticContext());
            currentScope.putDeclaredVariable(var);
        }

        super.visitClosureExpression(expression);
        markClosureSharedVariables();

        popState();
    }
```

I believe it is the line:

    declare(parameter, expression);

which appears to do a lot of the magic in defining and adding the variables to the scope.  The `declare` method ultimately calls

    currentScope.putDeclaredVariable(var);

for each variable in the _n - 1_ scope, in our case the parent of the closure.

This relatively short issue and code solution took a big chunk of my free time in December and early January.  Time I can only hope to save someone else in the future when doing this type of closure wrapping transformation.

## It Works... Almost - Issue 3

When defining a key property string in the annotation the use of the `$` character is not allowed as that will reference an ACTUAL GString at compile time.  We want the value to represent a GString to get interpreted at runtime.  I opted to have the users provide variables in the format `#{var}` leveraging the `#` sign as a replacement for the `$` character.

With that issue resolved it was time to tackle passing the _GString variable_ into the annotation closure as the memoization key.  That went awry very quickly as using a GString gets a little tricky when a user is passing in compound GStrings.  Representing the key as an expression `$variable` might be easy, but using something like `${key}:string${key2.prop}:value2` was proving to be hard as you would have to split and iterate all the GStrings vs non-GStrings in that statement.

The following is some sample code from the codehaus AST builder tests illustrating the typical usage of a GStringExpression in both builder and regular code.

``` groovy
    public void testGStringExpression() {
        // "$foo"
        def result = new AstBuilder().buildFromSpec {
            gString '$foo astring $bar', {
                strings {
                    constant ''
                    constant ' astring '
                    constant ''
                }
                values {
                    variable 'foo'
                    variable 'bar'
                }
            }
        }

        def expected = new GStringExpression('$foo astring $bar',
                [new ConstantExpression(''), new ConstantExpression(' astring '), new ConstantExpression('')],
                [new VariableExpression('foo'), new VariableExpression('bar')])


        AstAssert.assertSyntaxTree([expected], result)
    }
```

I went down the path of trying to parse the user provided string into a meaningful GStringExpression with little to no luck using complex/compound strings.

I figured if I could combine the `AstBuilder.buildFromString{}` method I might be able to use the statement(s) it generated and inject them into the code while letting the AstBuilder do the work in creating the GStringExpression.  After some tweaking, this is what I came up with, and it worked!

``` groovy
    protected void addRedisServiceMemoizeKeyExpression(Map memoizeProperties, ArgumentListExpression argumentListExpression) {
        if(memoizeProperties.get('key').toString().contains('#')) {
            def ast = new AstBuilder().buildFromString("""
                "${memoizeProperties.get('key').toString().replace('#', '$').toString()}"
           """)
            argumentListExpression.addExpression(ast[0].statements[0].expression)
        } else {
            argumentListExpression.addExpression(new ConstantExpression(memoizeProperties.get('key').toString()))
        }
    }
```

The real guts of this is in the following statements.

``` groovy
    def ast = new AstBuilder().buildFromString("""
        "${memoizeProperties.get('key').toString().replace('#', '$').toString()}"
    """)
    argumentListExpression.addExpression(ast[0].statements[0].expression)
```

Combining the expression built from the AstBuilder with the ArgumentListExpression married well together and I was happy that the solution ended up being so simple.  At one point I think the parsing, looping, etc. logic was nearly 100 lines of frustrating and non-working code.

## Up Next

Next week I will post a more concise list of AST-isms that I feel are important when working with the code and things to be mindful of when coding.  It may end up looking similar to what Graeme posted on [lessons learned][lessons].  I think the pain I experienced at least warrants a list of things to do/avoid next time around.  Stay Tuned!

## Code

The memoization AST transformation code I am referencing here is available at [github][github].

[redis]: http://www.grails.org/plugin/redis (Redis Plugin)
[jesque]: http://www.grails.org/plugin/jesque (Jesque Plugin)
[post]: http://www.christianoestreich.com/2012/02/grails-performance-framework/ (My Blog)
[ast]: http://groovy.codehaus.org/Compile-time+Metaprogramming+-+AST+Transformations (Groovy AST)
[jdgui]: http://java.decompiler.free.fr/?q=jdgui (JD-GUI)
[lessons]: http://grails.io/post/15965611310/lessons-learnt-developing-groovy-ast-transformations
[github]: https://github.com/grails-plugins/grails-redis/tree/master/src/groovy/grails/plugin/redis (Memoization AST Transformation Code)
[ast1]: http://svn.codehaus.org/groovy/trunk/groovy/groovy-core/src/test/org/codehaus/groovy/ast/builder/AstBuilderFromSpecificationTest.groovy
[localast]: http://groovy.codehaus.org/Local+AST+Transformations
[buildingastguide]: http://groovy.codehaus.org/Building+AST+Guide
[example1]: http://java.dzone.com/articles/groovy-ast-transformations
[transform1]: http://joesgroovyblog.blogspot.com/2011/10/ast-transformation-using-astbuilder.html
[transform2]: http://joesgroovyblog.blogspot.com/2011/09/ast-transformations-compiler-phases-and.html
[transform3]: http://joesgroovyblog.blogspot.com/2011/09/ast-transformations-transformation.html
[unit]: http://blog.andresteingress.com/2010/06/18/unit-testing-groovy-ast-transformations/
[lmgtfy]: http://lmgtfy.com/?q=groovy+ast
[api]: http://groovy.codehaus.org/api/org/codehaus/groovy/classgen/VariableScopeVisitor.html
[sample]: http://www.devdaily.com/java/jwarehouse/groovy/src/main/org/codehaus/groovy/tools/javac/JavaAwareCompilationUnit.java.shtml