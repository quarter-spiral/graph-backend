module Graph
  module Backend
    def self.boot
      Connection.setup_indices
    end
  end
end

require "graph-backend/version"
require "graph-backend/error"
require "graph-backend/connection"
require "graph-backend/node"
require "graph-backend/relations"
require "graph-backend/relation"
require "graph-backend/api"

ENV['RACK_ENV'] ||= 'development'

if ['test', 'development'].include?(ENV['RACK_ENV'])
  ENV['NEO4J_URL'] ||= 'http://localhost:7474'
end

Graph::Backend.boot
