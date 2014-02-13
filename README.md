## Usage

Start Fedora:
```bash
java -jar fcrepo-webapp-4.0.0-alpha-3-jetty-console.war
```

```ruby
> load './fedora_lens.rb'
> a = TestClass.find('/rest/node/to/update')
```

## To Do
* add tests for lenses
* fix broken tests
* handle attribute updates
* handle associations (maybe use an identity map--should that be the model that the lenses operate on?)
* add tons of missing tests

Future:
* make a "lazy" lens
* convert to more of a OO style?
