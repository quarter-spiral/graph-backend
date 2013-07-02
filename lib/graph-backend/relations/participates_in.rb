module Graph::Backend::Relations
  class ParticipatesIn < Base
    def valid?
      Graph::Backend::Node.get_roles(@uuid1).include?('player') &&
        Graph::Backend::Node.get_roles(@uuid2).include?('turnbased-match')
    end
  end
end