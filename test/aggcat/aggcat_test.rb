require 'test_helper'

class AggcatTest < Test::Unit::TestCase
  def setup
    Aggcat.configure do |config|
      config.issuer_id = 'issuer_id'
      config.consumer_key = 'consumer_key'
      config.consumer_secret = 'consumer_secret'
      config.certificate_path = "#{fixture_path}/cert.key"
    end
  end

  def test_configure
    configurable = Aggcat.configure do |config|
      config.issuer_id = 'issuer_id'
      config.consumer_key = 'consumer_key'
      config.consumer_secret = 'consumer_secret'
      config.certificate_path = "#{fixture_path}/cert.key"
      config.open_timeout = 5
      config.read_timeout = 30
    end
    assert_equal 'issuer_id', configurable.instance_variable_get(:'@issuer_id')
    assert_equal 'consumer_key', configurable.instance_variable_get(:'@consumer_key')
    assert_equal 'consumer_secret', configurable.instance_variable_get(:'@consumer_secret')
    assert_equal "#{fixture_path}/cert.key", configurable.instance_variable_get(:'@certificate_path')
    assert_equal 5, configurable.instance_variable_get(:'@open_timeout')
    assert_equal 30, configurable.instance_variable_get(:'@read_timeout')
  end

  def test_configure_certificate_by_value
    cert_value = File.read("#{fixture_path}/cert.key")
    configurable = Aggcat.configure do |config|
      config.issuer_id = 'issuer_id'
      config.consumer_key = 'consumer_key'
      config.consumer_secret = 'consumer_secret'
      config.certificate_value = cert_value
      config.open_timeout = 5
      config.read_timeout = 30
    end
    assert_equal 'issuer_id', configurable.instance_variable_get(:'@issuer_id')
    assert_equal 'consumer_key', configurable.instance_variable_get(:'@consumer_key')
    assert_equal 'consumer_secret', configurable.instance_variable_get(:'@consumer_secret')
    assert_equal cert_value, configurable.instance_variable_get(:'@certificate_value')
    assert_equal 5, configurable.instance_variable_get(:'@open_timeout')
    assert_equal 30, configurable.instance_variable_get(:'@read_timeout')
  end

  def test_scope
    client1 = Aggcat.scope('1')
    assert_true client1.is_a?(Aggcat::Client)
    assert_equal 'issuer_id', client1.instance_variable_get(:'@issuer_id')
    assert_equal 'consumer_key', client1.instance_variable_get(:'@consumer_key')
    assert_equal 'consumer_secret', client1.instance_variable_get(:'@consumer_secret')
    assert_equal "#{fixture_path}/cert.key", client1.instance_variable_get(:'@certificate_path')
    assert_equal '1', client1.instance_variable_get(:'@customer_id')
    client2 = Aggcat.client
    assert_equal client1, client2
    client3 = Aggcat.scope('1')
    assert_equal client1, client3
    client4 = Aggcat.scope('2')
    assert_not_equal client1, client4
  end

  def test_no_scope
    exception = assert_raise(ArgumentError) { Aggcat.scope(nil) }
    assert_equal('customer_id is required for scoping all requests', exception.message)
  end

  def test_client_api
    stub_request(:post, Aggcat::Base::SAML_URL).to_return(:status => 200, :body => fixture('oauth_token.txt'))
    Aggcat.scope('1')
    stub_get('/institutions').to_return(:body => fixture('institutions.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = Aggcat.institutions
    assert_equal '100000', response[:result][:institutions][:institution][0][:institution_id]
  end
end
