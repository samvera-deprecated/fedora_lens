require 'ldp'
require 'active_support/core_ext/object'
module Ldp
  module Response
    def self.resource? raw_resp
      # workaround for a bug in fedora-commons, see https://github.com/cbeer/ldp/issues/1
      links(raw_resp).fetch("type", []).to_set.intersection([Ldp.resource.to_s, "http://www.w3.org/ns/ldp/Resource"]).present?
    end
  end

  class Resource
    def create
      # create seems to not be working in ldp, but it's not entirely clear how it should work
      # for example, :new? calls :get, which will raise an error when an object doesn't exist,
      # this means it is impossible to create anything.
      # raise "" if new?
      resp = client.post '/rest', graph.dump(:ttl) do |req|
        # req.headers['Slug'] = subject
      end

      @subject = resp.headers['Location']
      @subject_uri = nil
    end
  end
end
