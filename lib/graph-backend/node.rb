module Graph::Backend
  class Node
    ROLES = ['developer', 'game']

    def self.find_or_create(uuid)
      connection.get_node_auto_index('uuid', uuid) || connection.create_node('uuid' => uuid)
    end

    def self.find_by_role(role)
      ensure_role_exists(role)
      connection.find_node_auto_index("roles:\"#{escape_string(role)}\"") || []
    end

    def self.get_roles(uuid_or_node)
      node = get_node(uuid_or_node)
      connection.get_node_properties(node)['roles'] || []
    end

    def self.add_role(uuid_or_node, role)
      ensure_role_exists(role)

      node  = get_node(uuid_or_node)
      roles = get_roles(node)
      roles << role
      set_roles(node, roles)
    end

    def self.remove_role(uuid_or_node, role)
      ensure_role_exists(role)
      node = get_node(uuid_or_node)
      roles = get_roles(node)
      roles.delete role
      set_roles(node, roles)
    end

    protected
    def self.connection
      @connection ||= Connection.create
    end

    def self.get_node(uuid_or_node)
      uuid_or_node.is_a?(String) ? find_or_create(uuid_or_node) : uuid_or_node
    end

    def self.ensure_role_exists(role)
      raise Error.new("Role #{role} does not exist!") unless ROLES.include?(role)
    end

    def self.escape_string(string)
      string.gsub(/[^\\]"/, '\"')
    end

    def self.set_roles(node, roles)
      if roles.empty?
        connection.remove_node_properties(node, 'roles')
      else
        connection.set_node_properties(node, 'roles' => roles.uniq)
      end
    end
  end
end
