module Graph::Backend
  class Query
    def initialize(starting_uuids, query)
      starting_uuids = Array(starting_uuids)

      @starting_nodes = starting_uuids.map {|uuid| Node.id(Node.find_or_create(uuid))}

      @query = query
    end

    def to_cypher
      start = []
      @starting_nodes.each_with_index do |node, i|
        start << "node#{i}=node(#{node})"
      end
      start = start.join(", ")

      "START #{start} #{@query}"
    end
  end
end
