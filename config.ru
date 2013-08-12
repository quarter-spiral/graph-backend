require 'rubygems'
require 'bundler/setup'

require 'graph-backend'

require 'ping-middleware'
use Ping::Middleware

# Enable live logging
$stdout.sync = true

use Qs::Request::Tracker::Middleware
run Graph::Backend::API