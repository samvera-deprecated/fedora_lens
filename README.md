== Usage

```ruby
> load './fedora_projection.rb'
> a = TestClass.find('/rest/node/to/update')
```
== To Do
* fix broken tests
* handle attribute updates
* handle associations (maybe use an identity map--should that be the model that the lenses operate on?)
* add tons of missing tests
