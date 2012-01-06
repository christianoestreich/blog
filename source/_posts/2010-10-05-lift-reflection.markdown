---
author: ctoestreich
date: '2010-10-05 13:54:10'
layout: post
comments: true
slug: lift-reflection
status: publish
title: Lift and Reflection
wordpress_id: '6'
categories:
- Technology
tags:
- Code
- framework
- Java
- Lift
- Sample
- Scala
---

So here is some really dumb Scala and Lift code that does a bit of validation.
The only thing I really wanted to do when I wrote this code was to see how I
could use reflection and a Map to drive validation since our main project does
something similar (albeit more well configured) in Java.  There is some other
code mixed in when I was playing with the dispatch stuff that isn't currently
hooked up.

The reflection and adding the error class to the map is done in this method.
Note that the setAccessible(true) was the key for me to get this working as it
was puking all over the place with out that line in there.


    def validateFields = {

     requiredFields.foreach(field => {

     var f = getClass.getDeclaredField(field)

     if (f != null) {

     f.setAccessible(true)

     if (f.get(this) == "") {

     S.error(field + "Field", "You need to provide a " + field)

     fieldClass += field -> "error"

     } else {

     fieldClass -= field

     }

     }

     })

     }

Here is the full code for reference.

Xhtml Code:


    <lift:surround with="default" at="content"
xmlns:lift="http://www.w3.org/1999/xhtml"
xmlns:hello="http://www.w3.org/1999/xhtml"
xmlns:v="http://java.sun.com/xml/ns/j2ee">

     <lift:RentingForm.rent form="POST" id="confirmform">

     <fieldset>

     <legend>Video Hire Details</legend>

     <div>

     <label for="name"><u>N</u>ame:<span>*</span></label>

     <v:name/>&nbsp;<lift:Msg id="nameField" errorClass="errortext" />

     </div>

     <div>

     <label for="address">Address:<span>*</span></label>

     <v:textbox name="addressVO" property="address1" />

     </div>

     <div>

     <label for="email">Email:<span>*</span></label>

     <v:email/>&nbsp;<lift:Msg id="emailField" errorClass="errortext" />

     </div>

     <div>

     <label for="movietype">Movie Type:<span>*</span></label>

     <v:movie/>

     </div>

     <div>

     <label for="dateOfHire">Date of Hire:<span>*</span></label>

     <v:date/>

     <span id="notify"> DD/MM/YYYY </span>

     </div>

     <div>

     <label for="numberOfDays">Number Of Days:<span>*</span></label>

     <v:numberOfDays/>

     </div>

     <div>

     <fieldset>

     <legend><span> Discount Rate:<span>*</span> </span></legend>

     <div>

     <v:regular/><label> <v:rtxt1/> </label>

     <v:new/> <label> <v:rtxt2/> </label>

     </div>

     </fieldset>

     </div>

     <div id="btn">

     <v:submit/>

     </div>

     </fieldset>

     </lift:RentingForm.rent>

    </lift:surround>

Snippet Code:


    package demo.helloworld.snippet

    import net.liftweb.http._

    import js.jquery.JqJsCmds.DisplayMessage

    import js.JsCmds.SetHtml

    import S._

    import SHtml._

    import net.liftweb.util._

    import Helpers._

    import scala.xml._

    import net.liftweb.http.js._

    import net.liftweb.common.{Empty, Logger, Full}

    import java.lang.String

    /**

     */

    class RentingForm extends StatefulSnippet {

     var dispatch: DispatchIt = {

     case "rent" => rentForm _

     }

     var (name, address, email, movieType, dateOfHire, numberOfDays, discount)
= ("", "", "", "", "", "", "")

     var movieMap = Seq("" -> "Select Movie Type", "Sci-fi" -> "Sci-fi",
"Horror" -> "Horror", "Comedy" -> "Comedy", "Suspense" -> "Suspense",
"Romance" -> "Romance")

     var discountMap = Map("Regular Customer" -> "Regular Customer", "New
Customer" -> "New Customer")

     val discounts = radio(discountMap.keys.toList, Full(discount), discount =
_, "class" -> "required")

     var fieldClass = Map.empty[String, String]

     var requiredFields = List("name", "email")

     def bindFormFields(xhtml: NodeSeq, discounts: SHtml.ChoiceHolder[String],
submitLabel: String): NodeSeq = {

     val requiredClass: String = "required"

     bind("v", xhtml,

     "name" -> text(name, name = _, "class" -> fieldClass.getOrElse("name",
requiredClass), "accesskey" -> "N"),

     "address" -> textarea(address, address = _, "rows" -> "5", "class" ->
fieldClass.getOrElse("address", requiredClass)),

     "email" -> text(email, email = _, "class" ->
{fieldClass.getOrElse("email", requiredClass) + " email"}),

     "movie" -> select(movieMap, Empty, movieType = _, "class" ->
fieldClass.getOrElse("movieMap", requiredClass)),

     "date" -> text(dateOfHire, dateOfHire = _, "class" ->
{fieldClass.getOrElse("dateOfHire", requiredClass) + " date"}, "id" ->
"datePicker"),

     "numberOfDays" -> text(numberOfDays, numberOfDays = _, "class" ->
fieldClass.getOrElse("numberOfDays", requiredClass), "onkeypress" ->
"checkNumerics(event)"),

     "regular" -> discounts(0),

     "new" -> discounts(1),

     "rtxt1" -> (discountMap.getOrElse("Regular Customer", "No Key!")),

     "rtxt2" -> (discountMap.getOrElse("New Customer", "No Key!")),

     "submit" -> submit(submitLabel, () => {}, "id" -> "submit"))

     }

     def rentForm(xhtml: NodeSeq): NodeSeq = {

     dispatch = {

     case name if name != "" => showDetails _

     }

     bindFormFields(xhtml, discounts, "Confirm")

     }

     def validateFields = {

     requiredFields.foreach(field => {

     var f = getClass.getDeclaredField(field)

     if (f != null) {

     f.setAccessible(true)

     if (f.get(this) == "") {

     S.error(field + "Field", "You need to provide a " + field)

     fieldClass += field -> "error"

     } else {

     fieldClass -= field

     }

     }

     })

     }

     def showDetails(xhtml: NodeSeq): NodeSeq = {

     validateFields

     bindFormFields(xhtml, discounts, "Edit")

     }

     def thankYou(xhtml: NodeSeq): NodeSeq = {

     Log.info(name, address, email, movieType, dateOfHire, numberOfDays,
discount)

     bind("v", xhtml,

     "name" -> (name))

     }

    }

