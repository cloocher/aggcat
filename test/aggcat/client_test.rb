require 'test_helper'

class ClientTest < Test::Unit::TestCase
  def setup
    stub_request(:post, Aggcat::Base::SAML_URL).to_return(:status => 200, :body => fixture('oauth_token.txt'))
    @client = Aggcat::Client.new(
        {
            issuer_id: 'issuer_id',
            consumer_key: 'consumer_key',
            consumer_secret: 'consumer_secret',
            certificate_path: "#{fixture_path}/cert.key",
            customer_id: 'default'
        }
    )
  end

  def test_arguments
    assert_equal 'issuer_id', @client.instance_variable_get(:'@issuer_id')
    assert_equal 'consumer_key', @client.instance_variable_get(:'@consumer_key')
    assert_equal 'consumer_secret', @client.instance_variable_get(:'@consumer_secret')
    assert_equal "#{fixture_path}/cert.key", @client.instance_variable_get(:'@certificate_path')
    assert_equal 'default', @client.instance_variable_get(:'@customer_id')
    assert_equal false, @client.instance_variable_get(:'@verbose')
  end

  def test_institutions
    stub_get('/institutions').to_return(:body => fixture('institutions.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.institutions
    assert_equal response[:result][:institutions][:institution][0][:institution_id].to_i, 100000
  end

  def test_institution
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.institution(institution_id)
    assert_equal institution_id, response[:result][:institution_detail][:institution_id]
  end

  def test_institution_with_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.institution(arg) }
      assert_equal('institution_id is required', exception.message)
    end
  end

  def test_discover_and_add_accounts
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_post("/institutions/#{institution_id}/logins").to_return(:body => fixture('account.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.discover_and_add_accounts(institution_id, 'username', 'password')
    assert_equal institution_id, response[:result][:account_list][:banking_account][:institution_id]
    assert_equal '000000000001', response[:result][:account_list][:banking_account][:account_id]
  end

  def test_discover_and_add_accounts_inactive_fields
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution_hidden_fields.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_post("/institutions/#{institution_id}/logins").to_return(:body => fixture('account.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.discover_and_add_accounts(institution_id, 'username', 'password')
    assert_equal institution_id, response[:result][:account_list][:banking_account][:institution_id]
    assert_equal '000000000001', response[:result][:account_list][:banking_account][:account_id]
  end

  def test_discover_and_add_accounts_with_challenge
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_post("/institutions/#{institution_id}/logins").to_return(:code => 401, :body => fixture('account.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.discover_and_add_accounts(institution_id, 'username', 'password')
    assert_equal institution_id, response[:result][:account_list][:banking_account][:institution_id]
    assert_equal '000000000001', response[:result][:account_list][:banking_account][:account_id]
  end

  def test_discover_and_add_accounts_multiple_credential_args
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution_three_credentials.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_post("/institutions/#{institution_id}/logins").to_return(:body => fixture('account.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.discover_and_add_accounts(institution_id, 'username', 'password', 'account pin')
    assert_equal institution_id, response[:result][:account_list][:banking_account][:institution_id]
    assert_equal '000000000001', response[:result][:account_list][:banking_account][:account_id]
  end

  def test_discover_and_add_accounts_not_enough_credentials
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution_three_credentials.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    exception = assert_raise(ArgumentError) { @client.discover_and_add_accounts(institution_id, 'username', 'password') }
    assert_equal('institution_id 100000 requires 3 credential fields but was given 2 to authenticate with.', exception.message)
  end

  def test_discover_and_add_accounts_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.discover_and_add_accounts(arg, 'username', 'password') }
      assert_equal('institution_id is required', exception.message)

      exception = assert_raise(ArgumentError) { @client.discover_and_add_accounts(1, arg, 'password') }
      assert_equal('username is required', exception.message)

      exception = assert_raise(ArgumentError) { @client.discover_and_add_accounts(1, 'username', arg) }
      assert_equal('password is required', exception.message)
    end
  end

  def test_account
    account_id = '000000000001'
    stub_get("/accounts/#{account_id}").to_return(:body => fixture('account.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.account(account_id)
    assert_equal account_id, response[:result][:account_list][:banking_account][:account_id]
  end

  def test_account_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.account(arg) }
      assert_equal('account_id is required', exception.message)
    end
  end

  def test_accounts
    stub_get('/accounts').to_return(:body => fixture('accounts.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.accounts
    assert_equal '11111', response[:result][:account_list][:banking_account][0][:institution_id]
    assert_equal '75000033002', response[:result][:account_list][:banking_account][0][:account_id]
  end

  def test_account_transactions
    account_id = '000000000001'
    start_date = Date.today - 30
    uri = "/accounts/#{account_id}/transactions?txnStartDate=#{start_date.strftime(Aggcat::Base::DATE_FORMAT)}"
    stub_get(uri).to_return(:body => fixture('transactions.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.account_transactions(account_id, start_date)
    assert_equal '75000088503', response[:result][:transaction_list][:credit_card_transaction][:id]
  end

  def test_account_transactions_with_dates
    account_id = '000000000001'
    end_date = Date.today
    start_date = end_date - 30
    challenge_session_id = '1234'
    challenge_node_id = '4321'
    uri = "/accounts/#{account_id}/transactions?txnStartDate=#{start_date.strftime(Aggcat::Base::DATE_FORMAT)}&txnEndDate=#{end_date.strftime(Aggcat::Base::DATE_FORMAT)}"
    stub_get(uri).to_return(:body => fixture('transactions.xml'), :headers => {:content_type => 'application/xml; charset=utf-8', :challengeSessionId => challenge_session_id, :challengeNodeId => challenge_node_id})
    response = @client.account_transactions(account_id, start_date, end_date)
    assert_equal '75000088503', response[:result][:transaction_list][:credit_card_transaction][:id]
    assert_equal response[:challenge_session_id], challenge_session_id
    assert_equal response[:challenge_node_id], challenge_node_id
  end

  def test_account_transactions_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.account_transactions(arg, Date.today) }
      assert_equal('account_id is required', exception.message)

      exception = assert_raise(ArgumentError) { @client.account_transactions(1, arg) }
      assert_equal('start_date is required', exception.message)
    end
  end

  def test_update_account_type
    account_id = '000000000001'
    type = 'ANOTHER'
    stub_put("/accounts/#{account_id}").to_return(:status => 200)
    response = @client.update_account_type(account_id, type)
    assert_equal '200', response[:status_code]
  end

  def test_update_account_type_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.update_account_type(arg, 'CREDITCARD') }
      assert_equal('account_id is required', exception.message)

      exception = assert_raise(ArgumentError) { @client.update_account_type(1, arg) }
      assert_equal('type is required', exception.message)
    end
  end

  def test_delete_account
    account_id = '000000000001'
    stub_delete("/accounts/#{account_id}").to_return(:status => 200)
    response = @client.delete_account(account_id)
    assert_equal '200', response[:status_code]
  end

  def test_delete_account_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.delete_account(arg) }
      assert_equal('account_id is required', exception.message)
    end
  end

  def test_delete_customer
    stub_get('/accounts').to_return(:body => fixture('accounts.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_delete('/customers').to_return(:status => 200)
    response = @client.delete_customer
    assert_equal '200', response[:status_code]
    assert_nil @client.instance_variable_get('@oauth_token')
  end

  def test_login_accounts
    login_id = '147630161'
    stub_get("/logins/#{login_id}/accounts").to_return(:body => fixture('accounts.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.login_accounts(login_id)
    assert_equal '200', response[:status_code]
  end

  def test_login_accounts_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.login_accounts(arg) }
      assert_equal('login_id is required', exception.message)
    end
  end

  def test_update_login
    institution_id = '100000'
    login_id = '12345'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_put("/logins/#{login_id}?refresh=true").to_return(:status => 200)
    response = @client.update_login(institution_id, login_id, 'usename', 'password')
    assert_equal '200', response[:status_code]
  end

  def test_update_login_multiple_credential_args
    institution_id = '100000'
    login_id = '12345'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution_three_credentials.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_put("/logins/#{login_id}?refresh=true").to_return(:status => 200)
    response = @client.update_login(institution_id, login_id, 'usename', 'password', 'account pin')
    assert_equal '200', response[:status_code]
  end

  def test_update_login_not_enough_credentials
    institution_id = '100000'
    login_id = '12345'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution_three_credentials.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    exception = assert_raise(ArgumentError) { @client.update_login(institution_id, login_id, 'username', 'password') }
    assert_equal('institution_id 100000 requires 3 credential fields but was given 2 to authenticate with.', exception.message)
  end

  def test_update_login_bad_args
    [nil, ''].each do |arg|
      exception = assert_raise(ArgumentError) { @client.update_login(arg, 1, 'username', 'password') }
      assert_equal('institution_id is required', exception.message)

      exception = assert_raise(ArgumentError) { @client.update_login(1, arg, 'username', 'password') }
      assert_equal('login_id is required', exception.message)

      exception = assert_raise(ArgumentError) { @client.update_login(1, 1, arg, 'password') }
      assert_equal('username is required', exception.message)

      exception = assert_raise(ArgumentError) { @client.update_login(1, 1, 'username', arg) }
      assert_equal('password is required', exception.message)
    end
  end

  def test_account_confirmation
    institution_id = '100000'
    challenge_session_id = '1234'
    challenge_node_id = '4321'
    answer = 'answer'
    parser = XmlHasher::Parser.new(snakecase: true, ignore_namespaces: true)
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_post("/institutions/#{institution_id}/logins").to_return(:body => lambda { |request| assert_equal(parser.parse(fixture('challenge.xml')), parser.parse(request.body)) })
    @client.account_confirmation(institution_id, challenge_session_id, challenge_node_id, answer)
  end

  def test_account_confirmation_multi_answer
    institution_id = '100000'
    challenge_session_id = '1234'
    challenge_node_id = '4321'
    answers = ['answer1', 'answer2']
    parser = XmlHasher::Parser.new(snakecase: true, ignore_namespaces: true)
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_post("/institutions/#{institution_id}/logins").to_return(:body => lambda { |request| assert_equal(parser.parse(fixture('challenges.xml')), parser.parse(request.body)) })
    @client.account_confirmation(institution_id, challenge_session_id, challenge_node_id, answers)
  end

  def test_update_login_confirmation
    login_id = '1234567890'
    challenge_session_id = '1234'
    challenge_node_id = '4321'
    answer = 'answer'
    validator = lambda do |request|
      parser = XmlHasher::Parser.new(snakecase: true, ignore_namespaces: true)
      assert_equal(parser.parse(fixture('challenge.xml')), parser.parse(request.body))
      assert_equal(challenge_session_id, request.headers['Challengesessionid'])
      assert_equal(challenge_node_id, request.headers['Challengenodeid'])
    end
    stub_put("/logins/#{login_id}?refresh=true").to_return(:body => validator)
    @client.update_login_confirmation(login_id, challenge_session_id, challenge_node_id, answer)
  end

  def test_update_login_confirmation_multi_answers
    login_id = '1234567890'
    challenge_session_id = '1234'
    challenge_node_id = '4321'
    answers = ['answer1', 'answer2']
    validator = lambda do |request|
      parser = XmlHasher::Parser.new(snakecase: true, ignore_namespaces: true)
      assert_equal(parser.parse(fixture('challenges.xml')), parser.parse(request.body))
      assert_equal(challenge_session_id, request.headers['Challengesessionid'])
      assert_equal(challenge_node_id, request.headers['Challengenodeid'])
    end
    stub_put("/logins/#{login_id}?refresh=true").to_return(:body => validator)
    @client.update_login_confirmation(login_id, challenge_session_id, challenge_node_id, answers)
  end

  def test_retry_success
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_timeout.times(1).then.to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.institution(institution_id)
    assert_equal institution_id, response[:result][:institution_detail][:institution_id]
  end

  def test_retry_failure
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_timeout.times(2)
    assert_raise(Timeout::Error) { @client.institution(institution_id) }
  end

  def test_investment_postitions
    account_id = '000000000001'
    stub_get("/accounts/#{account_id}/positions").to_return(:body => fixture('positions.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.investment_positions(account_id)
    assert_equal response[:result][:investment_positions][:position][0][:investment_position_id].to_i , 000000000001
    assert_equal response[:result][:investment_positions][:position][1][:investment_position_id].to_i , 000000000002
  end

end
