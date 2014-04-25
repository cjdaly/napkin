Napkin is a collection of Internet of Things (IoT) projects.

### Napkin Reference Things

* [Radxa Rock](https://github.com/cjdaly/napkin/wiki/Server-on-Radxa-Rock)
* [pcDuino](https://github.com/cjdaly/napkin/wiki/Server-on-pcduino)
* [Cubieboard2](https://github.com/cjdaly/napkin/wiki/Server-on-Cubieboard-A20) (out-of-date: [Cubieboard1](https://github.com/cjdaly/napkin/wiki/Server-on-Cubieboard))
* [BeagleBone Black](https://github.com/cjdaly/napkin/wiki/Server-on-BeagleBone-black)
  * [with Fez Cerbuino Bee](https://github.com/cjdaly/napkin/wiki/Server-with-serial-client-bone2-cerbee1)
  * [with Fez Cerberus](https://github.com/cjdaly/napkin/wiki/Server-with-serial-client-bone3-cerb3)
* [x86 architecture virtual machine](https://github.com/cjdaly/napkin/wiki/Server-on-Ubuntu-x86)

### Napkin Server

The Napkin server runs on [JRuby](http://jruby.org/) [Sinatra](http://www.sinatrarb.com/) and the [Neo4j](http://www.neo4j.org/) graph database.  Core plugins handle storing and retrieving configuration information and collecting time series data from client IoT devices.  New plugins can be added to customize HTTP handling, for periodic processing of stored data, and to utilize system-specific resources.

### Napkin Client API

Napkin clients use REST-style HTTP communication to access services such as:
* [config](https://github.com/cjdaly/napkin/wiki/Plugin-config) - allows devices to store and retrieve hierarchical configuration data
* [chatter](https://github.com/cjdaly/napkin/wiki/Plugin-chatter) - allows devices to post time series data
* [vitals](https://github.com/cjdaly/napkin/wiki/Plugin-vitals) - periodically stores data about the state of the napkin server
* new services can be implemented as plugins
