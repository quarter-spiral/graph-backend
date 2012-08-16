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

    def self.exists?(relationship_type, uuid1, uuid2)
      ensure_relationship_type_exists(relationship_type)

      !connection.get_path(Node.find_or_create(uuid1), Node.find_or_create(uuid2), {"type"=> relationship_type, "direction" => "out"}, 1).empty?
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
  end
end
