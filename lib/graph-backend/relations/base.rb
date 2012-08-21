module Graph::Backend::Relations
  class Base
    def initialize(uuid1, uuid2, connection)
      @uuid1 = uuid1
      @uuid2 = uuid2

      @connection = connection
    end
  end
end
