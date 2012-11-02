require_relative '../spec_helper.rb'

require 'uuid'

describe Graph::Backend::Relations::Friends do
  before do
    @user1 = UUID.new.generate
    @user2 = UUID.new.generate
  end

  it "allows relations only when both ends are a player" do
    validator = Graph::Backend::Relations::Friends.new(@user1, @user2)
    validator.valid?.must_equal false

    Graph::Backend::Node.add_role(@user1, 'player')
    validator.valid?.must_equal false

    Graph::Backend::Node.add_role(@user2, 'player')
    validator.valid?.must_equal true
  end
end

