require 'active_model'
require 'fedora_lens/core'

module FedoraLens
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include FedoraLens::Core
  end
end

require 'fedora_lens/lenses'
