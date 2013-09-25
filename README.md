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

Take a look at the [API Use cases](https://developer.intuit.com/docs/0020_customeraccountdata/customer_account_data_api/0005_key_concepts).

[Test accounts](https://developer.intuit.com/docs/0020_customeraccountdata/customer_account_data_api/testing_calls_to_the_api).

## Usage

```ruby
require 'aggcat'

# Aggcat global configuration
Aggcat.configure do |config|
  config.issuer_id = 'your issuer id'
  config.consumer_key = 'your consumer key'
  config.consumer_secret = 'your consumer secret'
  config.certificate_path = '/path/to/your/certificate/key'
end

# alternatively, specify configuration options when instantiating an Aggcat::Client
client = Aggcat::Client.new(
  issuer_id: 'your issuer id',
  consumer_key: 'your consumer key',
  consumer_secret: 'your consumer secret',
  certificate_path: '/path/to/your/certificate/key',
  customer_id: 'scope for all requests'
)

# create an scope for a client
scoped_client = Aggcat.scope(customer_id)

# get all supported financial institutions
scoped_client.institutions

# get details for Bank of America
scoped_client.institution(14007)

# add new financial account to aggregate from Bank of America
response = scoped_client.discover_and_add_accounts(14007, username, password)

# in case MFA is required
questions = response[:result][:challenges]
answers = ['first answer', 'second answer']
challenge_session_id = response[:challenge_session_id]
challenge_node_id = response[:challenge_node_id]
scoped_client.account_confirmation(14007, challenge_session_id, challenge_node_id, answers)

# get already aggregated financial account
scoped_client.account(account_id)

# get all aggregated accounts
scoped_client.accounts

# get account transactions
start_date = Date.today - 30
end_date = Date.today # optional
scoped_client.account_transactions(account_id, start_date, end_date)

# update login credentials
scoped_client.update_login(institution_id, login_id, new_username, new_password)

# in case MFA is required
scoped_client.update_login_confirmation(institution_id, challenge_session_id, challenge_node_id, answers)

# you can set scope inline for any request
Aggcat.scope(customer_id).account(account_id)

# delete account
scoped_account.delete_account(account_id)

# delete customer for the current scope
scoped_account.delete_customer
```

## Documentation

Please make sure to read Intuit's [Account Data API](http://docs.developer.intuit.com/0020_Aggregation_Categorization_Apps/AggCat_API/0020_API_Documentation) docs.

## Requirements

* Ruby 1.9.3 or higher

## Copyright
Copyright (c) 2013 Gene Drabkin.
See [LICENSE][] for details.

[license]: LICENSE.md
