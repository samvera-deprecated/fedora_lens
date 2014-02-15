require 'ldp'
module Ldp
  module Response
    def self.resource? raw_resp
      links(raw_resp).fetch("type", []).to_set.intersection([Ldp.resource.to_s, "http://www.w3.org/ns/ldp/Resource"]).present?
    end
  end
end
