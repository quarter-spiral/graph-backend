Bundler.setup

require 'minitest/autorun'

require 'graph-backend'

# Wipe the graph
connection = Graph::Backend::Connection.create
(connection.find_node_auto_index('uuid:*') || []).each do |node|
  connection.delete_node!(node)
end
