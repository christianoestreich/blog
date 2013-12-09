---
author: ctoestreich
date: '2013-12-01 10:00:00'
layout: post
comments: true
slug: knockout-validation-rules-engine
status: publish
title: Knockout Validation Rules Engine
categories:
- JavaScript
tags:
- javscript
- knockout
- validation
- rule engine
- rules
- model
---

We have recently begun working with [Knockout.js][1] and needed a way to run validation on the models.  We found the amazing plugin [Knockout.Validation][2].  This plugin did an awesome job and we were able to port over all our jQuery Validation rules fairly easy.  As I was working with the plugin, my model grew and additional models were being created it became tedious having to append every rule to every model property and not remember which rules applied to which model properties across model contexts.  Thus the concept of the [Knockout Validation Rule Engine][3] was born.

<!-- more -->

## Getting Started

Download the latest [knockout-rule-engine][4] file.

Define a rule set that uses the parent key as the name of the model property you want to map to.  If you wanted to set an email rule for a model with a property of userEmail, you would provide the following rule set.

``` javascript
define(['knockout', 'knockout-rule-engine'], function (ko, RuleEngine) {
    var ruleSet = {
        userEmail: { email: true, required: true }
    };

    var ruleEngine = new RuleEngine(ruleSet);

    var model = {
        userEmail: ko.observable('')
    };

    ruleEngine.apply(model);

    ko.applyBindings(model, $('html')[0]);
});
```

This would be equivalent to the following code.

``` javascript
define(['knockout'], function (ko) {
    var model = {
        userEmail: ko.observable('').extend({email: true, required: true});
    };

    ko.applyBindings(model, $('html')[0]);
});
```

## Override Knockout Validation Options

You can pass in the options you want to use for the knockout.validation library as the optional second param in the constructor.  For example if you wanted to disable the validation plugin from auto inserting messages you would use the following.

``` javascript
define(['knockout', 'knockout-rule-engine'], function (ko, RuleEngine) {
    var ruleSet = {
        userEmail: { email: true, required: true }
    };

    var ruleEngine = new RuleEngine(ruleSet, {insertMessages: false});

    var model = {
        userEmail: ko.observable('')
    };

    ruleEngine.apply(model);

    ko.applyBindings(model, $('html')[0]);
});
```

See [Configuration Options][5] for details on all the Knockout.Validation options.

## Deep Mapping

By default the plugin will attempt to recurse your model tree and look at all properties and try and match rules against them.  If you only want to apply rules to the first level object simply pass a flag with deep set to false in the options param.

``` javascript
define(["knockout", "knockout-rule-engine", "rules/address/rules"], function (ko, RuleEngine, personRules) {
    var ruleEngine = new RuleEngine(personRules, {deep: false});
    ... do work ...
});
```

## Reusing rules

If you store your rules in a common directory and include them via require into your models you will ensure you have a common experience across your site.  See [main.js][6] for more detailed examples.

``` javascript
define(['filters/filters'], function (filters) {
    return {
        address1: {
            required: true,
            noSpecialChars: true,
            filter: [filters.noSpecialChars, filters.ltrim]
        },
        address2: {
            noSpecialChars: true,
            filter: [filters.noSpecialChars, filters.ltrim]
        },
        city: {
            required: true,
            noSpecialChars: true,
            filter: [filters.noSpecialChars, filters.ltrim]
        },
        state: {
            validSelectValue: {
                message: 'Please select a state.'
            }
        },
        zipCode: {
            required: true,
            validDigitLength: {
                params: 5,
                message: 'Please enter a valid zip code (XXXXX).'
            },
            filter: filters.onlyDigits
        },
        phone: {
            required: true,
            pattern: {
                message: 'Invalid phone number. (XXX-XXX-XXXX)',
                params: /^\D?(\d{3})\D?\D?(\d{3})\D?(\d{4})$/
            }
        }
    };
});
```

Then you can include this module named rules/address/rules.js into any model that has address or nested address properties that match the keys above (address1, address2, etc).

``` javascript

define(["knockout", "knockout-rule-engine", "rules/address/rules"], function (ko, RuleEngine, personRules) {

    // set deep to false if you do not want to traverse child properties on the model
    // var ruleEngine = new RuleEngine(personRules, {deep: false});
    var ruleEngine = new RuleEngine(personRules);

    var PhoneModel = function () {
        return {
            phone: ko.observable('')
        };
    };

    var AddressModel = function () {
        return {
            address1: ko.observable(''),
            address2: ko.observable(''),
            city: ko.observable(''),
            state: ko.observable(''),
            zipCode: ko.observable(''),
            phone: new PhoneModel()
        };
    };

    var personModel = {
        firstName: ko.observable(''),
        lastName: ko.observable(''),
        middleName: ko.observable(''),
        address: new AddressModel()
    };

    // example of wiring a field at apply time
    ruleEngine.apply(personModel);

    ko.applyBindings(personModel, $('html')[0]);
});
```

## Adding Validation Rules At Runtime

If you have already instantiated the RuleEngine and need to add a rule later at runtime you can do so via the addRule method.

``` javascript
ruleEngine.addRule('nameNotTom', {
    validator: function (val) {
        return val !== 'Tom';
    },
    message: 'Your name can not be Tom!'
});
```

## Adding Rule Sets At Runtime

You can add additional rule sets to your model via the following code.

``` javascript
ruleEngine.addRuleSet('firstName', { nameNotTom: true });
```

This is extremely handy if you make use of the onlyIf clause in knockout.validation that depends on other model data.  You can add these rules later and not have to inject your model into your rule definitions and keep the them clean.

``` javascript

var model = {
    firstName: ko.observable('');
    foo: ko.observable('');
}

//do other work

ruleEngine.addRuleSet('firstName', {
    nameNotTom: true,
    onlyIf: function(){
        return model.foo() === 'bar';
    }
});
```

## Using The Filter Extender

It is pretty common that you must also filter the input of data on the knockout model via a form.  This is an example filter extender that can be used in conjunction with the rules definitions as in the above example.

``` javascript
ko.extenders.filter = function (target, filter) {
    var writeFilter = function (newValue) {
        var newValueAdjusted = (typeof filter === 'function') ? filter(newValue) : newValue;
        if ($.isArray(filter)) {
            $.each(filter, function (o) {
                if (typeof o === 'function') {
                    newValueAdjusted = o(newValueAdjusted);
                }
            });
        }
        var currentValue = target();
        if (newValueAdjusted !== currentValue) {
            target(newValueAdjusted);
        } else {
            if (newValue !== currentValue) {
                target.notifySubscribers(newValueAdjusted);
            }
        }
    };

    var result = ko.computed({
        read: target,
        write: writeFilter
    }).extend({ notify: 'always', throttle: 1 });

    result(target());

    target.subscribe(writeFilter);

    return target;
};
```

Global filters can be setup to be reused via something similar to the following.  See [Filters][7] for more information.

``` javascript
define(function () {
    return {
        ltrim: function (value) {
            return (typeof value === 'string') ? value.replace(/^\s+/, "") : value;
        },

        onlyDigits: function (value) {
            return (typeof value === 'string') ? value.replace(/[^0-9]/g, '') : value;
        },

        onlyAlpha: function (value) {
            return (typeof value === 'string') ? value.replace(/[^A-Za-z _\-']/g, '') : value;
        },

        noSpecialChars: function (value) {
            return (typeof value === 'string') ? value.replace(/[^\/A-Za-z0-9 '\.,#\-]*$/g, '') : value;
        }
    };
});
```

## Without RequireJS

You can still include the plugin without require js.  The plugin adds a global ko.RuleEngine singleton that you can instantiate.  This is done in the [Inline Tests][8].

``` html
<script src="../app/js/knockout-rule-engine.js"></script>
<script>
    var ruleSet = {firstName: {required: true, validName: true, filter: function(){}}};
    var ruleEngine = new ko.RuleEngine(ruleSet);
    ...
</script>
```

[1]: http://knockoutjs.com/ (Knockout JS)
[2]: https://github.com/Knockout-Contrib/Knockout-Validation (Knockout Validation)
[3]: https://github.com/ctoestreich/knockout-validation-rule-engine (Knockout Validation Rule Engine)
[4]: https://github.com/ctoestreich/knockout-validation-rule-engine/tree/master/build (Knockout Validation Rule Engine Dist)
[5]: https://github.com/Knockout-Contrib/Knockout-Validation/wiki/Configuration (Knockout Validation Configuration)
[6]: https://github.com/ctoestreich/knockout-validation-rule-engine/blob/master/app/js/main.js (Knockout Validation Rule Engine Main.js)
[7]: https://github.com/ctoestreich/knockout-validation-rule-engine/blob/master/app/js/filters/filters.js (Knockout Validation Rule Engine Filters)
[8]: https://github.com/ctoestreich/knockout-validation-rule-engine/blob/master/test/inline.html (Knockout Validation Rule Engine Tests)