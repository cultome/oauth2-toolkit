# frozen_string_literal: true

require 'securerandom'
require 'digest'
require 'faraday'
require 'base64'
require 'json'
require 'thor'

module Oath2Course
  class Cli < Thor
    SPA_CLIENT_ID = '0oa1544e81jwUDzaf5d7'

    CLIENT_ID_CREDENTIAL = '0oa155f93aGyY1d2O5d7'
    CLIENT_SECRET_CREDENTIAL = 'rq3iZoMdGDHotIDuCoznAui5DyBkKteRLa5iMxJx'
    CLIENT_ID = '0oa153ahp1h5UmRWP5d7'
    CLIENT_SECRET = '5Pdd_XF4QJuFeu2Ol1ZEMHFBj0EVJKfnXatMeOBw'

    INTROSPECTION_URL = 'https://dev-19441964.okta.com/oauth2/default/v1/introspect'
    AUTHORIZE_URL = 'https://dev-19441964.okta.com/oauth2/default/v1/authorize'
    TOKEN_URL = 'https://dev-19441964.okta.com/oauth2/default/v1/token'
    REDIRECT_URI = 'https://example-app.com/redirect'

    desc 'code', 'Executes a grant code flow'
    def code
      pkce_code = randstr 128

      puts "[1] Authorize URL:"
      puts code_url pkce_code, CLIENT_ID

      print "[2] Write the authorization code: "
      auth_code = STDIN.gets.chomp

      body = obtain_token pkce_code, auth_code
      puts "[3] Authentication response:"
      puts JSON.pretty_generate body
    end

    desc 'refresh TOKEN', 'Executes grant refresh token flow'
    def refresh(token)
      body = obtain_token_with_refresh token
      puts "[1] Refresh Token response:"
      puts JSON.pretty_generate body
    end

    desc 'pkce', 'Exceutes a grant code flow with PKCE'
    def pkce
      pkce_code = randstr 128

      puts "[1] Authorize URL:"
      puts code_url pkce_code, SPA_CLIENT_ID, ['offline_access']

      print "[2] Write the authorization code: "
      auth_code = STDIN.gets.chomp

      body = obtain_pkce_token pkce_code, auth_code
      puts "[3] Authentication response:"
      puts JSON.pretty_generate body
    end

    desc 'credentials', 'Execute grant client credentials flow'
    def credentials
      body = obtain_credentials_token
      puts "[1] Authentication response:"
      puts JSON.pretty_generate body
    end

    desc 'openid', 'Include scopes for OpenID'
    def openid
      pkce_code = randstr 128

      puts "[1] Authorize URL:"
      puts code_url pkce_code, CLIENT_ID, ['openid', 'profile', 'email']

      print "[2] Write the authorization code: "
      auth_code = STDIN.gets.chomp

      body = obtain_token pkce_code, auth_code
      puts "[3] Authentication response:"
      puts JSON.pretty_generate body

      puts "[4] OpenID JWT contents:"
      payload = Base64.decode64 body['id_token'].split('.')[1]
      content = JSON.parse payload
      puts JSON.pretty_generate content
    end

    desc 'validate ACCESS_TOKEN', 'Validate and access token'
    def validate(access_token)
      query_string = URI.encode_www_form(
        client_id: CLIENT_ID_CREDENTIAL,
        client_secret: CLIENT_SECRET_CREDENTIAL,
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

      def code_url(pkce_code, client_id, extra_scopes = [], state = randstr)
        challenge_code = urlsafe_base64 pkce_code

        query_string = URI.encode_www_form(
          response_type: 'code',
          client_id: client_id,
          redirect_uri: REDIRECT_URI,
          scope: [*extra_scopes, 'aleph'].join(' '),
          state: state,
          code_challenge: challenge_code,
          code_challenge_method: 'S256',
        )

        "#{AUTHORIZE_URL}?#{query_string}"
      end

      def obtain_token_with_refresh(refresh_token)
        token_body = URI.encode_www_form(
          grant_type: 'refresh_token',
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          refresh_token: refresh_token,
        )

        response = Faraday.post TOKEN_URL, token_body
        JSON.parse(response.body.to_s)
      end

      def obtain_credentials_token
        token_body = URI.encode_www_form(
          grant_type: 'client_credentials',
          client_id: CLIENT_ID_CREDENTIAL,
          client_secret: CLIENT_SECRET_CREDENTIAL,
          scope: ['aleph'],
        )

        response = Faraday.post TOKEN_URL, token_body
        JSON.parse(response.body.to_s)
      end

      def obtain_pkce_token(pkce_code, auth_code)
        token_body = URI.encode_www_form(
          grant_type: 'authorization_code',
          code: auth_code,
          redirect_uri: REDIRECT_URI,
          code_verifier: pkce_code,
          client_id: SPA_CLIENT_ID,
        )

        response = Faraday.post TOKEN_URL, token_body
        JSON.parse(response.body.to_s)
      end

      def obtain_token(pkce_code, auth_code)
        token_body = URI.encode_www_form(
          grant_type: 'authorization_code',
          code: auth_code,
          redirect_uri: REDIRECT_URI,
          code_verifier: pkce_code,
          client_id: CLIENT_ID,
          # different from PKE flow
          client_secret: CLIENT_SECRET,
        )

        response = Faraday.post TOKEN_URL, token_body
        JSON.parse(response.body.to_s)
      end
    end
  end
end
