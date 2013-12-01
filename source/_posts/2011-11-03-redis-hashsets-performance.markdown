---
author: ctoestreich
date: '2011-11-03 16:23:06'
layout: post
comments: true
slug: redis-hashsets-performance
status: publish
title: Redis Hashsets - Performance Analysis & Numerical Key Compression
wordpress_id: '161'
categories:
- Technology
tags:
- groovy
- hashset
- instagram
- jedis
- memory
- performance
- redis
---

Recently I read a pretty interesting [blog post][1] by Mike Krieger, co-founder of Instagram.  The summary of the post was they were faced with an interesting challenge in storing 300 million key value pairs for consumer to photo resolution.  They even went as far as to write an interesting test in
python and posted it on [github gist][2].

I wanted to see if I could improve a bit on his memory allocation in the redis
hash so I set out to write an algorithm that might help further reduce the
overhead.

<!-- more -->

I was using [groovyconsole][3] to run all of these scripts.

Here is a comparison of using a traditional numerical id to one of my
compressed ids:

{% gist 1337772 %}

By adding the list lookup and key transformation it does add some additional
time over using plain numeric keys.  For the reverse transformation I played
around with using both a list and a map.  I think it is pretty clear the map
is quite a bit faster in general for decoding.  I did however see the
performance of the redis operations not reflect this speed increase since I am
only doing an encode on the values in that script.  Below is the code to test
the speed differences in encoding and decoding with lists and maps.

The results I saw were consistent with the following:


    5000 encode map took 0.0286 ms each on avg and 143 ms total
    5000 decode map took 0.0496 ms each on avg and 248 ms total
    5000 encode list took 0.0186 ms each on avg and 93 ms total
    5000 decode list took 1.5004 ms each on avg and 7502 ms total

{% gist 1337848 %}

I wrote a similar test as the one provided by Mike
[https://gist.github.com/1329319 ][2]using compressed ids instead of the full
numerical ids and was able to save an additional 18% in space going from
17mb/1,000,000 keys to 14mb/1,000,000 keys.  I probably could squeeze a little
more efficiency out of the memory and redis hash if I ran both the first and
second ids through the compression methods.  For the space savings to be
really worth while I am assuming the number would need to be at least 4 digits
long as the compression would only be a byte going from 3 to 2 (33%) as
opposed to going from 4 to 2 (50%).  Five and six digit ids will both reduce
to 3 chars, seven and eight to 4, etc.  I am doing�� a 2->1 reduce�� and have to
pad the odd length keys with a 0 in effect giving you (n) and (n-1) having the
same number of bytes in memory (where n = all even length keys).

Here is the complete script I wrote to test the id space reduction hypothesis.
I would certainly welcome any feedback on additional improvements that can be
made to the code.  I think there are probably further reductions in memory to
be had.

{% gist 1337648 %}

   [1]: http://instagram-engineering.tumblr.com/post/12202313862/storing-hundreds-of-millions-of-simple-key-value-pairs (Redis Instagram)
   [2]: https://gist.github.com/1329319
   [3]: http://groovy.codehaus.org/Groovy+Console (Groovy Console)
