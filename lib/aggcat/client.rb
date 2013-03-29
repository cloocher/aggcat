module Aggcat
  class Client < Aggcat::Base

    BASE_URL = 'https://financialdatafeed.platform.intuit.com/rest-war/v1'

    def initialize(options={})
      Aggcat::Configurable::KEYS.each do |key|
        instance_variable_set(:"@#{key}", options[key] || Aggcat.instance_variable_get(:"@#{key}"))
      end
    end

    def institutions
      get('/institutions')
    end

    def institution(institution_id)
      get("/institutions/#{institution_id}")
    end

    def discover_and_add_accounts(institution_id, username, password)
      body = credentials(institution_id, username, password)
      post("/institutions/#{institution_id}/logins", body, {user_id: "#{institution_id}-#{username}"})
    end

    def accounts
      get('/accounts')
    end

    def account(account_id)
      get("/accounts/#{account_id}")
    end

    def account_transactions(account_id, start_date = nil, end_date = nil)
      uri = "/accounts/#{account_id}/transactions"
      if start_date
        uri += "?txnStartDate=#{start_date.strftime(DATE_FORMAT)}"
        if end_date
          uri += "&txnEndDate=#{end_date.strftime(DATE_FORMAT)}"
        end
      end
      get(uri)
    end

    def delete_account(account_id)
      delete("/accounts/#{account_id}")
    end

    def delete_customers
      delete('/customers')
    end

    protected

    def get(uri, options = {:user_id => 'default'})
      response = access_token(options[:user_id]).get("#{BASE_URL}#{uri}")
      {:response_code => response.code, :response => parse_xml(response.body)}
    end

    def post(uri, message, options = {})
      response = access_token(options[:user_id]).post("#{BASE_URL}#{uri}", message, {'Content-Type' => 'application/xml'})
      result = {:response_code => response.code, :response => parse_xml(response.body)}
      if response['challengeSessionId']
        result[:challenge_session_id] = response['challengeSessionId']
        result[:challenge_node_id] = response['challengeNodeId']
      end
      result
    end

    def delete(uri, options = {:user_id => 'default'})
      response = access_token(options[:user_id]).delete("#{BASE_URL}#{uri}")
      {:response_code => response.code, :response => parse_xml(response.body)}
    end

    private

    def credentials(institution_id, username, password)
      institution = institution(institution_id)
      keys = institution[:response][:institution_detail][:keys][:key].sort { |a, b| a[:display_order] <=> b[:display_order] }
      hash = {
          keys[0][:name] => username,
          keys[1][:name] => password
      }

      xml = Builder::XmlMarkup.new
      xml.InstitutionLogin('xmlns' => NAMESPACE) do |login|
        login.credentials('xmlns:ns1' => NAMESPACE) do
          hash.each do |key, value|
            xml.tag!('ns1:credential', {'xmlns:ns2' => NAMESPACE}) do
              xml.tag!('ns2:name', key)
              xml.tag!('ns2:value', value)
            end
          end
        end
      end
    end
  end
end

