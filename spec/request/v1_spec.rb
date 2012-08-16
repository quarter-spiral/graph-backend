require_relative '../spec_helper.rb'

require 'json'
require 'uuid'
require 'rack/client'

include Graph::Backend

def client
  @client ||= Rack::Client.new {run API}
end

def has_role?(uuid, role)
  JSON.parse(client.get("/v1/roles/#{role}").body).include? @entity1
end

def is_related?(uuid1, uuid2)
  client.get("/v1/entities/#{uuid1}/develops/#{uuid2}").status == 200
end

describe Graph::Backend::API do
  before do
    @entity1 = UUID.new.generate
    @entity2 = UUID.new.generate
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
  end

  describe "relations" do
    describe "can be created" do
      it "outgoing" do
        is_related?(@entity1, @entity2).must_equal false
        client.post "/v1/entities/#{@entity1}/develops/#{@entity2}"
        is_related?(@entity1, @entity2).must_equal true
        is_related?(@entity2, @entity1).must_equal false
      end

      it "incoming" do
        is_related?(@entity1, @entity2).must_equal false
        client.post "/v1/entities/#{@entity1}/develops/#{@entity2}", {}, JSON.dump(direction: 'incoming')
        is_related?(@entity1, @entity2).must_equal false
        is_related?(@entity2, @entity1).must_equal true
      end

      it "both ways" do
        is_related?(@entity1, @entity2).must_equal false
        client.post "/v1/entities/#{@entity1}/develops/#{@entity2}", {}, JSON.dump(direction: 'both')
        is_related?(@entity1, @entity2).must_equal true
        is_related?(@entity2, @entity1).must_equal true
      end
    end
  end
end
