# frozen_string_literal: true

require 'securerandom'
require 'digest'
require 'faraday'
require 'base64'
require 'json'

client_id = '0oa153ahp1h5UmRWP5d7'
client_secret = '5Pdd_XF4QJuFeu2Ol1ZEMHFBj0EVJKfnXatMeOBw'
state = SecureRandom.hex(5)
pkce_code = SecureRandom.hex(64)
challenge_code = Base64.urlsafe_encode64(Digest::SHA256.digest pkce_code).gsub('=', '')

#puts "[0] Generated codes:"
#puts "    - state: #{state}"
#puts "    - pkce_code: #{pkce_code}"
#puts "    - challenge_code: #{challenge_code}"

query_string = URI.encode_www_form response_type: 'code', scope: 'aleph', client_id: client_id, state: state, redirect_uri: 'https://example-app.com/redirect', code_challenge: challenge_code, code_challenge_method: 'S256'

puts "[1] Authorize URL:"
puts "https://dev-19441964.okta.com/oauth2/default/v1/authorize?#{query_string}"

print "[2] Write the authorization code: "
auth_code = STDIN.gets.chomp

token_body = URI.encode_www_form grant_type: 'authorization_code', redirect_uri: 'https://example-app.com/redirect', client_id: client_id, client_secret: client_secret, code_verifier: pkce_code, code: auth_code

response = Faraday.post 'https://dev-19441964.okta.com/oauth2/default/v1/token', token_body
body = JSON.parse(response.body.to_s)

puts "[3] Authentication response:"
puts JSON.pretty_generate body
