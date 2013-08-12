module Graph
  module Backend
    def self.boot
      Connection.create.setup_indices
    end
  end
end

require 'cache-client'
require 'cache-backend-iron-cache'

require "graph-backend/version"
require "graph-backend/error"
require "graph-backend/connection"
require "graph-backend/node"
require "graph-backend/relations"
require "graph-backend/relation"
require "graph-backend/query"
require "graph-backend/api"

ENV['RACK_ENV'] ||= 'development'

if ['test', 'development'].include?(ENV['RACK_ENV'])
  ENV['NEO4J_URL'] ||= 'http://localhost:7474'
end

Graph::Backend.boot

require 'qs/request/tracker'
require 'qs/request/tracker/service_client_extension'