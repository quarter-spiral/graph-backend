require 'neography'

module Graph::Backend
  class Connection
    INDEXED_PROPERTIES = {
      nodes: ['uuid', 'roles'],
      relationships: []
    }

    def self.create
      ::Neography::Rest.new(ENV['NEO4J_URL'])
    end

    def self.setup_indices
      connection = create
      connection.set_node_auto_index_status(true)
      connection.set_relationship_auto_index_status(true)

      auto_indexed_node_properties = connection.get_node_auto_index_properties
      missing_auto_indexed_node_properties = INDEXED_PROPERTIES[:nodes] - auto_indexed_node_properties
      missing_auto_indexed_node_properties.each do |property|
        connection.add_node_auto_index_property(property)
      end

      auto_indexed_relationship_properties = connection.get_relationship_auto_index_properties
      missing_auto_indexed_relationship_properties = INDEXED_PROPERTIES[:relationships] - auto_indexed_relationship_properties
      missing_auto_indexed_relationship_properties.each do |property|
        conncetion.add_relationship_auto_index_property(property)
      end

      connection.create_node_auto_index
      connection.create_relationship_auto_index
    end
  end
end
