Overview
===
With this, you get full control over your Hue light bulbs. You can easily view light status, do complex controls of your lights such as pulsing a color.

Sets let you save a light configuration and then easily restore or turn it off later. You can even use this on simple browsers like a Kindle. No need to find your phone to turn on reading lights, or turn them off after you're done.

Browser requirements
-
The goal is for most of this to work under modern browsers. Any reasonably up to date version of Chrome, Firefox or Safari should work fine. IE9 and up should also work, but isn't guaranteed.

Examples
-

To view screenshots of the app in action, [click here](https://github.com/zanker/hue-controller/blob/master/examples)

Running
-
For installing Ruby on Linux or OSX, try [RVM](https://rvm.io/)
For Windows, try [Ruby Installer](http://rubyinstaller.org/). I haven't used this so no promises on how well it works.

Any Ruby 1.9.3+ version should work, JRuby 1.7.x is optimal for the background worker, but not required. You might be able to use a 1.8.7 version of Ruby, but I've not tested it.

Got Ruby installed? Next:

1) Run `gem install bundler` if you don't have bundler installed (when in doubt, you can just run it safely)

2) Run `bundle install`

3) Run `thin -R config.ru -p 9200 -e production start`, this starts the web server

4) Run `ruby worker.rb --cores 2 -e production`, this starts the background worker

5) Go to `http://localhost:9200`

6) Enjoy!

Contributing
-
Pull requests are more than welcome if you want to add new functionality or ways of extending the Hue lightbulbs.

You can find documentation on the API at: http://blog.ef.net/2012/11/02/philips-hue-api.html

Disclaimer
-
All of this uses the standard APIs, but it does give you more granular access to the API than the official apps do.

While you shouldn't be able to break your lights by using this, if you set your lights to pulse every 100ms for 6 hours and they break, it's your own fault.