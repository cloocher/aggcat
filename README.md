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
```

### Playing with the API

It is recommend to take a look at the [API Use cases](https://developer.intuit.com/docs/0020_customeraccountdata/customer_account_data_api/0005_key_concepts).

There are several testing accounts provided by Intuit: [Testing Calls to the API](https://developer.intuit.com/docs/0020_customeraccountdata/customer_account_data_api/testing_calls_to_the_api).


#### Get institutions details

```ruby
# create an scope for a client
customer_id = 1
@scope = Aggcat.scope(customer_id)

# get all supported financial institutions
@scope.institutions

# get details for Bank of America
@scope.institution(14007)
```

#### Discovering accounts

```ruby
# add new financial account to aggregate from Bank of America
result = @scope.discover_and_add_accounts(14007, username, password)
puts result

# if MFA is needed, you need to answers the challenges
challenges = result[:result][:challenges]
answers = ['first_answer', 'second_answer']
result = @scope.account_confirmation(14007, result[:challenge_session_id], result[:challenge_node_id], answers)
```

#### Retrieving accounts and transactions

```ruby
# get already aggregated financial account
@scope.account(account_id)

# get all aggregated accounts
@scope.accounts

# get account transactions
start_date = Time.now - 2.month
end_date = Time.now - 1.month    # optional
@scope.account_transactions(account_id, start_date, end_date)
```

#### Updating login

```ruby
# update login credentials
@scope.update_login(institution_id, login_id, new_username, new_password)

# if MFA is needed, you need to answers the challenges
@scope.update_login_confirmation(institution_id, challenge_session_id, challenge_node_id, answers)
```

#### Other

```ruby
# you can set scope inline for any request
Aggcat.scope(customer1).account(account_id)

# delete account
@scope.delete_account(account_id)

# delete customer for the current scope
@scope.delete_customer
```

## Documentation

Please make sure to read Intuit's [Account Data API](http://docs.developer.intuit.com/0020_Aggregation_Categorization_Apps/AggCat_API/0020_API_Documentation) docs.

## Requirements

* Ruby 1.9.3 or higher

## Copyright
Copyright (c) 2013 Gene Drabkin.
See [LICENSE][] for details.

[license]: LICENSE.md
