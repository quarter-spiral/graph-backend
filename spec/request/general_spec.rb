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

  it "can't access the api unauthenticated" do
    client.post("/v1/entities/#{@entity1}/roles/developer").status.must_equal 403
    client.get("/v1/entities/#{@entity1}/roles").status.must_equal 403
    client.post("/v1/entities/#{@entity1}/test_relates/#{@entity2}").status.must_equal 403
    client.get("/v1/entities/#{@entity1}/test_relates").status.must_equal 403
    client.delete("/v1/entities/#{@entity1}/roles/developer").status.must_equal 403
  end
end
