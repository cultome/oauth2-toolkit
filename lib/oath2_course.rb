# frozen_string_literal: true

require 'dotenv/load'
require 'securerandom'
require 'digest'
require 'faraday'
require 'base64'
require 'json'
require 'thor'

module Oath2Course
  class Cli < Thor
    desc 'code', 'Executes a grant code flow'
    option :profile, type: :string, required: true
    def code
      pkce_code = randstr 128

      puts "[1] Authorize URL:"
      puts code_url pkce_code, client_id

      print "[2] Write the authorization code: "
      auth_code = STDIN.gets.chomp

      body = obtain_token pkce_code, auth_code
      puts "[3] Authentication response:"
      puts JSON.pretty_generate body
    end

    desc 'refresh TOKEN', 'Executes grant refresh token flow'
    option :profile, type: :string, required: true
    def refresh(token)
      body = obtain_token_with_refresh token
      puts "[1] Refresh Token response:"
      puts JSON.pretty_generate body
    end

    desc 'pkce', 'Exceutes a grant code flow with PKCE'
    option :profile, type: :string, required: true
    def pkce
      pkce_code = randstr 128

      puts "[1] Authorize URL:"
      puts code_url pkce_code, client_id, custom_scopes

      print "[2] Write the authorization code: "
      auth_code = STDIN.gets.chomp

      body = obtain_pkce_token pkce_code, auth_code
      puts "[3] Authentication response:"
      puts JSON.pretty_generate body
    end

    desc 'credentials', 'Execute grant client credentials flow'
    option :profile, type: :string, required: true
    def credentials
      body = obtain_credentials_token custom_scopes
      puts "[1] Authentication response:"
      puts JSON.pretty_generate body
    end

    desc 'openid', 'Include scopes for OpenID'
    option :profile, type: :string, required: true
    def openid
      pkce_code = randstr 128

      puts "[1] Authorize URL:"
      puts code_url pkce_code, client_id, custom_scopes

      print "[2] Write the authorization code: "
      auth_code = STDIN.gets.chomp

      body = obtain_token pkce_code, auth_code
      puts "[3] Authentication response:"
      puts JSON.pretty_generate body

      puts "[4] OpenID JWT contents:"
      # puts "[DEBUG] #{body}"
      payload = Base64.decode64 body['id_token'].split('.')[1]
      content = JSON.parse payload
      puts JSON.pretty_generate content
    end

    desc 'validate ACCESS_TOKEN', 'Validate and access token'
    option :profile, type: :string, required: true
    def validate(access_token)
      query_string = URI.encode_www_form(
        client_id: client_id,
        client_secret: client_secret,
        token: access_token,
      )

      puts "[1] Validate token:"
      response = Faraday.post INTROSPECTION_URL, query_string
      body = JSON.parse(response.body.to_s)
      puts JSON.pretty_generate body
    end

    no_commands do
      def randstr(size=10)
        SecureRandom.hex(size / 2)
      end

      def urlsafe_base64(value)
        Base64.urlsafe_encode64(Digest::SHA256.digest value).gsub('=', '')
      end

      def code_url(pkce_code, client_id, scopes = [], state = randstr)
        challenge_code = urlsafe_base64 pkce_code

        query_string = URI.encode_www_form(
          response_type: 'code',
          client_id: client_id,
          redirect_uri: redirect_uri,
          scope: scopes.join(' '),
          state: state,
          code_challenge: challenge_code,
          code_challenge_method: 'S256',
        )

        "#{AUTHORIZE_URL}?#{query_string}"
      end

      def obtain_token_with_refresh(refresh_token)
        token_body = URI.encode_www_form(
          grant_type: 'refresh_token',
          client_id: client_id,
          client_secret: client_secret,
          refresh_token: refresh_token,
        )

        response = Faraday.post token_url, token_body
        JSON.parse(response.body.to_s)
      end

      def obtain_credentials_token(scopes)
        token_body = URI.encode_www_form(
          grant_type: 'client_credentials',
          client_id: client_id,
          client_secret: client_secret,
          scope: scopes.join(' '),
        )

        response = Faraday.post token_url, token_body
        JSON.parse(response.body.to_s)
      end

      def obtain_pkce_token(pkce_code, auth_code)
        token_body = URI.encode_www_form(
          grant_type: 'authorization_code',
          code: auth_code,
          redirect_uri: redirect_uri,
          code_verifier: pkce_code,
          client_id: client_id,
        )

        response = Faraday.post token_url, token_body
        JSON.parse(response.body.to_s)
      end

      def obtain_token(pkce_code, auth_code)
        token_body = URI.encode_www_form(
          grant_type: 'authorization_code',
          code: auth_code,
          redirect_uri: redirect_uri,
          code_verifier: pkce_code,
          client_id: client_id,
          # different from PKE flow
          client_secret: client_secret,
        )

        response = Faraday.post token_url, token_body
        JSON.parse(response.body.to_s)
      end

      def client_id
        ENV["#{options[:profile]}.client_id"]
      end

      def client_secret
        ENV["#{options[:profile]}.client_secret"]
      end

      def base_url
        ENV["#{options[:profile]}.base_url"]
      end

      def custom_scopes
        ENV["#{options[:profile]}.scopes"].split(',')
      end

      def redirect_uri
        ENV["#{options[:profile]}.callback_url"]
      end

      def introspection_url
        "#{base_url}/introspect"
      end

      def authorize_url
        "#{base_url}/authorize"
      end

      def token_url
        "#{base_url}/token"
      end
    end
  end
end
