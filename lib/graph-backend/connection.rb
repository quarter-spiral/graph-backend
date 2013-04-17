require 'neography'
require 'auth-client'

module Graph::Backend
  class Connection
    INDEXED_PROPERTIES = {
      nodes: ['uuid', 'roles'],
      relationships: []
    }

    attr_reader :neo4j, :auth, :cache

    def self.create
      new(
        ENV['NEO4J_URL'],
        ENV['QS_AUTH_BACKEND_URL'] || 'http://auth-backend.dev'
      )
    end

    def initialize(neo4j_url, auth_backend_url)
      @neo4j = ::Neography::Rest.new(neo4j_url)
      @cache = ::Cache::Client.new(::Cache::Backend::IronCache, ENV['IRON_CACHE_PROJECT_ID'], ENV['IRON_CACHE_TOKEN'], ENV['IRON_CACHE_CACHE'])
      @auth = Auth::Client.new(auth_backend_url, cache: @cache)
    end

    def setup_indices
      neo4j.set_node_auto_index_status(true)
      neo4j.set_relationship_auto_index_status(true)

      auto_indexed_node_properties = neo4j.get_node_auto_index_properties
      missing_auto_indexed_node_properties = INDEXED_PROPERTIES[:nodes] - auto_indexed_node_properties
      missing_auto_indexed_node_properties.each do |property|
        neo4j.add_node_auto_index_property(property)
      end

      auto_indexed_relationship_properties = neo4j.get_relationship_auto_index_properties
      missing_auto_indexed_relationship_properties = INDEXED_PROPERTIES[:relationships] - auto_indexed_relationship_properties
      missing_auto_indexed_relationship_properties.each do |property|
        conncetion.add_relationship_auto_index_property(property)
      end

      neo4j.create_node_auto_index
      neo4j.create_relationship_auto_index
    end
  end
end
