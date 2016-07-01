# Aggcat
[![Build Status](https://travis-ci.org/cloocher/aggcat.png)](https://travis-ci.org/cloocher/aggcat)
[![Coverage Status](https://coveralls.io/repos/cloocher/aggcat/badge.png?branch=master)](https://coveralls.io/r/cloocher/aggcat)
[![Gem Version](https://badge.fury.io/rb/aggcat.png)](http://badge.fury.io/rb/aggcat)

  Intuit Customer Account Data API client

## Installation

Aggcat is available through [Rubygems](http://rubygems.org/gems/aggcat) and can be installed via:

```
$ gem install aggcat
```

or add it to your Gemfile like this:

```
gem 'aggcat'
```

## Start Guide

Register for [Intuit Customer Account Data](https://developer.intuit.com/docs/0020_customeraccountdata/0005_service_features).

Get your OAuth data.

Or

Register for [Finicity Facade API](https://www.finicity.com/IntuitTransition/)

If you want to use the Finicity Facade API set the following additional
configuration parameters:

```ruby
oauth_url: 'https://api.finicity.com/oauth/v1/get_access_token_by_saml'
base_url: 'https://api.finicity.com/financialdatafeed/v1'
```

See: [Finicity Setup](https://finicity.zendesk.com/hc/en-us/articles/208775606-Finicity-Setup)

## Usage

```ruby
require 'aggcat'

# Aggcat global configuration
Aggcat.configure do |config|
  config.oauth_url 'oauth url if using Finicity Facade API'
  config.base_url 'base url if using Finicity Facade API'
  config.issuer_id = 'your issuer id'
  config.consumer_key = 'your consumer key'
  config.consumer_secret = 'your consumer secret'
  config.certificate_path = '/path/to/your/certificate/key'
  config.verbose = false # verbose = true will output all raw XML API requests/responses to STDOUT
  # certificate could be provided as a string instead of a path to a file using certificate_value
  # certificate_value takes precedence over certificate_path
  # certificate_value should contain newline characters as appropriate
  # config.certificate_value = "-----BEGIN RSA PRIVATE KEY-----\nasdf123FOO$BAR\n...\n-----END RSA PRIVATE KEY-----"
  # certificate's can contain passwords, put your password here.
  # config.certificate_password = "1234"
end

# alternatively, specify configuration options when instantiating an Aggcat::Client
client = Aggcat::Client.new(
  issuer_id: 'your issuer id',
  consumer_key: 'your consumer key',
  consumer_secret: 'your consumer secret',
  certificate_path: '/path/to/your/certificate/key', # OR certificate_value: "--BEGIN RSA KEY--..."
  customer_id: 'scope for all requests'
)

# create an scoped client by customer_id
client = Aggcat.scope(customer_id)

# get all supported financial institutions
client.institutions

# get details for Bank of America
client.institution(14007)

# add new financial account to aggregate from Bank of America
response = client.discover_and_add_accounts(14007, username, password)

# in case MFA is required
questions = response[:result][:challenges]
answers = ['first answer', 'second answer']
challenge_session_id = response[:challenge_session_id]
challenge_node_id = response[:challenge_node_id]
client.account_confirmation(14007, challenge_session_id, challenge_node_id, answers)

# get already aggregated financial account
client.account(account_id)

# get all aggregated accounts
client.accounts

# get account transactions
start_date = Date.today - 30
end_date = Date.today # optional
client.account_transactions(account_id, start_date, end_date)

# update account type
client.update_account_type(account_id, 'CREDITCARD')

# update login credentials
client.update_login(institution_id, login_id, new_username, new_password)

# in case MFA is required
client.update_login_confirmation(login_id, challenge_session_id, challenge_node_id, answers)

# get position info for an investment account
client.investment_positions(account_id)

# you can set scope inline for any request
Aggcat.scope(customer_id).account(account_id)

# delete account
client.delete_account(account_id)

# delete customer for the current scope
client.delete_customer
```

## Documentation

Please make sure to read Intuit's [Account Data API](http://docs.developer.intuit.com/0020_Aggregation_Categorization_Apps/AggCat_API/0020_API_Documentation).

[API Use Cases](https://developer.intuit.com/docs/0020_customeraccountdata/customer_account_data_api/0005_key_concepts).

[Testing Calls to the API](https://developer.intuit.com/docs/0020_customeraccountdata/customer_account_data_api/testing_calls_to_the_api).

## Requirements

* Ruby 2.2.2 or higher

## Copyright
Copyright (c) 2013 Gene Drabkin.
See [LICENSE][] for details.

[license]: LICENSE.md
