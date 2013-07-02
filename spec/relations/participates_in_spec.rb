require_relative '../spec_helper.rb'

require 'uuid'

describe Graph::Backend::Relations::ParticipatesIn do
  before do
    @user = UUID.new.generate
    @match = UUID.new.generate
  end

  it "allows relations only when a player participates in a match" do
    validator = Graph::Backend::Relations::ParticipatesIn.new(@user, @match)
    validator.valid?.must_equal false

    Graph::Backend::Node.add_role(@user, 'player')
    validator.valid?.must_equal false

    Graph::Backend::Node.add_role(@match, 'turnbased-match')
    validator.valid?.must_equal true
  end
end