require_relative '../spec_helper.rb'

require 'uuid'

describe Graph::Backend::Relations::ParticipatesIn do
  before do
    @match = UUID.new.generate
    @game = UUID.new.generate
  end

  it "allows relations only when a player participates in a match" do
    validator = Graph::Backend::Relations::IsAMatchOf.new(@match, @game)
    validator.valid?.must_equal false

    Graph::Backend::Node.add_role(@match, 'turnbased-match')
    validator.valid?.must_equal false

    Graph::Backend::Node.add_role(@game, 'game')
    validator.valid?.must_equal true
  end
end

