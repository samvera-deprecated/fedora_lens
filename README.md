## Usage

Download Fedora 4:
```bash
rake fedora:download
```

Start Fedora:
```bash
rake fedora:start
```

```ruby
# bundle console
require 'test_class'
b = TestClass.new(title: "New resource")
b.uri
b.save
b.id
a = TestClass.find(b.id)
a.attributes
a.primary_id = "some id"
a.save
b.reload
b.attributes
c = TestClass.create(title: "created resource")
c.id
```

## To Do
* test any untested lenses
* convert to more of a OO style using Object.new for the lenses and implement == so we can compact the paths into a tree
* get Lenses.zip working so we don't traverse the depth of the tree of paths for every attribute
* handle associations (maybe use an identity map--should that be the model that the lenses operate on?)
* add tons of missing tests

Future:
* make a "lazy" lens
