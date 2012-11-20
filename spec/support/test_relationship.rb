module Graph::Backend::Relations
  class TestRelates < Base
    def self.valid(uuid1, uuid2, valid = true)
      @valids ||= {}
      @valids[uuid1] ||= {}
      @valids[uuid1][uuid2] = valid
    end

    def self.invalid(uuid1, uuid2)
      valid(uuid1, uuid2, false)
    end

    def self.valid?(uuid1, uuid2)
      @always_valid || (@valids && @valids[uuid1] && @valids[uuid1][uuid2])
    end

    def self.always_valid(valid)
      @always_valid = valid
    end

    def self.reset!
      @valids = nil
    end

    def valid?
      self.class.valid?(@uuid1, @uuid2)
    end
  end
end
