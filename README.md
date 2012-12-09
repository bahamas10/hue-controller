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
You will need ruby installed (this is all tested against ruby-1.9.3-p327, but any ruby-1.9.3 should work.

If you don't have bundler installed yet, you will need to do `gem install bundler` before running `bundle install`.

Run `bundle install` in the directory to install the necessary gems, and then just `thin -R config.ru -p 9200 -e production start` and that's it! Navigate to localhost:9200 and enjoy

Contributing
-
Pull requests are more than welcome if you want to add new functionality or ways of extending the Hue lightbulbs.

You can find documentation on the API at: http://blog.ef.net/2012/11/02/philips-hue-api.html
