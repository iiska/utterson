Simple utility to traverse directory of html files and check links in them.

[![Gem Version](https://badge.fury.io/rb/utterson.png)](http://badge.fury.io/rb/utterson)
[![Tests](https://github.com/iiska/utterson/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/iiska/utterson/actions/workflows/ci.yml)


## Getting started

Install the gem:

    $ gem install utterson

Check you statically generated files:

    $ utterson my-jekyll-blog/_site

Or some subdirectory

    $ utterson --root my-jekyll-blog/_site my-jekyll-blog/_site/archives/2012


## Why the name?

I developed this to help me checking links in my Jekyll powered blog
and Mr. Utterson is the main character in the [Strange Case of Dr
Jekyll and Mr
Hyde](https://en.wikipedia.org/wiki/Strange_Case_of_Dr_Jekyll_and_Mr_Hyde).


## License

Released under the [MIT License](http://www.opensource.org/licenses/MIT)
