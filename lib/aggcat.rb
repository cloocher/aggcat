require 'aggcat/version'
require 'aggcat/configurable'
require 'aggcat/base'
require 'aggcat/client'

module Aggcat
  class << self
    include Aggcat::Configurable

    def client
      @client ||= Aggcat::Client.new(options)
    end

    private

    def method_missing(method_name, *args, &block)
      return super unless client.respond_to?(method_name)
      client.send(method_name, *args, &block)
    end

  end
end
