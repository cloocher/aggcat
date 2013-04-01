$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'simplecov'
SimpleCov.start

require 'webmock/test_unit'
require 'test/unit'
require 'aggcat'

def stub_delete(path)
  stub_request(:delete, Aggcat::Client::BASE_URL + path)
end

def stub_get(path)
  stub_request(:get, Aggcat::Client::BASE_URL + path)
end

def stub_post(path)
  stub_request(:post, Aggcat::Client::BASE_URL + path)
end

def stub_put(path)
  stub_request(:put, Aggcat::Client::BASE_URL + path)
end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end
