require_relative '../request_spec_helper.rb'

def find_in_relationships(relationships, uuid)
  relationships.detect {|relationship| relationship['target'] == uuid}
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

  describe "authenticated" do
    before do
      AuthenticationInjector.token = token
    end

    after do
      AuthenticationInjector.reset!
    end

    describe "relations" do
      describe "can be created" do
        it "outgoing" do
          is_related?(@entity1, @entity2).must_equal false
          response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
          JSON.parse(response.body).must_equal([{"source" => @entity1, "target" => @entity2, "relation" => "test_relates", "meta" => {}}])

          is_related?(@entity1, @entity2).must_equal true
          is_related?(@entity2, @entity1).must_equal false
        end

        it "incoming" do
          is_related?(@entity1, @entity2).must_equal false
          response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'incoming')
          JSON.parse(response.body).must_equal([{"source" => @entity2, "target" => @entity1, "relation" => "test_relates", "meta" => {}}])

          is_related?(@entity1, @entity2).must_equal false
          is_related?(@entity2, @entity1).must_equal true
        end

        it "both ways" do
          is_related?(@entity1, @entity2).must_equal false
          response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'both')
          relations = JSON.parse(response.body)
          relations.size.must_equal 2
          relations.must_include("source" => @entity1, "target" => @entity2, "relation" => "test_relates", "meta" => {})
          relations.must_include("source" => @entity2, "target" => @entity1, "relation" => "test_relates", "meta" => {})

          is_related?(@entity1, @entity2).must_equal true
          is_related?(@entity2, @entity1).must_equal true
        end

        it "doesn't create them twice" do
          response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
          response.status.must_equal 201
          response = client.post "/v1/entities/#{@entity2}/test_relates/#{@entity1}", {}, JSON.dump(direction: 'incoming')
          response.status.must_equal 304
        end
      end

      it "can be checked and retrieved" do
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        response = client.get "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        JSON.parse(response.body).must_equal("source" => @entity1, "target" => @entity2, "relation" => "test_relates", "meta" => {})
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

      it "deletes all duplicate relations in one go" do
        5.times do
          client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'both')
        end
        is_related?(@entity1, @entity2).must_equal true
        is_related?(@entity2, @entity1).must_equal true

        client.delete "/v1/entities/#{@entity1}/test_relates/#{@entity2}"

        is_related?(@entity1, @entity2).must_equal false
        is_related?(@entity2, @entity1).must_equal true
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
        find_in_relationships(games_of_entity_1, @entity2).wont_be_nil
        find_in_relationships(games_of_entity_1, @entity3).wont_be_nil

        games_of_entity_2 = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates").body)
        find_in_relationships(games_of_entity_2, @entity1).wont_be_nil
        find_in_relationships(games_of_entity_2, @entity4).wont_be_nil

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

        relations = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates", {}, JSON.dump(direction: 'incoming')).body)
        find_in_relationships(relations, @entity1).wont_be_nil
        find_in_relationships(relations, @entity2).must_be_nil
        find_in_relationships(relations, @entity3).wont_be_nil
        find_in_relationships(relations, @entity4).must_be_nil

        relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates", {}, JSON.dump(direction: 'incoming')).body)
        relations.size.must_equal 1
        find_in_relationships(relations, @entity4).wont_be_nil
      end

      it "can list two way related entities" do
        @entity3 = UUID.new.generate
        @entity4 = UUID.new.generate

        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        client.post "/v1/entities/#{@entity3}/test_relates/#{@entity2}"
        client.post "/v1/entities/#{@entity4}/test_relates/#{@entity1}"

        relations = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates", {}, JSON.dump(direction: 'both')).body)
        find_in_relationships(relations, @entity1).wont_be_nil
        find_in_relationships(relations, @entity2).must_be_nil
        find_in_relationships(relations, @entity3).wont_be_nil
        find_in_relationships(relations, @entity4).must_be_nil

        relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates", {}, JSON.dump(direction: 'both')).body)
        find_in_relationships(relations, @entity1).must_be_nil
        find_in_relationships(relations, @entity2).wont_be_nil
        find_in_relationships(relations, @entity3).must_be_nil
        find_in_relationships(relations, @entity4).wont_be_nil
      end

      it "can have meta information" do
        @entity3 = UUID.new.generate
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(meta: {some: 123, attribute: "yeah"})
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity3}", {}, JSON.dump(meta: {some: "bla", attribute: 456})

        relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates").body)
        relations.size.must_equal 2
        entity2_relation = find_in_relationships(relations, @entity2)
        entity2_relation['meta'].must_equal("some" => 123, "attribute" => "yeah")
        entity3_relation = find_in_relationships(relations, @entity3)
        entity3_relation['meta'].must_equal("some" => "bla", "attribute" => 456)
      end

      it "meta information will be merged when posting twice" do
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(meta: {some: 123, venueFacebook: true})
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(meta: {bla: "456", venueFacebook: false})

        relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates").body)
        relations.size.must_equal 1
        entity2_relation = find_in_relationships(relations, @entity2)
        entity2_relation['meta'].must_equal("some" => 123, "bla" => "456", "venueFacebook" => false)
      end

      it "responds with 404 when changing a non-existent relation" do
        response = client.put "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(meta: {yo: 123})
        response.status.must_equal 404

        response = client.get "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        response.status.must_equal 404
      end

      it "can update the meta information" do
        response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(direction: 'both', meta: {some: 123, venueFacebook: true})
        relations = JSON.parse(response.body)
        relations.size.must_equal 2
        relations.each {|r| r['meta'].must_equal "some" => 123, "venueFacebook" => true}

        response = client.put "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump(meta: {some: "bla"})
        relations = JSON.parse(response.body)
        relations.size.must_equal 1
        relations.first["meta"].must_equal "some" => "bla"

        response = client.get "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        relation = JSON.parse(response.body)
        relation['meta'].must_equal "some" => "bla"

        response = client.get "/v1/entities/#{@entity2}/test_relates/#{@entity1}"
        relation = JSON.parse(response.body)
        relation['meta'].must_equal "some" => 123, "venueFacebook" => true
      end

      it "can remove nodes with all it's relations" do
        @entity3 = UUID.new.generate
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
        client.post "/v1/entities/#{@entity1}/test_relates/#{@entity3}", {}, JSON.dump(direction: 'both')

        relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates", {}, JSON.dump(direction: 'both')).body)
        find_in_relationships(relations, @entity2).wont_be_nil
        find_in_relationships(relations, @entity3).wont_be_nil

        relations = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates", {}, JSON.dump(direction: 'both')).body)
        find_in_relationships(relations, @entity1).wont_be_nil

        relations = JSON.parse(client.get("/v1/entities/#{@entity3}/test_relates", {}, JSON.dump(direction: 'both')).body)
        find_in_relationships(relations, @entity1).wont_be_nil

        client.delete "/v1/entities/#{@entity1}"

        relations = JSON.parse(client.get("/v1/entities/#{@entity1}/test_relates", {}, JSON.dump(direction: 'both')).body)
        relations.empty?.must_equal true

        relations = JSON.parse(client.get("/v1/entities/#{@entity2}/test_relates", {}, JSON.dump(direction: 'both')).body)
        find_in_relationships(relations, @entity1).must_be_nil

        relations = JSON.parse(client.get("/v1/entities/#{@entity3}/test_relates", {}, JSON.dump(direction: 'both')).body)
        find_in_relationships(relations, @entity1).must_be_nil
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

          response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump({direction: 'incoming'})
          response.status.wont_equal 201

          Graph::Backend::Relations::TestRelates.valid(@entity2, @entity1)
          response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump({direction: 'incoming'})
          response.status.must_equal 201

          client.delete "/v1/entities/#{@entity1}/test_relates/#{@entity2}"
          client.delete "/v1/entities/#{@entity2}/test_relates/#{@entity1}"

          response = client.post "/v1/entities/#{@entity1}/test_relates/#{@entity2}", {}, JSON.dump({direction: 'both'})
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

            client.post "/v1/entities/#{@entity1}/test_relates/#{@entity3}", {}, JSON.dump(direction: 'both')

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
end
