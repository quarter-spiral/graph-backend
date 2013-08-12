require 'rubygems'
require 'bundler/setup'

require 'graph-backend'

require 'ping-middleware'
use Ping::Middleware

# Enable live logging
$stdout.sync = true

require 'raven'
require 'qs/request/tracker/raven_processor'
Raven.configure do |config|
  config.tags = {'app' => 'auth-backend'}
  config.processors = [Raven::Processor::SanitizeData, Qs::Request::Tracker::RavenProcessor]
end
use Raven::Rack
use Qs::Request::Tracker::Middleware
run Graph::Backend::API