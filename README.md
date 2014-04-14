## Usage

Download and extract Fedora 4:
```bash
rake jetty:download
rake jetty:unzip
```

Start Fedora:
```bash
rake jetty:start
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
