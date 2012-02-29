The `source_map` gem provides an API for parsing, and an API for generating source maps in ruby.

Source maps?
============

Source maps are Javascripts equivalent of the C `#line` functionality. They allow you to
combine multiple javascript files into one, or minify your javascript yet still debug it
as though you had done neither of these things.

To do this you attach a SourceMap to a given generated javascript file, which contains a
list of mappings between points in the generated file and points in the original files.

This gem helps you create or parse those mapping files according to the
<a href="https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit">SourceMaps version 3</a> spec.


Installing
==========

    gem install source_map


Generating a source map
=======================

Let's say you have a directory full of javascript files, but you'd prefer them to be
lumped together to avoid latency.

```ruby

    require 'source_map'

    file = File.open("public/combined.js", "w")

    map = SourceMap.new(:generated_output => file,
                        :file => "combined.js",
                        :source_root => "http://localhost:3000/")

    Dir["js/*"].each do |filename|
      map.add_generated File.read(filename), :source => filename.sub('public/', '')
    end

    map.save("public/combined.js.map")
```

This snippet will create two files for you. `combined.js` which contains all your
javascripts lumped together, and `combined.js.map` which explains which bits of the file
came from where.

(Using the :generated_output feature to automatically write the combined.js file is
totally optional if you don't need that feature).

If you want more flexibility, there's an alternative API that requires you to do a bit
more manual work:

```ruby

    require 'source_map'

    map = SourceMap.new(:file => 'combined.js',
                        :source_root => 'http://localhost:3000/')

    my_crazy_process.each_fragment do |x|
      map.add_mapping(
        :generated_line => x.generated_line,
        :generated_col => 0,
        :source_line => x.source_line,
        :source_col => 0
        :source => "foo.js"
      )
    end
```

If you use this API, you'll probably need to read
<a href="https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit">the Spec</a>.


Using a source map
==================

You'll need Chrome version 19 or greater. Go to the developer console, and click on the
settings cog; and then click "Enable source maps".

Now, ensure that when you load `combined.js`, you also need to send an extra HTTP header:
`X-SourceMap: /combined.js.map`.

Finally ensure that eah of the source files can be reached by appending the value you
provided to `:source`, to the value you provided for `:source_root`.


NOTE: in theory you can (instead of using the `X-SourceMap` header) add a comment to the
end of your generated file (`combined.js`) which looks like:

    //@ sourceMappingURL=/combined.js.map

however I haven't had much luck with this.

NOTE2: In theory you could use the Closure Inspector Firefox extension instead of Chrome
19, but I couldn't get it to work either (even when I tried in Firefox 3.6 which is the
most recent version it supports).

Sorry this is a bit rubbish :(.


Future work
===========

* An API to look up the position in the original source from a given position in the generated
  file.

* I'd like to write a tool that given two source maps, composes them. Once that is done,
  then we could pipe `combined.js` through a minifier which generates a `combined.js.min`
  and a `combined.js.min.map`. And then we could combine `combined.js.map` and
  `combined.js.min.map` so that we can use our concatenated and minified code with the
  debugger with impunity. (The only such minifier that exists at the moment is the closure
  compier, maybe that will change...)

* Supporting the index-file mode of SourceMaps (an alternative to the previous suggestion
  in some circumstances)


Meta-Fu
=======

This stuff is all available under the MIT license, bug-reports and feature suggestions
welcome.


Further Reading
===============

This stuff is quite new so there's not exactly a lot of information about it:

* <a href="https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit">the Version 3 Spec</a>.
* <a href="https://github.com/mozilla/source-map/">A javascript implementation (which helped this one)</a>
* <a href="http://peter.sh/2012/01/css-selector-profiler-source-mapping-and-software-rendering/">Announcement of feature being released into Chrome.</a>
* <a href="https://developers.google.com/closure/compiler/docs/inspector">The closure inspector was the first tool to allow reading of source maps, now seems a bit broken</a>
* <a href="https://wiki.mozilla.org/DevTools/Features/SourceMap">Implementation status at Mozilla</a>
