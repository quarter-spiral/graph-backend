module Graph::Backend::Relations
  class Plays < Base
    def valid?
      Graph::Backend::Node.get_roles(@uuid1).include?('player') &&
        Graph::Backend::Node.get_roles(@uuid2).include?('game')
    end
  end
end


