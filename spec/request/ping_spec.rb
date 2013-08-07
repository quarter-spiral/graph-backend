require 'json'

describe Graph::Backend::API do
  it "ping endpoint calls the graph" do
    response = client.get "/v1/public/__PING__"
    response.status.must_equal 200
    data = JSON.parse(response.body)
    data['root_id'].must_equal "0"
  end
end
