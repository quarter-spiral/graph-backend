require 'rubygems'
require 'bundler/setup'

require 'graph-backend'
require 'newrelic_rpm'
require 'new_relic/agent/instrumentation/rack'
require 'ping-middleware'

class NewRelicMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  end
  include NewRelic::Agent::Instrumentation::Rack
end

use NewRelicMiddleware
use Ping::Middleware

run Graph::Backend::API
