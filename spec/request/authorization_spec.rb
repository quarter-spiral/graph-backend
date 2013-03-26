require_relative '../request_spec_helper.rb'

describe "Authorization of Graph::Backend::API" do
  before do
    @uuid = OAUTH_USER['uuid']
    @uuid2 = UUID.new.generate

    Graph::Backend::Relation::RELATIONSHIP_TYPES << 'test_relates'
    Graph::Backend::Relations::TestRelates.always_valid(true)
  end

  after do
    Graph::Backend::Relation::RELATIONSHIP_TYPES.delete 'test_relates'
    Graph::Backend::Relations::TestRelates.reset!
    Graph::Backend::Node.delete(@uuid)
    Graph::Backend::Node.delete(@uuid2)
  end

  it "can't access the api unauthenticated" do
    client.post("/v1/entities/#{@uuid}/roles/developer").status.must_equal 403
    client.get("/v1/entities/#{@uuid}/roles").status.must_equal 403
    client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}").status.must_equal 403
    client.get("/v1/entities/#{@uuid}/test_relates").status.must_equal 403
    client.delete("/v1/entities/#{@uuid}/roles/developer").status.must_equal 403
  end

  describe "authenticated as a user" do
    before do
      AuthenticationInjector.token = token
    end

    after do
      AuthenticationInjector.reset!
    end

    it "can delete own node" do
      client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}", {"Authorization" => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      is_related?(@uuid, @uuid2).must_equal true
      client.delete("/v1/entities/#{@uuid}").status.must_equal 200
      is_related?(@uuid, @uuid2).must_equal false
    end

    it "cannot delete any other node" do
      client.post("/v1/entities/#{@uuid2}/test_relates/#{@uuid}", {"Authorization" => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      is_related?(@uuid2, @uuid1).must_equal true
      client.delete("/v1/entities/#{@uuid2}").status.must_equal 403
      is_related?(@uuid2, @uuid1).must_equal true
    end

    it "cannot list all entities with a role" do
      client.post("/v1/entities/#{@uuid2}/roles/developer", {"Authorization" => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      response = client.get("/v1/roles/developer")
      response.status.must_equal 403
    end

    it "can add roles to yourself" do
      has_role?(@uuid, 'developer').must_equal false
      client.post("/v1/entities/#{@uuid}/roles/developer").status.must_equal 201
      has_role?(@uuid, 'developer').must_equal true
    end

    it "cannot add roles to anyone else" do
      has_role?(@uuid2, 'developer').must_equal false
      client.post("/v1/entities/#{@uuid2}/roles/developer").status.wont_equal 201
      has_role?(@uuid2, 'developer').must_equal false
    end

    it "can get the roles of yourself" do
      client.post("/v1/entities/#{@uuid}/roles/developer").status.must_equal 201
      response = client.get("/v1/entities/#{@uuid}/roles")
      response.status.must_equal 200
      roles = JSON.parse(response.body)
      roles.size.must_equal 1
      roles.must_include 'developer'
    end

    it "cannot get the roles of anyone else" do
      client.post("/v1/entities/#{@uuid2}/roles/developer", {"Authorization" => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      response = client.get("/v1/entities/#{@uuid2}/roles")
      response.status.wont_equal 200
      JSON.parse(response.body).kind_of?(Array).wont_equal true
    end

    it "can remove a role of yourself" do
      client.post("/v1/entities/#{@uuid}/roles/developer").status.must_equal 201
      has_role?(@uuid, 'developer').must_equal true
      client.delete("/v1/entities/#{@uuid}/roles/developer").status.must_equal 200
      has_role?(@uuid, 'developer').must_equal false
    end

    it "cannot remove a role of anyone else" do
      client.post("/v1/entities/#{@uuid2}/roles/developer", {"Authorization" => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      has_role?(@uuid2, 'developer').must_equal true
      client.delete("/v1/entities/#{@uuid2}/roles/developer").status.wont_equal 200
      has_role?(@uuid2, 'developer').must_equal true
    end

    it "cannot relate to anything" do
      is_related?(@uuid, @uuid2).must_equal false
      client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}").status.must_equal 403
      is_related?(@uuid, @uuid2).must_equal false
    end

    it "cannot remove any existing relationship" do
      client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}", {'Authorization' => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      is_related?(@uuid, @uuid2).must_equal true
      client.delete("/v1/entities/#{@uuid}/test_relates/#{@uuid2}").status.must_equal 403
      is_related?(@uuid, @uuid2).must_equal true
    end

    it "can get related entities of yourself" do
      client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}", {'Authorization' => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      response = client.get("/v1/entities/#{@uuid}/test_relates")
      response.status.must_equal 200
      relations = JSON.parse(response.body)
      relations.size.must_equal 1
      relations.select {|r| r['source'] == @uuid && r['target'] == @uuid2}.wont_be_empty
    end

    it "cannot get related entities of anyone" do
      client.post("/v1/entities/#{@uuid2}/test_relates/#{@uuid}", {'Authorization' => "Bearer #{APP_TOKEN}"}).status.must_equal 201

      response = client.get("/v1/entities/#{@uuid2}/test_relates")
      response.status.must_equal 403
    end

    it "cannot query a thing" do
      client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}", {'Authorization' => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      query = CGI.escape("MATCH node0-[:test_relates]->thing RETURN thing.uuid")
      response = client.get("/v1/query/#{@uuid}?query=#{query}")
      response.status.must_equal 403
      things = JSON.parse(response.body)
      things.kind_of?(Array).must_equal(false)
    end
  end

  describe "authenticated with system privileges" do
    before do
      AuthenticationInjector.token = APP_TOKEN
    end

    after do
      AuthenticationInjector.reset!
    end

    it "can list all entities with a role" do
      client.post("/v1/entities/#{@uuid2}/roles/developer").status.must_equal 201
      response = client.get("/v1/roles/developer")
      response.status.must_equal 200
      entities = JSON.parse(response.body)
      entities.must_include @uuid2
    end

    it "can add roles to anyone else" do
      has_role?(@uuid2, 'developer').must_equal false
      client.post("/v1/entities/#{@uuid2}/roles/developer").status.must_equal 201
      has_role?(@uuid2, 'developer').must_equal true
    end

    it "can get the roles of anyone else" do
      client.post("/v1/entities/#{@uuid2}/roles/developer").status.must_equal 201
      response = client.get("/v1/entities/#{@uuid2}/roles")
      response.status.must_equal 200
      roles = JSON.parse(response.body)
      roles.size.must_equal 1
      roles.must_include 'developer'
    end

    it "can remove a role of anyone else" do
      client.post("/v1/entities/#{@uuid2}/roles/developer").status.must_equal 201
      has_role?(@uuid2, 'developer').must_equal true
      client.delete("/v1/entities/#{@uuid2}/roles/developer").status.must_equal 200
      has_role?(@uuid2, 'developer').must_equal false
    end

    it "can relate to anything" do
      is_related?(@uuid, @uuid2).must_equal false
      client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}").status.must_equal 201
      is_related?(@uuid, @uuid2).must_equal true
    end

    it "can remove any existing relationship" do
      client.post("/v1/entities/#{@uuid}/test_relates/#{@uuid2}").status.must_equal 201
      is_related?(@uuid, @uuid2).must_equal true
      client.delete("/v1/entities/#{@uuid}/test_relates/#{@uuid2}").status.must_equal 200
      is_related?(@uuid, @uuid2).must_equal false
    end

    it "can get related entities of anyone" do
      client.post("/v1/entities/#{@uuid2}/test_relates/#{@uuid}").status.must_equal 201

      response = client.get("/v1/entities/#{@uuid2}/test_relates")
      response.status.must_equal 200
      relations = JSON.parse(response.body)
      relations.size.must_equal 1
      relations.select {|r| r['source'] == @uuid2 && r['target'] == @uuid}.wont_be_empty
    end

    it "can query everything" do
      client.post("/v1/entities/#{@uuid2}/test_relates/#{@uuid}", {'Authorization' => "Bearer #{APP_TOKEN}"}).status.must_equal 201
      query = CGI.escape("MATCH node0-[:test_relates]->thing RETURN thing.uuid")
      response = client.get("/v1/query/#{@uuid2}?query=#{query}")
      response.status.must_equal 200
      things = JSON.parse(response.body)
      things.size.must_equal 1
      things.must_include [@uuid]
    end
  end
end
