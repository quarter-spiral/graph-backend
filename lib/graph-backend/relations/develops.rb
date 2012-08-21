module Graph::Backend::Relations
  class Develops < Base
    def valid?
      Graph::Backend::Node.get_roles(@uuid1).include?('developer')
    end
  end
end
