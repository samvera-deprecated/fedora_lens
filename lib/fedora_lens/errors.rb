module FedoraLens
  # generic exception class
  class FedoraLensError < StandardError; end
  # raised when a resource can't be saved
  class RecordNotSaved < FedoraLensError; end
end
