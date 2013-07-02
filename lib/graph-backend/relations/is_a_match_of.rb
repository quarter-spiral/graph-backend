module Graph::Backend::Relations
  class IsAMatchOf < Base
    def valid?
      Graph::Backend::Node.get_roles(@uuid1).include?('turnbased-match') &&
        Graph::Backend::Node.get_roles(@uuid2).include?('game')
    end
  end
end