require_relative '../spec_helper.rb'

require 'json'
require 'uuid'
require 'rack/client'

include Graph::Backend

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

def client
  @client ||= Rack::Client.new {run API}
end

def has_role?(uuid, role)
  JSON.parse(client.get("/v1/roles/#{role}").body).include? @entity1
end

def is_related?(uuid1, uuid2, relationship_type = 'test_relates')
  client.get("/v1/entities/#{uuid1}/#{relationship_type}/#{uuid2}").status == 200
end

describe Graph::Backend::API do
  before do
    @entity1 = UUID.new.generate
    @entity2 = UUID.new.generate

    Graph::Backend::Relation::RELATIONSHIP_TYPES << 'test_relates'
    Graph::Backend::Relations::TestRelates.always_valid(true)
  end

  after do
    Graph::Backend::Relation::RELATIONSHIP_TYPES.delete 'test_relates'
    Graph::Backend::Relations::TestRelates.reset!
  end

  describe "roles" do
    it "can add roles to an entity" do
      has_role?(@entity1, 'developer').must_equal false
      client.post "/v1/entities/#{@entity1}/roles/developer"
      has_role?(@entity1, 'developer').must_equal true
    end

    it "can remove roles of an entity" do
      has_role?(@entity1, 'developer').must_equal false
      client.post   "/v1/entities/#{@entity1}/roles/developer"
      client.delete "/v1/entities/#{@entity1}/roles/developer"
      has_role?(@entity1, 'developer').must_equal false
    end

    it "returns an error when trying to add a non-exisitng role" do
      response = client.post "/v1/entities/#{@entity1}/roles/mehmehmeh"
      response.status.wont_equal 201
      JSON.parse(response.body)['error'].wont_be_nil
    end

    it "can retrieve the roles of an entity" do
      response = client.get "/v1/entities/#{@entity1}/roles"
      JSON.parse(response.body).wont_include 'developer'
      client.post   "/v1/entities/#{@entity1}/roles/developer"
      response = client.get "/v1/entities/#{@entity1}/roles"
      JSON.parse(response.body).must_include 'developer'
    end
  end

  describe "relations" do
    describe "can be created" do
      it "outgoing" do
        is_related?(@entity1, @entity2).must_equal false
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        is_related?(@entity1, @entity2).must_equal true
        is_related?(@entity2, @entity1).must_equal false
      end

      it "incoming" do
        is_related?(@entity1, @entity2).must_equal false
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'incoming')
        is_related?(@entity1, @entity2).must_equal false
        is_related?(@entity2, @entity1).must_equal true
      end

      it "both ways" do
        is_related?(@entity1, @entity2).must_equal false
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'both')
        is_related?(@entity1, @entity2).must_equal true
        is_related?(@entity2, @entity1).must_equal true
      end
    end

    it "can be deleted" do
      is_related?(@entity1, @entity2).must_equal false
      is_related?(@entity2, @entity1).must_equal false
      client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'both')
      response = client.delete "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
      response.status.must_equal 200
      is_related?(@entity1, @entity2).must_equal false
      is_related?(@entity2, @entity1).must_equal true
      response = client.delete "/v1/entities/#{@entity2}/test_relates/#{@entity1}"
      response.status.must_equal 200
      is_related?(@entity1, @entity2).must_equal false
      is_related?(@entity2, @entity1).must_equal false
    end

    it "responds 404 when trying to delete a non-existing relationship" do
      is_related?(@entity1, @entity2).must_equal false
      response = client.delete "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
      response.status.must_equal 404
    end

    it "can list related entities" do
      @entity3 = UUID.new.generate
      @entity4 = UUID.new.generate

      client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'both')
      client.post "/v1/entities/#{@entity1}/test_relates/#{@entity3}"
      client.post "/v1/entities/#{@entity2}/test_relates/#{@entity4}"

      games_of_entity_1 = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates").body)
      games_of_entity_1.must_include @entity2
      games_of_entity_1.must_include @entity3


      games_of_entity_2 = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates").body)
      games_of_entity_2.must_include @entity1
      games_of_entity_2.must_include @entity4

      games_of_entity_3 = JSON.parse(client.get("/v1/entities/#{@entity3}/test_relates").body)
      games_of_entity_3.empty?.must_equal true

      games_of_entity_4 = JSON.parse(client.get("/v1/entities/#{@entity4}/test_relates").body)
      games_of_entity_4.empty?.must_equal true
    end

    it "can list incoming related entities" do
      @entity3 = UUID.new.generate
      @entity4 = UUID.new.generate

      client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
      client.post "/v1/entities/#{@entity3}/test_relates/#{@entity2}"
      client.post "/v1/entities/#{@entity4}/test_relates/#{@entity1}"

      relations = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates", {}, direction: 'incoming').body)
      relations.must_include(@entity1)
      relations.wont_include(@entity2)
      relations.must_include(@entity3)
      relations.wont_include(@entity4)

      relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates", {}, direction: 'incoming').body)
      relations.must_equal [@entity4]
    end

    it "can list two way related entities" do
      @entity3 = UUID.new.generate
      @entity4 = UUID.new.generate

      client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
      client.post "/v1/entities/#{@entity3}/test_relates/#{@entity2}"
      client.post "/v1/entities/#{@entity4}/test_relates/#{@entity1}"

      relations = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates", {}, direction: 'both').body)
      relations.must_include(@entity1)
      relations.wont_include(@entity2)
      relations.must_include(@entity3)
      relations.wont_include(@entity4)

      relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates", {}, direction: 'both').body)
      relations.wont_include(@entity1)
      relations.must_include(@entity2)
      relations.wont_include(@entity3)
      relations.must_include(@entity4)
    end

    describe "valiation mechanism" do
      before do
        Graph::Backend::Relations::TestRelates.always_valid(false)
      end

      it "invalid relations can't be setup" do
        response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        response.status.wont_equal 201

        Graph::Backend::Relations::TestRelates.valid(@entity1, @entity2)
        response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        response.status.must_equal 201

        response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, {direction: 'incoming'}
        response.status.wont_equal 201

        Graph::Backend::Relations::TestRelates.valid(@entity2, @entity1)
        response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, {direction: 'incoming'}
        response.status.must_equal 201

        client.delete "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        client.delete "/v1/entities/#{@entity2}/test_relates/#{@entity1}"

        response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, {direction: 'both'}
        response.status.must_equal 201
        is_related?(@entity1, @entity2).must_equal true
        is_related?(@entity2, @entity1).must_equal true
      end

      describe "removes invalid relations on role changes" do
        before do
          @entity3 = UUID.new.generate
          @entity4 = UUID.new.generate

          Graph::Backend::Relation::RELATIONSHIP_TYPES << 'test_relates_two'
          Graph::Backend::Relations::TestRelates.valid(@entity1, @entity2)
          Graph::Backend::Relations::TestRelates.valid(@entity1, @entity3)
          Graph::Backend::Relations::TestRelates.valid(@entity3, @entity1)

          client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
          client.post "/v1/entities/#{@entity1}/test_relates_two/#{@entity2}"

          client.post "/v1/entities/#{@entity1}/test_relates/#{@entity3}", {}, direction: 'both'

          client.post "/v1/entities/#{@entity1}/test_relates_two/#{@entity4}"

          is_related?(@entity1, @entity2).must_equal true
          is_related?(@entity1, @entity2, 'test_relates_two').must_equal true
          is_related?(@entity1, @entity3).must_equal true
          is_related?(@entity3, @entity1).must_equal true
          is_related?(@entity1, @entity4, 'test_relates_two').must_equal true
        end

        after do
          # overcoming a stupid 1.9.2/minitest bug
          Graph::Backend::Relation::RELATIONSHIP_TYPES << 'test_relates'

          is_related?(@entity1, @entity2).must_equal false
          is_related?(@entity1, @entity2, 'test_relates_two').must_equal true
          is_related?(@entity1, @entity3).must_equal false
          is_related?(@entity3, @entity1).must_equal true
          is_related?(@entity1, @entity4, 'test_relates_two').must_equal true

          Graph::Backend::Relation::RELATIONSHIP_TYPES.delete 'test_relates_two'
        end

        it "works on adding roles" do
          Graph::Backend::Relations::TestRelates.invalid(@entity1, @entity2)
          Graph::Backend::Relations::TestRelates.invalid(@entity1, @entity3)
          Graph::Backend::Relations::TestRelates.invalid(@entity3, @entity1)

          client.post "/v1/entities/#{@entity1}/roles/developer"
        end

        it "works on removing roles" do
          client.post "/v1/entities/#{@entity1}/roles/developer"
          Graph::Backend::Relations::TestRelates.invalid(@entity1, @entity2)
          Graph::Backend::Relations::TestRelates.invalid(@entity1, @entity3)
          Graph::Backend::Relations::TestRelates.invalid(@entity3, @entity1)
          client.delete "/v1/entities/#{@entity1}/roles/developer"
        end
      end
    end
  end
end
