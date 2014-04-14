require 'ldp'
module Ldp

  class Resource
    def create
      # create seems to not be working in ldp, but it's not entirely clear how it should work
      # for example, :new? calls :get, which will raise an error when an object doesn't exist,
      # this means it is impossible to create anything.
      # raise "" if new?
      # puts "MONKEY patch create #{client.inspect}"
      # puts "Graph #{graph.dump(:ttl)}"
      resp = client.post '/fedora/rest', graph.dump(:ttl) do |req|
        # req.headers['Slug'] = subject
      end

      # puts "Heards #{resp.headers.inspect}"
      @subject = resp.headers['Location']
      # puts "Loc #{@subject.inspect}"
      @subject_uri = nil
    end
  end
end
