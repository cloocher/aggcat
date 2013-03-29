# Aggcat

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

# scope Aggcat client by customer id
Aggcat.scope(customer_id)

# get all supported financial institutions
Aggcat.institutions

# get details for Bank of America
Aggcat.institution(14007)

# add new financial account to aggregate from Bank of America
Aggcat.discover_and_add_accounts(14007, username, password)

# get already aggregated financial account
Aggcat.account(account_id)

# get all aggregated accounts
Aggcat.accounts

# delete account
Aggcat.delete_account(account_id)

# get account transactions
Aggcat.account_transactions(account_id, start_date, end_date)

# delete customer for the current scope
Aggcat.delete_customer

```

## Documentation

Please make sure to read Intuit's [Account Data API](http://docs.developer.intuit.com/0020_Aggregation_Categorization_Apps/AggCat_API/0020_API_Documentation) docs.

## Copyright
Copyright (c) 2013 Gene Drabkin.
See [LICENSE][] for details.

[license]: LICENSE.md
