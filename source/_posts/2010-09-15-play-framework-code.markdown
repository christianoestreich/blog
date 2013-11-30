---
author: ctoestreich
date: '2010-09-15 18:14:03'
layout: post
comments: true
slug: play-framework-code
status: publish
title: Play!(ing) with some code
wordpress_id: '14'
categories:
- Technology
tags:
- Code
- framework
- Java
- Play
- Play Framework
- playframework
- Sample
- Scala
---

I have been doing some analysis on Lift and Scala.  I really like it
so far despite the drawbacks of poor code examples available online.  I also
have some personal projects that I am working on at home and wanted to expand
my knowledge of other frameworks so I decided to check out the [Play! Framework][1].

I ran through the [Learn][2] link on the site for the new 1.1 framework.  It
got me up and running in no time flat.  I was able to see the default page in
a heart beat and it was very easy to go from zero to functional with minimal
setup.

The two things that I wanted to accomplish were to find a framework that was
easy to get running, that supported an MVC model and something with Scala
support.

As I am a re-convert back into Java after spending almost a decade doing
Microsoft development, I have really tried to immerse myself in more than just
plain vanilla Java development.  I have found Scala to be a breadth of fresh
air and a new challenge to help me dust off some of those idle brain cells.

To get Scala support with play you simply have to add the play (play.bat for
windows or play for mac) into your class path.  For the Mac you also need to
"chmod -x play" and "chmod 775 play" on the play file in there to make it
executable as well.

[![Play! Framework Setting Permissions Example Code][3]][4]

After setting up Scala and looking at their docs, I started to discover some
slight differences in what code is required to actually get their examples to
work.  For example their code had the following code to access a Jpa class
within a test.

``` java
    import models.User
    import org.scalatest.matchers.ShouldMatchers
    import play.test._

    class SpecStyle extends UnitFlatSpec with ShouldMatchers {
    "Creating a user" should "be succesfull" in {
     val user = new User("bob@gmail.com", "secret", "Bob").save()
     val bob = User.find("byEmail", "bob@gmail.com").first
     bob should not be (null)
     bob.fullname should be ("Bob")
     }
    }
```

I had to use the following to get the code to run.  I am not sure if I did
something wrong or of the example code was wrong but here is what I had to do
to get it working.

``` java
    import models.User
    import org.scalatest.matchers.ShouldMatchers
    import play.test._
    
    class SpecStyle extends UnitFlatSpec with ShouldMatchers {
    "Creating a user" should "be succesfull" in {
     val user = new User("bob@gmail.com", "secret", "Bob").save()
     val bob = User.find("byEmail", "bob@gmail.com").first
     bob should not be (null)
     bob.get.fullname should be ("Bob")
     }
    }
```

The only thing that is different is the fact that I had to call the get on
bob.get.fullname as calling bob.firstname wasn't getting me a User object that
I could check properties on.  If anyone has any ideas on this by all means let
me know.  Here is the user class/object.

``` java
    package models
    import java.util._
    import play.db.jpa._
    import play.data.Validators._

    @Entity
    @Table(uniqueConstraints=Array(new UniqueConstraint(columnNames=Array("email"))))
    class User(
     @Email
     @Required
     var email: String,

     @Required
     var password: String,
     var fullname: String
    ) extends Model {
     var isAdmin = false
     override def toString() = email
    }

    object User extends QueryOn[User] {
     def connect(email: String, password: String) = {
     find("byEmailAndPassword", email, password).first
     }
    }
```

What I really love about the play framework is the integrated testing,
especially with Selenium, that comes for free with the framework.  More on
that to come soon.  I will post more code to get up and running, but the
sample code on the play site is very easy to get you up and running.

On a side note, I have been using my Mac more and more for development I
really like it now that I have a two button mouse... :)

   [1]: http://www.playframework.org/ (Play! Framework)
   [2]: http://www.playframework.org/documentation/1.1-trunk/home
   [3]: http://build.christianoestreich.com/wp-content/uploads/2010/09/Screen-shot-2010-09-15-at-8.11.21-PM.png (Play! Framework Setup)
   [4]: http://build.christianoestreich.com/wp-content/uploads/2010/09/Screen-shot-2010-09-15-at-8.11.21-PM.png

