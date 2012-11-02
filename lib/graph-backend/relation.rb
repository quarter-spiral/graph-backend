module Graph::Backend
  class Relation
    RELATIONSHIP_TYPES = ['develops', 'friends']
    DIRECTIONS = ['incoming', 'outgoing', 'both']

    def self.create(relationship_type, uuid1, uuid2, direction)
      direction ||= 'outgoing'
      ensure_relationship_type_exists(relationship_type)
      ensure_direction_is_valid(direction)
      ensure_relationship_is_valid(relationship_type, uuid1, uuid2, direction)

      if ['incoming', 'both'].include?(direction)
        connection.create_relationship(relationship_type, Node.find_or_create(uuid2), Node.find_or_create(uuid1))
      end
      if ['outgoing', 'both'].include?(direction)
        connection.create_relationship(relationship_type, Node.find_or_create(uuid1), Node.find_or_create(uuid2))
      end
    end

    def self.delete(relationship_type, uuid1, uuid2)
      ensure_relationship_type_exists(relationship_type)

      paths = get_paths(relationship_type, uuid1, uuid2)
      relationship_urls = paths.map {|path| (path['relationships'] || []).first}.compact

      return false if relationship_urls.empty?

      relationship_urls.each do |relationship_url|
        relationship = connection.get_relationship(relationship_url)
        connection.delete_relationship(relationship)
      end
      true
    end

    def self.exists?(relationship_type, uuid1, uuid2, direction = nil)
      ensure_relationship_type_exists(relationship_type)

      result = true
      if direction && (direction == 'incoming' || direction == 'both')
        result = result && !get_paths(relationship_type, uuid2, uuid1).empty?
      end
      if !direction || (direction == 'outgoing' || direction == 'both')
        result = result && !get_paths(relationship_type, uuid1, uuid2).empty?
      end
      result
    end

    def self.list_for(relationship_type, uuid, direction)
      direction ||= 'outgoing'
      ensure_direction_is_valid(direction)

      ensure_relationship_type_exists(relationship_type)

      node = Node.find_or_create(uuid)
      relationships = connection.get_node_relationships(node, direction, relationship_type)
      get_ends(node, relationships).map {|relationship, node| node['body']['data']['uuid']}.uniq
    end

    def self.revise_relationships_for(uuid)
      node = Node.find_or_create(uuid)
      relationships = connection.get_node_relationships(node, 'outgoing')
      get_ends(node, relationships).each do |relationship, other_end|
        other_uuid = other_end['body']['data']['uuid']
        begin
          ensure_relationship_is_valid(relationship['type'], uuid, other_uuid, 'outgoing')
        rescue Error
          connection.delete_relationship(relationship)
        end
      end
    end

    protected
    def self.connection
      @connection ||= Connection.create.neo4j
    end

    def self.ensure_relationship_type_exists(relationship_type)
      raise Error.new("Relationship type #{relationship_type} does not exist!") unless RELATIONSHIP_TYPES.include?(relationship_type)
    end

    def self.ensure_direction_is_valid(direction)
      raise Error.new("#{direction} is an invalid direction!") unless DIRECTIONS.include?(direction)
    end

    def self.ensure_relationship_is_valid(relationship_type, uuid1, uuid2, direction)
      validator = validator_for(relationship_type)
      return unless validator

      if ['incoming', 'both'].include?(direction)
        valid = validator.new(uuid2, uuid1).valid?
        raise Error.new("Relation: #{uuid2} #{relationship_type} #{uuid1} is invalid!") unless valid
      end

      if ['outgoing', 'both'].include?(direction)
        valid = validator.new(uuid1, uuid2).valid?
        raise Error.new("Relation: #{uuid1} #{relationship_type} #{uuid2} is invalid!") unless valid
      end
    end

    def self.get_paths(relationship_type, uuid1, uuid2)
      connection.get_paths(Node.find_or_create(uuid1), Node.find_or_create(uuid2), {"type"=> relationship_type, "direction" => "out"}, 1)
    end

    def self.get_ends(node, relationships)
      jobs = (relationships || []).map {|r| [:get_node, other_end(r, node)]}
      (relationships || []).zip(connection.batch(*jobs))
    end

    def self.other_end(relationship, node)
      return relationship['start'] if relationship['end'] == node['self']
      return relationship['end'] if relationship['start'] == node['self']
      raise Error.new("Node does not belong to this relationship!")
    end

    def self.validator_for(relationship_type)
      class_name = camelize_string(relationship_type)
      Graph::Backend::Relations.const_get(class_name)
    rescue NameError => e
      nil
    end

    def self.camelize_string(str)
      str.sub(/^[a-z\d]*/) { $&.capitalize }.gsub(/(?:_|(\/))([a-z\d]*)/i) {$2.capitalize}
    end
  end
end
