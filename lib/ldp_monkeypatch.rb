require 'ldp'
require 'active_support/core_ext/object'
module Ldp
  module Response
    def self.resource? raw_resp
      links(raw_resp).fetch("type", []).to_set.intersection([Ldp.resource.to_s, "http://www.w3.org/ns/ldp/Resource"]).present?
    end
  end

  class Resource
    def create
      # raise "" if new?
      resp = client.post '/rest', graph.dump(:ttl) do |req|
        # req.headers['Slug'] = subject
      end

      @subject = resp.headers['Location']
      @subject_uri = nil
    end
  end
end
