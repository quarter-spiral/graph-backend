module Graph::Backend
  class Relation
    RELATIONSHIP_TYPES = ['develops']
    DIRECTIONS = ['incoming', 'outgoing', 'both']

    def self.create(relationship_type, uuid1, uuid2, direction)
      direction ||= 'outgoing'
      ensure_relationship_type_exists(relationship_type)
      ensure_direction_is_valid(direction)

      if ['incoming', 'both'].include?(direction)
        connection.create_relationship(relationship_type, Node.find_or_create(uuid2), Node.find_or_create(uuid1))
      end
      if ['outgoing', 'both'].include?(direction)
        connection.create_relationship(relationship_type, Node.find_or_create(uuid1), Node.find_or_create(uuid2))
      end
    end

    def self.delete(relationship_type, uuid1, uuid2)
      ensure_relationship_type_exists(relationship_type)

      path = get_path(relationship_type, uuid1, uuid2)
      relationship_url = (path['relationships'] || []).first
      return false unless relationship_url
      relationship = connection.get_relationship(relationship_url)
      connection.delete_relationship(relationship)
      true
    end

    def self.exists?(relationship_type, uuid1, uuid2)
      ensure_relationship_type_exists(relationship_type)

      !get_path(relationship_type, uuid1, uuid2).empty?
    end

    def self.list_for(relationship_type, uuid)
      ensure_relationship_type_exists(relationship_type)

      node = Node.find_or_create(uuid)
      relationships = connection.get_node_relationships(node, 'outgoing', relationship_type)
      jobs = (relationships || []).map {|r| [:get_node, other_end(r, node)]}
      connection.batch(*jobs).map {|node| node['body']['data']['uuid']}.uniq
    end

    protected
    def self.connection
      @connection ||= Connection.create
    end

    def self.ensure_relationship_type_exists(relationship_type)
      raise Error.new("Relationship type #{relationship_type} does not exist!") unless RELATIONSHIP_TYPES.include?(relationship_type)
    end

    def self.ensure_direction_is_valid(direction)
      raise Error.new("#{direction} is an invalid direction!") unless DIRECTIONS.include?(direction)
    end

    def self.get_path(relationship_type, uuid1, uuid2)
      connection.get_path(Node.find_or_create(uuid1), Node.find_or_create(uuid2), {"type"=> relationship_type, "direction" => "out"}, 1)
    end

    def self.other_end(relationship, node)
      return relationship['start'] if relationship['end'] == node['self']
      return relationship['end'] if relationship['start'] == node['self']
      raise Error.new("Node does not belong to this relationship!")
    end
  end
end
