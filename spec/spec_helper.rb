ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'auth-backend'

require 'rack/client'

require 'minitest/autorun'

require 'graph-backend'

# Wipe the graph
connection = Graph::Backend::Connection.create.neo4j
(connection.find_node_auto_index('uuid:*') || []).each do |node|
  connection.delete_node!(node)
end
