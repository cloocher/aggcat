module Aggcat
  module Configurable

    attr_writer :issuer_id, :consumer_key, :consumer_secret, :certificate_path, :customer_id, :open_timeout, :read_timeout, :verbose

    KEYS = [:issuer_id, :consumer_key, :consumer_secret, :certificate_path, :customer_id, :open_timeout, :read_timeout, :verbose]

    def configure
      yield self
      self
    end

    private

    def options
      Aggcat::Configurable::KEYS.inject({}) { |hash, key| hash[key] = instance_variable_get(:"@#{key}"); hash }
    end

  end
end
