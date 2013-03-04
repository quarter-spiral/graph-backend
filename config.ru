require 'rubygems'
require 'bundler/setup'

require 'graph-backend'

require 'ping-middleware'
use Ping::Middleware

# Enable live logging
$stdout.sync = true

run Graph::Backend::API