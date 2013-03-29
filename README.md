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

# configure Aggcat
Aggcat.configure do |config|
  config.issuer_id = YOUR_ISSUER_ID
  config.consumer_key = YOUR_CONSUMER_KEY
  config.consumer_secret = YOUR_CONSUMER_SECRET
  config.certificate_path = '/path/to/your/certificate/key'
end

# create client
client = Aggcat.client

# get all supported financial institutions
client.institutions
=> {:response_code=>"200", :response=>{:institutions=>{:institution=>[{:institution_id=>"8860", :institution_name=>"Carolina Foothills FCU Credit Card", :home_url=>"http://www.cffcu.org/index.html", :phone_number=>"1-864-585-6838", :virtual=>false},

# get details for Bank of America
client.institution(14007)
=> {:response_code=>"200", :response=>{:institution_detail=>{:institution_id=>"14007", :institution_name=>"Bank of America", :home_url=>"https://www.bankofamerica.com/", :phone_number=>"1-800-792-0808", :address=>{:address1=>"307 S. MAIN", :city=>"Charlotte", :state=>"NC", :postal_code=>"28255", :country=>"USA"}, :email_address=>"https://www.bankofamerica.com/contact/", :special_text=>"Please enter your Bank of America Online ID and Passcode required for login.", :currency_code=>"USD", :keys=>{:key=>[{:name=>"TAX_AGGR_ENABLED", :val=>"FALSE", :status=>"Active", :display_flag=>false, :display_order=>"20", :mask=>false}, {:name=>"passcode", :status=>"Active", :value_length_max=>"20", :display_flag=>true, :display_order=>"2", :mask=>true, :description=>"Passcode"}, {:name=>"onlineID", :status=>"Active", :value_length_max=>"32", :display_flag=>true, :display_order=>"1", :mask=>false, :description=>"Online ID"}]}}}}

# add new financial account to aggregate from Bank of America
client.discover_and_add_accounts(14007, username, password)

# get one financial account
client.account(account_id)

# get all aggregated accounts
client.accounts

# delete account
client.delete_account(account_id)

# get account transactions
client.account_transactions(account_id, start_date, end_date)

# delete all aggregated customers
client.delete_customers

```

## Documentation

Please make sure to read Intuit's [Account Data API](http://docs.developer.intuit.com/0020_Aggregation_Categorization_Apps/AggCat_API/0020_API_Documentation) docs.

## Copyright
Copyright (c) 2013 Gene Drabkin.
See [LICENSE][] for details.

[license]: LICENSE.md
