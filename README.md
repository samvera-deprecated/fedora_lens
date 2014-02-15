## Usage

Start Fedora:
```bash
java -jar fcrepo-webapp-4.0.0-alpha-3-jetty-console.war
```

```ruby
> $LOAD_PATH << 'lib'
> require 'fedora_lens'
> a = TestClass.find('/rest/node/to/update')
```

## To Do
* test any untested lenses
* handle attribute updates to the graph
* make .save work
* handle associations (maybe use an identity map--should that be the model that the lenses operate on?)
* add tons of missing tests

Future:
* make a "lazy" lens
* convert to more of a OO style?
