module Graph::Backend
  class Relation
    RELATIONSHIP_TYPES = ['develops', 'friends', 'plays']
    DIRECTIONS = ['incoming', 'outgoing', 'both']

    attr_reader :uuid_source, :uuid_target, :relation, :meta

    def initialize(uuid_source, uuid_target, relation, meta = {})
      @uuid_source = uuid_source
      @uuid_target = uuid_target
      @relation = relation
      @meta = meta
    end

    def to_hash
      {
        "source" => uuid_source,
        "target" => uuid_target,
        "relation" => relation,
        "meta" => meta
      }
    end

    def dirty!
      @dirty = true
    end

    def dirty?
      @dirty
    end

    def self.create(relationship_type, uuid1, uuid2, direction, meta = {})
      direction ||= 'outgoing'
      ensure_relationship_type_exists(relationship_type)
      ensure_direction_is_valid(direction)
      ensure_relationship_is_valid(relationship_type, uuid1, uuid2, direction)

      relations = []
      if ['incoming', 'both'].include?(direction)
        relationship = connection.create_relationship(relationship_type, Node.find_or_create(uuid2), Node.find_or_create(uuid1))
        connection.reset_relationship_properties(relationship, meta)
        relations << Relation.new(uuid2, uuid1, relationship_type, meta)
      end
      if ['outgoing', 'both'].include?(direction)
        relationship = connection.create_relationship(relationship_type, Node.find_or_create(uuid1), Node.find_or_create(uuid2))
        connection.reset_relationship_properties(relationship, meta)
        relations << Relation.new(uuid1, uuid2, relationship_type, meta)
      end
      relations
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

    def self.get(relationship_type, uuid1, uuid2)
      ensure_relationship_type_exists(relationship_type)
      relationship = get_paths(relationship_type, uuid1, uuid2).sort {|a,b| a['relationships'].first.split('/').last.to_i <=> b['relationships'].first.split('/').last.to_i}.first
      return unless relationship
      relationship['relationships'].first
    end

    def self.update_meta(relationship_type, uuid1, uuid2, direction, meta, options = {})
      relations = []
      direction ||= 'outgoing'
      if direction == 'outgoing' || direction == 'both'
        relationship = get(relationship_type, uuid1, uuid2)
        old_meta, new_meta = self.set_meta_data(relationship, meta, options[:merge])
        relation =  Relation.new(uuid1, uuid2, relationship_type, new_meta)
        relation.dirty! if new_meta != old_meta
        relations << relation
      end
      if direction == 'incoming' || direction == 'both'
        relationship = get(relationship_type, uuid2, uuid1)
        old_meta, new_meta = self.set_meta_data(relationship, meta, options[:merge])
        relation = Relation.new(uuid2, uuid1, relationship_type, meta)
        relation.dirty! if new_meta != old_meta
        relations << relation
      end
      relations
    end

    def self.list_for(relationship_type, uuid, direction)
      direction ||= 'outgoing'
      ensure_direction_is_valid(direction)

      ensure_relationship_type_exists(relationship_type)

      node = Node.find_or_create(uuid)
      relationships = connection.get_node_relationships(node, direction, relationship_type)
      get_ends(node, relationships).map do |relationship, node|
        meta = get_meta_data(relationship)
        Relation.new(uuid, node['data']['uuid'], relationship_type, meta).to_hash
      end.uniq
    end

    def self.get_meta_data(relation)
      connection.get_relationship_properties(relation) || {}
    end

    def self.set_meta_data(relationship, meta, merge)
      old_meta = connection.get_relationship_properties(relationship) || {}
      connection.set_relationship_properties(relationship, meta)
      if merge
        [old_meta, old_meta.merge(meta)]
      else
        properties_to_remove = old_meta.keys - meta.keys
        unless properties_to_remove.empty?
          connection.remove_relationship_properties(relationship, properties_to_remove)
        end

        [old_meta, meta]
      end
    end

    def self.revise_relationships_for(uuid)
      node = Node.find_or_create(uuid)
      relationships = connection.get_node_relationships(node, 'outgoing')
      get_ends(node, relationships).each do |relationship, other_end|
        begin
          ensure_relationship_is_valid(relationship['type'], node, other_end, 'outgoing')
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
      connection.get_paths(Node.find_or_create(uuid1), Node.find_or_create(uuid2), {"type"=> relationship_type, "direction" => "out"}, 2).select {|e| e['nodes'].length == 2}
    end

    def self.get_ends(node, relationships)
      ids = (relationships || []).map {|r| other_end(r, node).split('/').last.to_i}
      results = []
      unless ids.empty?
        query = "START n = node(#{ids.join(',')}) return n"
        results = connection.execute_query(query)['data'].map(&:first)
      end
      (relationships || []).zip(results)
    end

    def self.get_properties(node, relationships)
      jobs = (relationships || []).map {|r| [:get_node_properties, other_end(r, node)]}
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

    def self.relationship_id(relationship)
      relationship['self'].gsub(/^.*\//, '')
    end

    def self.camelize_string(str)
      str.sub(/^[a-z\d]*/) { $&.capitalize }.gsub(/(?:_|(\/))([a-z\d]*)/i) {$2.capitalize}
    end
  end
end
