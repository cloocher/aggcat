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

    def discover_and_add_accounts(institution_id, username, password, username_key=nil, password_key=nil)
      validate(institution_id: institution_id, username: username, password: password)
      body = credentials(institution_id, username, password, username_key, password_key)
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

    def update_login(institution_id, login_id, username, password, username_key=nil, password_key=nil)
      validate(institution_id: institution_id, login_id: login_id, username: username, password: password)
      body = credentials(institution_id, username, password, username_key=nil, password_key=nil)
      put("/logins/#{login_id}?refresh=true", body)
    end

    def update_login_confirmation(login_id, challenge_session_id, challenge_node_id, answers)
      validate(login_id: login_id, challenge_node_id: challenge_session_id, challenge_node_id: challenge_node_id, answers: answers)
      headers = {'challengeSessionId' => challenge_session_id, 'challengeNodeId' => challenge_node_id}
      put("/logins/#{login_id}?refresh=true", challenge_answers(answers), headers)
    end

    def delete_account(account_id)
      validate(account_id: account_id)
      delete("/accounts/#{account_id}")
    end

    def delete_customer
      if accounts[:result][:account_list]
        accounts[:result][:account_list].values.flatten.each do |account|
          delete_account(account[:account_id])
        end
      end
      delete('/customers')
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
        raise AggcatError.new response.code if response.code.to_i < 200 || response.code.to_i >= 400
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

    def credentials(institution_id, username, password,username_key=nil, password_key=nil)
      if username_key.nil?
        institution = institution(institution_id)
        keys = institution[:result][:institution_detail][:keys][:key].sort { |a, b| a[:display_order] <=> b[:display_order] }
        username_key = keys[0][:name]
        password_key = keys[1][:name]
      end
      
      hash = {
          username_key => username,
          password_key => password
      }

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

  end
end


