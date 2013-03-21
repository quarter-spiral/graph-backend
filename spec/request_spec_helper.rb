require_relative './spec_helper'

require 'json'
require 'uuid'
require 'cgi'
require 'rack/client'

include Graph::Backend

class AuthenticationInjector
  def self.token=(token)
    @token = token
  end

  def self.token
    @token
  end

  def self.reset!
    @token = nil
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    if token = self.class.token
      env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
    end

    @app.call(env)
  end
end

class ContentTypeInjector
  def initialize(app)
    @app = app
  end

  def call(env)
    env['CONTENT_TYPE'] = 'application/json'
    env['CONTENT_LENGTH'] = env['rack.input'].length
    @app.call(env)
  end
end

ENV['QS_AUTH_BACKEND_URL'] = 'http://auth-backend.dev'

API_APP  = API.new
AUTH_APP = Auth::Backend::App.new(test: true)

module Auth
  class Client
    alias raw_initialize initialize
    def initialize(url, options = {})
      raw_initialize(url, options.merge(adapter: [:rack, AUTH_APP]))
    end
  end
end


def client
  return @client if @client

  @client = client = Rack::Client.new {
      use AuthenticationInjector
      use ContentTypeInjector
      run API_APP
  }

  def @client.get(url, headers = {}, body = '', &block)
    params = body && !body.empty? ? JSON.parse(body) : {}
    url += "?" + params.map {|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join('&')
    request('GET', url, headers, nil, {}, &block)
  end
  def @client.delete(url, headers = {}, body = '', &block)
    params = body && !body.empty? ? JSON.parse(body) : {}
    url += "?" + params.map {|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join('&')
    request('DELETE', url, headers, nil, {}, &block)
  end

  @client
end

require 'auth-backend/test_helpers'
AUTH_HELPERS = Auth::Backend::TestHelpers.new(AUTH_APP)

def auth_helpers
  AUTH_HELPERS
end

OAUTH_TOKEN = auth_helpers.get_token
def token
  token = OAUTH_TOKEN
end

def has_role?(uuid, role)
  JSON.parse(client.get("/v1/roles/#{role}").body).include? @entity1
end

def is_related?(uuid1, uuid2, relationship_type = 'test_relates')
  client.get("/v1/entities/#{uuid1}/#{relationship_type}/#{uuid2}").status == 200
end
