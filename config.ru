require 'rubygems'
require 'bundler/setup'

require 'graph-backend'

require 'ping-middleware'
use Ping::Middleware

run Graph::Backend::API
