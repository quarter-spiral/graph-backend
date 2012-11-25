require_relative '../request_spec_helper.rb'

def query(uuids, query)
  uuids = Array(uuids)
  url = (["/v1/query"] + uuids).join('/')
  response = client.get(url, {}, JSON.dump(query: query))
  JSON.parse(response.body)
end

def plays(player, game, venue)
  meta = {"venue#{venue.gsub(/^(.?)/) {|c| c.upcase}}" => true}
  relates(player, 'plays', game, meta)
end

def friends(player1, player2)
  relates(player1, 'friends', player2)
end

def develops(developer, game)
  relates(developer, 'develops', game)
end

def relates(uuid1, relation, uuid2, meta = nil)
  url = "/v1/entities/#{uuid1}/#{relation}/#{uuid2}"

  response = meta ? client.post(url, {}, JSON.dump(meta: meta)) : client.post(url)
  response.status.must_equal 201
end

describe Graph::Backend::API do
  before do
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

      @player1 = UUID.new.generate
      client.post "/v1/entities/#{@player1}/roles/player"
      @player2 = UUID.new.generate
      client.post "/v1/entities/#{@player2}/roles/player"
      @player3 = UUID.new.generate
      client.post "/v1/entities/#{@player3}/roles/player"
      @player4 = UUID.new.generate
      client.post "/v1/entities/#{@player4}/roles/player"
      @player5 = UUID.new.generate
      client.post "/v1/entities/#{@player5}/roles/player"
      @player6 = UUID.new.generate
      client.post "/v1/entities/#{@player6}/roles/player"
    end

    after do
      AuthenticationInjector.reset!
    end

    describe "queries" do
      before do
        @game1 = UUID.new.generate
        client.post "/v1/entities/#{@game1}/roles/game"
        @game2 = UUID.new.generate
        client.post "/v1/entities/#{@game2}/roles/game"
        @game3 = UUID.new.generate
        client.post "/v1/entities/#{@game3}/roles/game"

        plays(@player1, @game1, 'facebook')
        plays(@player2, @game1, 'facebook')
        plays(@player3, @game1, 'spiralGalaxy')
        plays(@player2, @game2, 'spiralGalaxy')
        plays(@player3, @game2, 'facebook')
        plays(@player4, @game1, 'facebook')
        plays(@player5, @game1, 'facebook')
        plays(@player5, @game3, 'facebook')
        plays(@player6, @game2, 'facebook')

        friends(@player1, @player2)
        friends(@player1, @player3)
        friends(@player1, @player4)
        friends(@player1, @player6)
      end

      it "can query for friends of a player that plays a given game on a given venue" do

        friends = query([@player1, @game1], "MATCH node0-[:friends]->friend-[p:plays]->game WHERE game = node1 AND p.venueFacebook! = true RETURN DISTINCT friend.uuid")

        friends.size.must_equal(2)
        friends.must_include [@player2]
        friends.must_include [@player4]
      end

      it "can query for developers of games my friends play on facebook" do
        @developer1 = UUID.new.generate
        client.post "/v1/entities/#{@developer1}/roles/developer"
        @developer2 = UUID.new.generate
        client.post "/v1/entities/#{@developer2}/roles/developer"
        @developer3 = UUID.new.generate
        client.post "/v1/entities/#{@developer3}/roles/developer"

        develops(@developer1, @game1)
        develops(@developer1, @game3)
        develops(@developer2, @game1)
        develops(@developer2, @game2)
        develops(@developer3, @game3)

        developers = query(@player1, "MATCH node0-[:friends]->()-[p:plays]->()<-[:develops]->developer WHERE p.venueFacebook! = true RETURN DISTINCT developer.uuid")
        developers.size.must_equal 2
        developers.must_include [@developer1]
        developers.must_include [@developer2]
      end
    end
  end
end
