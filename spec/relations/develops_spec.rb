require_relative '../spec_helper.rb'

require 'uuid'

describe Graph::Backend::Relations::Develops do
  before do
    @user = UUID.new.generate
    @game = UUID.new.generate
  end

  it "allows relations only when source is a developer" do
    validator = Graph::Backend::Relations::Develops.new(@user, @game)
    validator.valid?.must_equal false

    Graph::Backend::Node.add_role(@user, 'developer')
    validator.valid?.must_equal true
  end
end
