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

  def test_institutions
    stub_get('/institutions').to_return(:body => fixture('institutions.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.institutions
    assert_equal response[:response][:institutions][:institution][0][:institution_id].to_i, 100000
  end

  def test_institution
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.institution(institution_id)
    assert_equal institution_id, response[:response][:institution_detail][:institution_id]
  end

  def test_institution_with_bad_id
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    exception = assert_raise(ArgumentError) { @client.institution('') }
    assert_equal('institution_id is required', exception.message)
  end

  def test_discover_and_add_accounts
    institution_id = '100000'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_post("/institutions/#{institution_id}/logins").to_return(:body => fixture('account.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.discover_and_add_accounts(institution_id, 'username', 'password')
    assert_equal institution_id, response[:response][:account_list][:banking_account][:institution_id]
    assert_equal '000000000001', response[:response][:account_list][:banking_account][:account_id]
  end

  def test_account
    account_id = '000000000001'
    stub_get("/accounts/#{account_id}").to_return(:body => fixture('account.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.account(account_id)
    assert_equal account_id, response[:response][:account_list][:banking_account][:account_id]
  end

  def test_accounts
    stub_get('/accounts').to_return(:body => fixture('accounts.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.accounts
    assert_equal '11111', response[:response][:account_list][:banking_account][0][:institution_id]
    assert_equal '75000033002', response[:response][:account_list][:banking_account][0][:account_id]
  end

  def test_account_transactions
    account_id = '000000000001'
    start_date = Date.today - 30
    uri = "/accounts/#{account_id}/transactions?txnStartDate=#{start_date.strftime(Aggcat::Base::DATE_FORMAT)}"
    stub_get(uri).to_return(:body => fixture('transactions.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    response = @client.account_transactions(account_id, Date.today - 30)
    assert_equal '75000088503', response[:response][:transaction_list][:credit_card_transaction][:id]
  end

  def test_delete_account
    account_id = '000000000001'
    stub_delete("/accounts/#{account_id}").to_return(:status => 200)
    response = @client.delete_account(account_id)
    assert_equal '200', response[:response_code]
  end

  def test_delete_customer
    stub_delete('/customers').to_return(:status => 200)
    response = @client.delete_customer
    assert_equal '200', response[:response_code]
  end

  def test_update_login
    institution_id = '100000'
    login_id = '12345'
    stub_get("/institutions/#{institution_id}").to_return(:body => fixture('institution.xml'), :headers => {:content_type => 'application/xml; charset=utf-8'})
    stub_put("/logins/#{login_id}?refresh=true").to_return(:status => 200)
    response = @client.update_login(institution_id, login_id, 'usename', 'password')
    assert_equal '200', response[:response_code]
  end

end
