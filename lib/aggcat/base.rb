require 'active_support'
require 'active_support/builder'
require 'base64'
require 'cgi'
require 'net/https'
require 'oauth'
require 'openssl'
require 'securerandom'
require 'set'
require 'xmlhasher'
require 'uri'

module Aggcat
  class Base

    SAML_URL = 'https://oauth.intuit.com/oauth/v1/get_access_token_by_saml'

    LOGIN_NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/institutionlogin/v1'
    CHALLENGE_NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/challenge/v1'
    BANKING_ACCOUNT_NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/bankingaccount/v1'
    CREDIT_ACCOUNT_NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/creditaccount/v1'
    LOAN_NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/loan/v1'
    INVESTMENT_ACCOUNT_NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/investmentaccount/v1'
    REWARD_ACCOUNT_NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/rewardsaccount/v1'

    BANKING_TYPES = Set.new %w(CHECKING SAVINGS MONEYMRKT RECURRINGDEPOSIT CD CASHMANAGEMENT OVERDRAFT)
    CREDIT_TYPES = Set.new %w(CREDITCARD LINEOFCREDIT OTHER)
    LOAN_TYPES = Set.new %w(LOAN AUTO COMMERCIAL CONSTR CONSUMER HOMEEQUITY MILITARY MORTGAGE SMB STUDENT)
    INVESTMENT_TYPES = Set.new %w(TAXABLE 401K BROKERAGE IRA 403B KEOGH TRUST TDA SIMPLE NORMAL SARSEP UGMA OTHER)

    TIME_FORMAT = '%Y-%m-%dT%T.%LZ'
    DATE_FORMAT = '%Y-%m-%d'

    OPEN_TIMEOUT = 15
    READ_TIMEOUT = 120

    protected

    def oauth_client
      OAuth::AccessToken.new(oauth_consumer, *oauth_token)
    end

    def oauth_consumer
      @oauth_consumer ||= OAuth::Consumer.new(@consumer_key, @consumer_secret, {timeout: @read_timeout, open_timeout: @open_timeout, verbose: @verbose})
    end

    def oauth_token(force=false)
      now = Time.now
      if force || @oauth_token.nil? || @oauth_token_expire_at <= now
        @oauth_token = new_token(saml_message(@customer_id))
        @oauth_token_expire_at = now + 9 * 60 # 9 minutes
      end
      @oauth_token
    end

    def new_token(message)
      uri = URI.parse(SAML_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Authorization'] = %[OAuth oauth_consumer_key="#{@consumer_key}"]
      request.set_form_data({:saml_assertion => message})
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.set_debug_output($stdout) if @verbose
      response = http.request(request)
      params = CGI::parse(response.body)
      [params['oauth_token'][0], params['oauth_token_secret'][0]]
    end

    def saml_message(user_id)
      now = Time.now.utc
      reference_id = SecureRandom.uuid.gsub('-', '')
      assertion = %[<saml2:Assertion xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion" ID="_#{reference_id}" IssueInstant="#{iso8601(now)}" Version="2.0"><saml2:Issuer>#{@issuer_id}</saml2:Issuer><saml2:Subject><saml2:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">#{user_id}</saml2:NameID><saml2:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"></saml2:SubjectConfirmation></saml2:Subject><saml2:Conditions NotBefore="#{iso8601(now-5*60)}" NotOnOrAfter="#{iso8601(now+10*60)}"><saml2:AudienceRestriction><saml2:Audience>#{@issuer_id}</saml2:Audience></saml2:AudienceRestriction></saml2:Conditions><saml2:AuthnStatement AuthnInstant="#{iso8601(now)}" SessionIndex="_#{reference_id}"><saml2:AuthnContext><saml2:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml2:AuthnContextClassRef></saml2:AuthnContext></saml2:AuthnStatement></saml2:Assertion>]
      digest = Base64.encode64(OpenSSL::Digest::SHA1.digest(assertion)).strip
      signed_info = %[<ds:SignedInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:CanonicalizationMethod><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"></ds:SignatureMethod><ds:Reference URI="#_#{reference_id}"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></ds:DigestMethod><ds:DigestValue>#{digest}</ds:DigestValue></ds:Reference></ds:SignedInfo>]
      key = OpenSSL::PKey::RSA.new(certificate)
      signature_value = Base64.encode64(key.sign(OpenSSL::Digest::SHA1.new(nil), signed_info)).gsub(/\n/, '')
      signature = %[<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/><ds:Reference URI="#_#{reference_id}"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>#{digest}</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>#{signature_value}</ds:SignatureValue></ds:Signature>]
      assertion_with_signature = assertion.sub(/saml2:Issuer\>\<saml2:Subject/, "saml2:Issuer>#{signature}<saml2:Subject")
      Base64.encode64(assertion_with_signature)
    end

    def certificate
      @certificate_value ||= File.read(@certificate_path)
    end

    def iso8601(time)
      time.strftime(TIME_FORMAT)
    end

    def parse_xml(data)
      return data if data.nil? || data.to_s.empty?
      @parser ||= XmlHasher::Parser.new(snakecase: true, ignore_namespaces: true)
      @parser.parse(data)
    end
  end
end
