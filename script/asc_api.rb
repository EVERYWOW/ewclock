#!/usr/bin/env ruby
# frozen_string_literal: true

# Minimal App Store Connect API client authenticated with an API key.
#
# Usage: script/asc_api.rb GET  /v1/apps?filter[bundleId]=ch.everywow.clock
#        script/asc_api.rb POST /v1/... '{"data": ...}'
#
# Reads ASC_KEY_ID, ASC_ISSUER_ID, and optional ASC_KEY_PATH from the
# environment (see script/asc_env.sh). Prints the JSON response body.

require "base64"
require "json"
require "net/http"
require "openssl"
require "uri"

def b64url(data)
  Base64.urlsafe_encode64(data, padding: false)
end

key_id = ENV.fetch("ASC_KEY_ID") { abort "ASC_KEY_ID is not set" }
issuer_id = ENV.fetch("ASC_ISSUER_ID") { abort "ASC_ISSUER_ID is not set" }
key_path = ENV.fetch("ASC_KEY_PATH", File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{key_id}.p8"))

method, path, body = ARGV
abort "Usage: #{$PROGRAM_NAME} METHOD PATH [JSON_BODY]" if method.nil? || path.nil?

key = OpenSSL::PKey::EC.new(File.read(key_path))
now = Time.now.to_i
header = { alg: "ES256", kid: key_id, typ: "JWT" }
payload = { iss: issuer_id, iat: now, exp: now + 600, aud: "appstoreconnect-v1" }
signing_input = "#{b64url(header.to_json)}.#{b64url(payload.to_json)}"
der = key.sign(OpenSSL::Digest.new("SHA256"), signing_input)
r, s = OpenSSL::ASN1.decode(der).value.map { |v| v.value.to_s(2).rjust(32, "\0") }
token = "#{signing_input}.#{b64url(r + s)}"

uri = URI.join("https://api.appstoreconnect.apple.com", path)
request_class = Net::HTTP.const_get(method.capitalize)
request = request_class.new(uri)
request["Authorization"] = "Bearer #{token}"
if body
  request["Content-Type"] = "application/json"
  request.body = body
end

response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
puts response.body unless response.body.to_s.empty?
unless response.is_a?(Net::HTTPSuccess)
  warn "HTTP #{response.code} for #{method.upcase} #{path}"
  exit 1
end
