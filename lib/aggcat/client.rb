module Aggcat
  class Client < Aggcat::Base

    BASE_URL = 'https://financialdatafeed.platform.intuit.com/rest-war/v1'

    def initialize(options={})
      raise ArgumentError.new('customer_id is required for scoping all requests') if options[:customer_id].nil? || options[:customer_id].to_s.empty?
      options[:open_timeout] ||= OPEN_TIMEOUT
      options[:read_timeout] ||= READ_TIMEOUT
      options[:verbose] ||= false
      Aggcat::Configurable::KEYS.each do |key|
        instance_variable_set(:"@#{key}", !options[key].nil? ? options[key] : Aggcat.instance_variable_get(:"@#{key}"))
      end
    end

    def institutions
      get('/institutions')
    end

    def institution(institution_id)
      validate(institution_id: institution_id)
      get("/institutions/#{institution_id}")
    end

    def discover_and_add_accounts(institution_id, *login_credentials)
      validate(institution_id: institution_id, username: login_credentials[0], password: login_credentials[1])
      body = credentials(institution_id, login_credentials)
      post("/institutions/#{institution_id}/logins", body)
    end

    def account_confirmation(institution_id, challenge_session_id, challenge_node_id, answers)
      validate(institution_id: institution_id, challenge_node_id: challenge_session_id, challenge_node_id: challenge_node_id, answers: answers)
      headers = {'challengeSessionId' => challenge_session_id, 'challengeNodeId' => challenge_node_id}
      post("/institutions/#{institution_id}/logins", challenge_answers(answers), headers)
    end

    def accounts
      get('/accounts')
    end

    def account(account_id)
      validate(account_id: account_id)
      get("/accounts/#{account_id}")
    end

    def account_transactions(account_id, start_date, end_date = nil)
      validate(account_id: account_id, start_date: start_date)
      path = "/accounts/#{account_id}/transactions?txnStartDate=#{start_date.strftime(DATE_FORMAT)}"
      if end_date
        path += "&txnEndDate=#{end_date.strftime(DATE_FORMAT)}"
      end
      get(path)
    end

    def login_accounts(login_id)
      validate(login_id: login_id)
      get("/logins/#{login_id}/accounts")
    end

    def update_login(institution_id, login_id, *login_credentials)
      validate(institution_id: institution_id, login_id: login_id, username: login_credentials[0], password: login_credentials[1])
      body = credentials(institution_id, login_credentials)
      put("/logins/#{login_id}?refresh=true", body)
    end

    def update_login_confirmation(login_id, challenge_session_id, challenge_node_id, answers)
      validate(login_id: login_id, challenge_node_id: challenge_session_id, challenge_node_id: challenge_node_id, answers: answers)
      headers = {'challengeSessionId' => challenge_session_id, 'challengeNodeId' => challenge_node_id}
      put("/logins/#{login_id}?refresh=true", challenge_answers(answers), headers)
    end

    def update_account_type(account_id, type)
      validate(account_id: account_id, type: type)
      put("/accounts/#{account_id}", account_type(type))
    end

    def delete_account(account_id)
      validate(account_id: account_id)
      delete("/accounts/#{account_id}")
    end

    def delete_customer
      result = delete('/customers')
      if result[:status_code] == '200'
        @oauth_token = nil
      end
      result
    end

    def investment_positions(account_id)
      validate(account_id: account_id)
      get("/accounts/#{account_id}/positions")
    end

    protected

    def get(path, headers = {})
      request(:get, path, headers)
    end

    def post(path, body, headers = {})
      request(:post, path, body, headers.merge({'Content-Type' => 'application/xml'}))
    end

    def put(path, body, headers = {})
      request(:put, path, body, headers.merge({'Content-Type' => 'application/xml'}))
    end

    def delete(path, headers = {})
      request(:delete, path, headers)
    end

    private

    def request(http_method, path, *options)
      tries = 0
      begin
        response = oauth_client.send(http_method, BASE_URL + path, *options)
        result = {:status_code => response.code, :result => parse_xml(response.body)}
        if response['challengeSessionId']
          result[:challenge_session_id] = response['challengeSessionId']
          result[:challenge_node_id] = response['challengeNodeId']
        end
        return result
      rescue => e
        raise e if tries >= 1
        puts "failed to make API call - #{e.message}, retrying"
        oauth_token(true)
        tries += 1
      end while tries == 1
    end

    def validate(args)
      args.each do |name, value|
        if value.nil? || value.to_s.empty?
          raise ArgumentError.new("#{name} is required")
        end
      end
    end

    def credentials(institution_id, login_credentials)
      institution = institution(institution_id)
      raise ArgumentError.new("institution_id #{institution_id} is invalid") if institution.nil? || institution[:result][:institution_detail].nil?
      login_keys = institution[:result][:institution_detail][:keys][:key].select { |key| key[:display_flag] == 'true' }.sort { |a, b| a[:display_order].to_i <=> b[:display_order].to_i }
      if login_keys.length != login_credentials.length
        raise ArgumentError.new("institution_id #{institution_id} requires #{login_keys.length} credential fields but was given #{login_credentials.length} to authenticate with.")
      end

      hash = login_keys.each_with_index.inject({}) { |h, (key, index)| h[key[:name]] = login_credentials[index].to_s; h }

      xml = Builder::XmlMarkup.new
      xml.InstitutionLogin('xmlns' => LOGIN_NAMESPACE) do |login|
        login.credentials('xmlns:ns1' => LOGIN_NAMESPACE) do
          hash.each do |key, value|
            xml.tag!('ns1:credential', {'xmlns:ns2' => LOGIN_NAMESPACE}) do
              xml.tag!('ns2:name', key)
              xml.tag!('ns2:value', value)
            end
          end
        end
      end
    end

    def challenge_answers(answers)
      xml = Builder::XmlMarkup.new
      xml.InstitutionLogin('xmlns' => LOGIN_NAMESPACE) do |login|
        login.challengeResponses do |challenge|
          [answers].flatten.each do |answer|
            challenge.response(answer, 'xmlns' => CHALLENGE_NAMESPACE)
          end
        end
      end
    end

    def account_type(type)
      xml = Builder::XmlMarkup.new
      if BANKING_TYPES.include?(type)
        xml.tag!('ns4:BankingAccount', {'xmlns:ns4' => BANKING_ACCOUNT_NAMESPACE}) do
          xml.tag!('ns4:bankingAccountType', type)
        end
      elsif CREDIT_TYPES.include?(type)
        xml.tag!('ns4:CreditAccount', {'xmlns:ns4' => CREDIT_ACCOUNT_NAMESPACE}) do
          xml.tag!('ns4:creditAccountType', type)
        end
      elsif LOAN_TYPES.include?(type)
        xml.tag!('ns4:Loan', {'xmlns:ns4' => LOAN_NAMESPACE}) do
          xml.tag!('ns4:loanType', type)
        end
      elsif INVESTMENT_TYPES.include?(type)
        xml.tag!('ns4:InvestmentAccount', {'xmlns:ns4' => INVESTMENT_ACCOUNT_NAMESPACE}) do
          xml.tag!('ns4:investmentAccountType', type)
        end
      else
        xml.tag!('ns4:RewardAccount', {'xmlns:ns4' => REWARD_ACCOUNT_NAMESPACE}) do
          xml.tag!('ns4:rewardAccountType')
        end
      end
    end
  end
end


