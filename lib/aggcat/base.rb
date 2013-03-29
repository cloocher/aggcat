require 'active_support'
require 'active_support/builder'
require 'base64'
require 'cgi'
require 'net/https'
require 'nokogiri'
require 'nori'
require 'oauth'
require 'openssl'
require 'securerandom'
require 'uri'

module Aggcat
  class Base

    SAML_URL = 'https://oauth.intuit.com/oauth/v1/get_access_token_by_saml'

    NAMESPACE = 'http://schema.intuit.com/platform/fdatafeed/institutionlogin/v1'
    TIME_FORMAT = '%Y-%m-%dT%T.%LZ'
    DATE_FORMAT = '%Y-%m-%d'

    TIMEOUT = 120

    IGNORE_KEYS = Set.new([:'@xmlns', :'@xmlns:ns2', :'@xmlns:ns3', :'@xmlns:ns4', :'@xmlns:ns5', :'@xmlns:ns6', :'@xmlns:ns7', :'@xmlns:ns8', :'@xmlns:ns9'])

    protected

    def access_token
      token = oauth_token
      consumer = OAuth::Consumer.new(@consumer_key, @consumer_secret, {:timeout => TIMEOUT})
      OAuth::AccessToken.new(consumer, token[:key], token[:secret])
    end

    def oauth_token
      now = Time.now.utc
      if @oauth_token.nil? || @oauth_token[:expire_at] <= now
        @oauth_token = new_token(saml_message(@customer_id))
        @oauth_token[:expire_at] = now + 9 * 60 # 9 minutes
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
      #http.set_debug_output($stdout)
      response = http.request(request)
      params = CGI::parse(response.body)
      {key: params['oauth_token'][0], secret: params['oauth_token_secret'][0]}
    end

    def saml_message(user_id)
      now = Time.now.utc
      reference_id = SecureRandom.uuid.gsub('-', '')
      assertion = %[<?xml version="1.0" encoding="UTF-8"?><saml2:Assertion xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion" ID="_#{reference_id}" IssueInstant="#{iso8601(now)}" Version="2.0"><saml2:Issuer>#{@issuer_id}</saml2:Issuer><ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:SignedInfo><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/><ds:Reference URI="#_#{reference_id}"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>%%DIGEST%%</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>%%SIGNATURE%%</ds:SignatureValue></ds:Signature><saml2:Subject><saml2:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">#{user_id}</saml2:NameID><saml2:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"/></saml2:Subject><saml2:Conditions NotBefore="#{iso8601(now-5*60)}" NotOnOrAfter="#{iso8601(now+10*60)}"><saml2:AudienceRestriction><saml2:Audience>#{@issuer_id}</saml2:Audience></saml2:AudienceRestriction></saml2:Conditions><saml2:AuthnStatement AuthnInstant="#{iso8601(now)}" SessionIndex="_#{reference_id}"><saml2:AuthnContext><saml2:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml2:AuthnContextClassRef></saml2:AuthnContext></saml2:AuthnStatement></saml2:Assertion>]
      doc = Nokogiri::XML(assertion)
      doc.xpath('//ds:Signature', 'ds' => 'http://www.w3.org/2000/09/xmldsig#').remove
      doc.xpath('//text()[not(normalize-space())]').remove
      digest = OpenSSL::Digest::SHA1.digest(doc.canonicalize(Nokogiri::XML::XML_C14N_1_1))
      encoded_digest = Base64.encode64(digest).strip
      signed_info = %[<ds:SignedInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/><ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/><ds:Reference URI="#_#{reference_id}"><ds:Transforms><ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/><ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/></ds:Transforms><ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/><ds:DigestValue>#{encoded_digest.strip}</ds:DigestValue></ds:Reference></ds:SignedInfo>]
      signature_value = Nokogiri::XML(signed_info).canonicalize
      key = OpenSSL::PKey::RSA.new(File.read(@certificate_path))
      encoded_signature_value = Base64.encode64(key.sign(OpenSSL::Digest::SHA1.new, signature_value)).gsub!(/\n/, '')
      Base64.encode64(assertion.gsub(/%%DIGEST%%/, encoded_digest).gsub(/%%SIGNATURE%%/, encoded_signature_value))
    end

    def iso8601(time)
      time.strftime(TIME_FORMAT)
    end

    def parse_xml(data)
      @parser ||= Nori.new(:parser => :nokogiri,
                           :strip_namespaces => true,
                           :convert_tags_to => lambda { |tag| tag.snakecase.to_sym })
      cleanup(@parser.parse(data))
    end

    def cleanup(hash)
      hash.each do |k, v|
        if IGNORE_KEYS.include?(k)
          hash.delete(k)
        elsif v.respond_to?(:keys)
          cleanup(v)
        end
      end
      hash
    end
  end
end
