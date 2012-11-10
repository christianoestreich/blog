---
author: ctoestreich
date: '2012-11-10 10:00:00'
layout: post
comments: true
slug: domain-constraints-grails-spock-updated
status: publish
title: 'Testing Domain Constraints Using Grails 2.x & Spock 0.7'
wordpress_id: '200'
categories:
- Technology
tags:
- constraint
- constraints
- gorm
- Grails
- groovy
- integration testing
- spock
- test
- unit testing
---

We were migrating some existing Java code to Grails 2.0 and we were looking
for a good solution to test domain constraints as we were migrating from an
existing schema. We already use and love Spock for most of our testing needs.
We came up with a relatively easy and reusable solution for testing
constraints that I wanted to share. As we make improvements or changes I will
update the post.

*Update* I have updated the project and samples to work with Grails 2.1.1 and Spock 0.7.

All files for this demonstration can be found at my [grails-spock-constraints][1] GitHub repository.

<!-- more -->

### Setting Up A Domain Object

I set up an arbitrary Person object with some constraints defined on it that
will help demonstrate how to test a wide variety of constraints using spock.
The latest [Person][3] class can be found on github, but here the file at the
time I published this post.

``` groovy
class Person {
    static hasMany = [children: Person]
    String firstName
    String middleName
    String lastName
    String email
    Integer age
    String ssn
    String amex
    String gender
    String login
    Date birthDate
    Float wage
    Integer fingers
    String homePage
    String username
    static constraints = {
        firstName size: 1..50
        middleName size: 0..50
        lastName size: 1..50
        email email: true, notEqual: "bill@microsoft.com"
        age nullable: false, range: 0..150
        ssn unique: true, blank: false
        amex creditCard: true
        gender inList: ["Male", "Female"]
        login matches: "[a-zA-Z]+"
        birthDate max: new Date()
        wage min: 0F, scale: 2
        children maxSize: 10, minSize: 2
        fingers nullable: true
        homePage url: true
        username validator: {
            if(!it.startsWith('boba')) return ['invalid.bountyhunter']
        }
    }
}
```

As you can see there are variety of constraints defined for this object. Some
of these might be nonsensical, but I wanted to demonstrate testing a wide
variety of scenarios. To get the invalid.bountyhunter message working I simply
added the following to the bottom of my message.properties file:
    
``` groovy
person.username.invalid.bountyhunter=Invalid bounty hunter ({2}) tried to
```

log in.

### Grails Constraints

The following are a list of available constraints to define on your domain
classes.

* [attributes][4]
* [blank][5]
* [creditCard][6]
* [email][7]
* [inList][8]
* [matches][9]
* [max][10]
* [maxSize][11]
* [min][12]
* [minSize][13]
* [notEqual][14]
* [nullable][15]
* [range][16]
* [scale][17]
* [size][5]
* [unique][18]
* [url][19]
* [validator][20]
* [widget][21]

I will let the reader check the documentation for the specifics of each
constraint, but I do want to mention a few Gotchas that I ran into:

#### Gottchas

* Setting an inList constraint will not throw an error when passing a blank
'' string. I had assumed that using inList: ['one','two'] would require the
value to be not null and a valid value in list. **Not True**
* Setting a field as url type will allow blank and null values are valid
urls unless you explicitly define blank or nullable as a constraint. (This
seems to be fixed to not allow null by default in final 2.0.0)
* Setting column length for String type should be done using _field: size
0..50_ for a string that can be empty to 50 length. And would be set to
_field: size: 1..100_ for a field that can not be empty and has a max length
of 100. MaxSize and minSize are NOT valid for this.

I will add to that list as I run across items that are unexpected.

### Spock Basics

If you aren't familiar with [Spock][22] and it's feature set, read up on it
and start using it. It brings very rich and powerful tooling to testing your
Grails application. The important pieces to be familiar with for these tests
are the use of the [where clause, parameterizations and the @Unroll
features][23].

It is due to some Spock magic that these tests are able to do so much with
such little code. You will see the line in the tests like the one below of:

``` groovy
def obj = new Person("$field": val)
```

Spock will replace both the _field_ and _val_ with data from the configured
_where_ table. I had to put the field in quotes and treat it as a gstring so
Spock would replace that correctly as simply using the new Person(field: val)
would correctly replace the val, but treat the field as an actual object
property named field instead of being replaced with a valid field name from
the _where_ table.

### Other Possible Techniques

We also really like the [build test data plugin][24] and started off writing
these as integration tests with buildWithoutSave giving us fully hydrated live
domain objects and simply changing the fields we wanted to invalidate. But
with Grails' ability to mock for constraints in unit tests we can run these
tests even faster and earlier in the test cycle if we use unit tests instead.
This is import to us as we can run the test-app -unit in a few seconds during
development. Our machines are not the fastest and running -integration takes
several tens of seconds to run.

Having the objects built with the [build test data plugin][24] is another good
option that some people may opt for since you can mix a richer set of tests
together since you are in a headless app during integration. I will leave that
decision up the readers which method they prefer.

### Testing Constraints

I first created a simple abstract helper class that can build some of our data
for us with reusable methods. This class also holds the function that checks
for the error message to exist on a field after the validate is called. It is
called ConstraintUnitSpec.

``` groovy
import spock.lang.Specification

abstract class ConstraintUnitSpec extends Specification {
    String getLongString(Integer length) {
       'a' * length
   }

   String getEmail(Boolean valid) {
       valid ? "dexter@miamipd.gov" : "dexterm@m"
   }

   String getUrl(Boolean valid) {
       valid ? "http://www.google.com" : "http:/ww.helloworld.com"
   }

   String getCreditCard(Boolean valid) {
       valid ? "4111111111111111" : "41014"
   }

   void validateConstraints(obj, field, error) {
       def validated = obj.validate()
       if (error && error != 'valid') {
           assert !validated
           assert obj.errors[field]
           assert error == obj.errors[field]
       } else {
           assert !obj.errors[field]
       }
   }
}
```

We then create our constraint tests and extend this class. We also use the
[new Grails 2.0 @TestFor annotation][25] to inject some test helper methods
such as mockForConstraintsTests since we are in the unit test phase.

``` groovy
@TestFor(Person)
class PersonSpec extends ConstraintUnitSpec {

}
```

We want to set up the test and tell Grails that we are mocking the person
object so it will add the validate method and we can also add an existing
person to test unique constraints against. We do this by adding the following.

``` groovy
@TestFor(Person)
class PersonSpec extends ConstraintUnitSpec {
    def setup() {
        //mock a person with some data (put unique violations in here so they can be tested, the others aren't needed)
        mockForConstraintsTests(Person, [new Person(ssn: '123456789')])
    }
}
```

After this is done we can start adding some test blocks. The first test I
always add is the test for the standard constraint bounds. This will help with
any refactoring that you you do later to change field definitions such as
changing the size/length of a string. If you had size: 1..50 and your test
checks for 0 and 51 and then change the field constraint to size: 0..50, this
will cause your test to now fail and hopefully save you some headaches later
so you can double check your new change against the domain model and data.
Here is the comprehensive test for the Person class.

``` groovy
    @Unroll("test person all constraints #field is #error")
    def "test person all constraints"() {
        when:
        def obj = new Person("$field": val)

        then:
        validateConstraints(obj, field, error)

        where:
        error                  | field        | val
        'size'                 | 'firstName'  | getLongString(51)
        'nullable'             | 'firstName'  | null
        'size'                 | 'middleName' | getLongString(51)
        'nullable'             | 'middleName' | null
        'size'                 | 'lastName'   | getLongString(51)
        'nullable'             | 'lastName'   | null
        'notEqual'             | 'email'      | 'bill@microsoft.com'
        'email'                | 'email'      | getEmail(false)
        'range'                | 'age'        | 151
        'range'                | 'age'        | -1
        'nullable'             | 'age'        | null
        'blank'                | 'ssn'        | ''
        'unique'               | 'ssn'        | '123456789'
        'creditCard'           | 'amex'       | getCreditCard(false)
        'inList'               | 'gender'     | 'Unknown'
        'matches'              | 'login'      | 'ABC123'
        'max'                  | 'birthDate'  | new Date() + 1
        'min'                  | 'wage'       | -1F
        'maxSize'              | 'children'   | createPerson(11)
        'minSize'              | 'children'   | createPerson(1)
        'url'                  | 'homePage'   | getUrl(false)
        'invalid.bountyhunter' | 'username'   | 'buba'
    }
```

Using Spock, these tests become very concise and easy to read in the where
clause. I set it up so that the _field_ when using _val_ will cause the
_error_ constraint to be violated.

One of the reasons we like this method to test constraints is other constraint
tests simply test for errors to exist on a field, but not the specific type of
constraint violation. While the test for general field errors is still valid,
it isn't quite as fine grained as checking the actual type of constraint
violation expected. An example of a generic constraint testing can be found in
a couple places, but OPI published [an article here][26] on this style of
constraint testing. This is a good starting point if you don't need as fine
grained control as I offer here.

As a side note, every time the test checks for a constraint violation there
will be many fields violated, but we only care about and check for one
specific field and constraint to be violated for each row in the where table
as a time. It might be possible to mix multiple checks together, but we like
testing each scenario and constraint individually.

### Adding Valid Tests

We can also add additional tests that check for valid values. I added some
logic in the validateConstraints method that will expect the field to pass
validation if you use the value in the error column of 'valid' or just a null.
Using the actual word 'valid' instead of null will help the test names be more
concise when Spock unrolls them. In the following age tests we are checking
for both failure and valid criteria. Since age is defined as:

``` groovy
    age nullable: false, range: 0..150
```

We will be checking for values that fall at the limits, outside and inside the
range as well as passing a null value.

``` groovy
    @Unroll("person #field is #error using #val")
    def "test person age constraints"() {
        when:
        def obj = new Person("$field": val)

        then:
        validateConstraints(obj, field, error)

        where:
        error      | field | val
        'range'    | 'age' | 151
        'range'    | 'age' | -1
        'nullable' | 'age' | null
        'valid'    | 'age' | 100
        'valid'    | 'age' | 150
        'valid'    | 'age' | 0
    }
```

Here is the full PersonSpec

``` groovy
   import grails.test.mixin.TestFor
   import spock.lang.Unroll

   @TestFor(Person)
   class PersonSpec extends ConstraintUnitSpec {

       def setup() {
           //mock a person with some data (put unique violations in here so they can be tested, the others aren't needed)
           mockForConstraintsTests(Person, [new Person(ssn: '123456789')])
       }

       @Unroll("test person all constraints #field is #error")
       def "test person all constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error                  | field        | val
           'size'                 | 'firstName'  | getLongString(51)
           'nullable'             | 'firstName'  | null
           'size'                 | 'middleName' | getLongString(51)
           'nullable'             | 'middleName' | null
           'size'                 | 'lastName'   | getLongString(51)
           'nullable'             | 'lastName'   | null
           'notEqual'             | 'email'      | 'bill@microsoft.com'
           'email'                | 'email'      | getEmail(false)
           'range'                | 'age'        | 151
           'range'                | 'age'        | -1
           'nullable'             | 'age'        | null
           'blank'                | 'ssn'        | ''
           'unique'               | 'ssn'        | '123456789'
           'creditCard'           | 'amex'       | getCreditCard(false)
           'inList'               | 'gender'     | 'Unknown'
           'matches'              | 'login'      | 'ABC123'
           'max'                  | 'birthDate'  | new Date() + 1
           'min'                  | 'wage'       | -1F
           'maxSize'              | 'children'   | createPerson(11)
           'minSize'              | 'children'   | createPerson(1)
           'url'                  | 'homePage'   | getUrl(false)
           'invalid.bountyhunter' | 'username'   | 'buba'
       }

       @Unroll("person #field is #error using #val")
       def "test person age constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error      | field | val
           'range'    | 'age' | 151
           'range'    | 'age' | -1
           'nullable' | 'age' | null
           'valid'    | 'age' | 100
           'valid'    | 'age' | 150
           'valid'    | 'age' | 0
       }

       @Unroll("person #field is #error using #val")
       def "test person ssn constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error      | field | val
           'blank'    | 'ssn' | ''
           'nullable' | 'ssn' | null
           'unique'   | 'ssn' | '123456789'
           'valid'    | 'ssn' | '123456788'
           'valid'    | 'ssn' | '123-45-6787'
       }

       @Unroll("person #field is #error using #val")
       def "test person username constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error                  | field      | val
           'invalid.bountyhunter' | 'username' | ''
           'nullable'             | 'username' | null
           'invalid.bountyhunter' | 'username' | 'bubua'
           'valid'                | 'username' | 'bobafet'
           'valid'                | 'username' | 'bobajunior'
       }

       @Unroll("person #field is #error using #val")
       def "test person homepage constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error      | field      | val
           'url'      | 'homePage' | getUrl(false)
           'valid'    | 'homePage' | '' //blanks work for url
           'nullable' | 'homePage' | null //null works for url (2.0.0 not anymore)
           'valid'    | 'homePage' | getUrl(true) + '/page.gsp'
           'valid'    | 'homePage' | getUrl(true)
       }

       @Unroll("person #field is #error using #val")
       def "test person gender constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error      | field    | val
           'inList'   | 'gender' | 'Unknown'
           'nullable' | 'gender' | null
           'valid'    | 'gender' | '' //blanks work for inList
           'valid'    | 'gender' | 'Male'
           'valid'    | 'gender' | 'Female'
       }

       @Unroll("person #field is #error using #val")
       def "test person credit card constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error        | field  | val
           'creditCard' | 'amex' | getCreditCard(false)
           'nullable'   | 'amex' | null
           'valid'      | 'amex' | ''
           'valid'      | 'amex' | getCreditCard(true)
       }

       @Unroll("person #field is #error using #val")
       def "test person birth date constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error      | field       | val
           'max'      | 'birthDate' | new Date() + 1
           'nullable' | 'birthDate' | null
           'valid'    | 'birthDate' | new Date() - 1
           'valid'    | 'birthDate' | new Date()
       }

       @Unroll("person #field testing #error")
       def "test person children constraints"() {
           when:
           def obj = new Person("$field": val)

           then:
           validateConstraints(obj, field, error)

           where:
           error     | field      | val
           'maxSize' | 'children' | createPerson(11)
           'minSize' | 'children' | createPerson(1)
           'valid'   | 'children' | null
           'valid'   | 'children' | createPerson(10)
           'valid'   | 'children' | createPerson(2)
       }

       private createPerson(Integer count) {
           def persons = []
           count.times {
               persons << new Person()
           }
           persons
       }
   }
```

### Conclusion

I hope that this can be a useful tool or guideline for you when you are
creating constraint tests for your domain objects. These tests are a bit
tedious to write, but using some of the techniques here makes writing them
pretty quick to create and test.

I would probably never test ALL the constraints like this, but in case you wanted to
test anything specific and guard against certain non-allowed data then you might want to consider something like this.  This
would certainly be to your benefit to do for any custom constraints you define on your objects.

### Sample Project

All files for this demonstration can be found at my [grails-spock-
constraints][1] GitHub repository.

### Getting Grails 2.0 and Spock 0.6 Working (Legacy)

We had a little bit of trouble getting grails 2.0.0.RC1 and Spock 0.6 to play
well together, but found some useful information in this [jira][2].
Add the following to the repositories section of your BuildConfig.groovy

```
mavenRepo "http://m2repo.spockframework.org/snapshots"
```

and the following to the plugins section of your BuildConfig.groovy

```
test ":spock:0.6-SNAPSHOT"
```

These will no doubt change as 2.0 becomes final and the official spock plugin
is updated.

### References

Another Spock Constraint Test: [http://meetspock.appspot.com/script/35001][27]
Spock Documentation: [http://code.google.com/p/spock/][22] 
Generic Constraint Validation: [http://www.objectpartners.com/2011/02/10/grails-testing-domain-constraints/][26] 
Grails 2.0 Docs: [http://grails.org/doc/2.0.x/][28] 
Grails 2.0 Mocking: [http://grails.org/doc/2.0.x/guide/testing.html#mockingCollaborators][29]

   [1]: https://github.com/ctoestreich/grails-spock-constraints

   [2]: http://jira.grails.org/browse/GPSPOCK-5?focusedCommentId=67107&page=co
m.atlassian.jira.plugin.system.issuetabpanels%3acomment-tabpanel#comment-67107

   [3]: https://github.com/ctoestreich/grails-spock-constraints/blob/master
/grails-app/domain/com/tgid/data/Person.groovy

   [4]: http://grails.org/doc/2.0.x/ref/Constraints/attributes.html

   [5]: http://grails.org/doc/2.0.x/ref/Constraints/blank.html

   [6]: http://grails.org/doc/2.0.x/ref/Constraints/creditCard.html

   [7]: http://grails.org/doc/2.0.x/ref/Constraints/email.html

   [8]: http://grails.org/doc/2.0.x/ref/Constraints/inList.html

   [9]: http://grails.org/doc/2.0.x/ref/Constraints/matches.html

   [10]: http://grails.org/doc/2.0.x/ref/Constraints/max.html

   [11]: http://grails.org/doc/2.0.x/ref/Constraints/maxSize.html

   [12]: http://grails.org/doc/2.0.x/ref/Constraints/min.html

   [13]: http://grails.org/doc/2.0.x/ref/Constraints/minSize.html

   [14]: http://grails.org/doc/2.0.x/ref/Constraints/notEqual.html

   [15]: http://grails.org/doc/2.0.x/ref/Constraints/nullable.html

   [16]: http://grails.org/doc/2.0.x/ref/Constraints/range.html

   [17]: http://grails.org/doc/2.0.x/ref/Constraints/scale.html

   [18]: http://grails.org/doc/2.0.x/ref/Constraints/unique.html

   [19]: http://grails.org/doc/2.0.x/ref/Constraints/url.html

   [20]: http://grails.org/doc/2.0.x/ref/Constraints/validator.html

   [21]: http://grails.org/doc/2.0.x/ref/Constraints/widget.html

   [22]: http://code.google.com/p/spock/

   [23]: http://code.google.com/p/spock/wiki/Parameterizations

   [24]: http://www.grails.org/plugin/build-test-data

   [25]: http://grails.org/doc/2.0.x/guide/testing.html#unitTesting

   [26]: http://www.objectpartners.com/2011/02/10/grails-testing-domain-
constraints/

   [27]: http://meetspock.appspot.com/script/35001

   [28]: http://grails.org/doc/2.0.x/

   [29]: http://grails.org/doc/2.0.x/guide/testing.html#mockingCollaborators

