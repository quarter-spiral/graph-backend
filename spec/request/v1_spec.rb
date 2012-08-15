require_relative '../spec_helper.rb'

require 'json'
require 'uuid'
require 'rack/client'

include Graph::Backend
client = Rack::Client.new {run API}

describe Graph::Backend::API do
  before do
    @entity1 = UUID.new.generate
    @entity2 = UUID.new.generate
  end

  describe "roles" do
    it "can add roles to an entity" do
      JSON.parse(client.get("/v1/roles/developer").body).wont_include @entity1
      client.post "/v1/entities/#{@entity1}/roles/developer"
      JSON.parse(client.get("/v1/roles/developer").body).must_include @entity1
    end
  end
end
