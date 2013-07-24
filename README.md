### Napkin

Napkin is an interaction platform for HTTP enabled devices.  The Napkin server offers a REST API with predefined services for storing and retrieving configuration information and collecting time series data from client devices.  A plug-in model provides extensibility in HTTP handling and periodic processing of stored data.  The Napkin server runs on [JRuby](http://jruby.org/) [Sinatra](http://www.sinatrarb.com/) and the [Neo4j](http://www.neo4j.org/) graph database.

![vitals](https://github.com/cjdaly/napkin/wiki/images/pcduino-vitals-chart.jpg)

Napkin began when I discovered small, inexpensive but HTTP capable (ARM-based, "[arduino](http://en.wikipedia.org/wiki/Arduino)-ish") computers like the [Netduino Plus](http://www.netduino.com/), [.Net Gadgeteer](http://www.ghielectronics.com/catalog/category/274), [BeagleBone](http://beagleboard.org/bone), [Raspberry Pi](http://www.raspberrypi.org/), etc. and parts websites like [Sparkfun](https://www.sparkfun.com/), [Adafruit](http://adafruit.com/), etc. I built systems based on these devices to monitor and control the environment around my home (temperature, humidity, light levels, sounds, etc.) and needed a way to collect, store and process all of the data.

![chatter](https://github.com/cjdaly/napkin/wiki/images/cerbee1-humidity.jpg)

#### Details

The Napkin server can run in (at least) these configurations:
* [Ubuntu (x86) 12.04](https://github.com/cjdaly/napkin/wiki/Server-on-Ubuntu-x86)
* [pcDuino (running Ubuntu 12.04)](https://github.com/cjdaly/napkin/wiki/Server-on-pcduino)
* [BeagleBone Black (running Ubuntu 13.04)](https://github.com/cjdaly/napkin/wiki/Server-on-BeagleBone-black)
* [Cubieboard (running Ubuntu 13.01)](https://github.com/cjdaly/napkin/wiki/Server-on-Cubieboard)

Napkin clients use REST-style HTTP communication to access services such as:
* [config](https://github.com/cjdaly/napkin/wiki/Plugin-config) - allows devices to store and retrieve hierarchical configuration data
* [chatter](https://github.com/cjdaly/napkin/wiki/Plugin-chatter) - allows devices to post time series data
* [vitals](https://github.com/cjdaly/napkin/wiki/Plugin-vitals) - periodically stores data about the state of the napkin server
* new services can be implemented as plugins

Napkin client examples:
* .Net Gadgeteer (C#)
  * [cerbee1](https://github.com/cjdaly/napkin/wiki/Gadgeteer-client-cerbee1)
  * [cerb1](https://github.com/cjdaly/napkin/wiki/Gadgeteer-client-cerb1)
  * [cerb2](https://github.com/cjdaly/napkin/wiki/Gadgeteer-client-cerb2)
* BeagleBone (Python)
  * [bone1](https://github.com/cjdaly/napkin/wiki/Beaglebone-client-bone1)
