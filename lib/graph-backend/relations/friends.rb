module Graph::Backend::Relations
  class Friends < Base
    def valid?
      Graph::Backend::Node.get_roles(@uuid1).include?('player') &&
        Graph::Backend::Node.get_roles(@uuid2).include?('player')
    end
  end
end

