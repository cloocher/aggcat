require 'aggcat/version'
require 'aggcat/configurable'
require 'aggcat/base'
require 'aggcat/institutions_sax_parser'
require 'aggcat/client'

module Aggcat
  class << self
    include Aggcat::Configurable

    def scope(customer_id)
      if !defined?(@customer_id) || @customer_id != customer_id
        @customer_id = customer_id
        @client = Aggcat::Client.new(options.merge({customer_id: customer_id}))
      end
      @client
    end

    def client
      raise ArgumentError.new('set the client scope first by calling Aggcat.scope(customer_id)') unless defined?(@customer_id)
      @client
    end

    private

    def method_missing(method_name, *args, &block)
      return super unless client.respond_to?(method_name)
      client.send(method_name, *args, &block)
    end

  end
end
