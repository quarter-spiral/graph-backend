require_relative '../request_spec_helper.rb'

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

  describe "authenticated" do
    before do
      AuthenticationInjector.token = token
    end

    after do
      AuthenticationInjector.reset!
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
  end
end
