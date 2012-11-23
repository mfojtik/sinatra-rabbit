require 'rack/test'
require 'nokogiri'

include Rack::Test::Methods

def app
  Sample
end

def status
  last_response.status
end

def html
  Nokogiri::HTML(last_response.body)
end

describe 'Documentation' do

  it "should respond with status OK for root" do
    get '/docs'
    status.must_equal 200
  end

  it "should return list of collections in entrypoint" do
    get '/docs'
    html.css('html body h1').text.must_equal 'Sample'
    html.css('html body ul li').wont_be_empty
    html.css('html body ul li a').wont_be_empty
  end

  it "should return valid collection name when query collection documentation" do
    get '/docs/sample'
    html.css('html body h1').text.must_equal 'Sample'
  end

  it "should return valid collection description when query collection documentation" do
    get '/docs/sample'
    html.css('html body blockquote p').text.strip.must_equal 'Test'
  end

  it "should return list of features when query collection documentation" do
    get '/docs/sample'
    html.css('html body .features .feature').map { |f| f.text.strip}.must_include 'user_data', 'user_name'
  end

  it "should return complete list of operations when query collection documentation" do
    get '/docs/sample'
    html.css('html body .operations tr').size.must_equal 6
  end

  it "should provide valid links from entrypoint to collection" do
    get '/docs'
    html.css('html body ul li a').each do |a|
      get a[:href]
      last_response.status.must_equal 200
    end
  end

  it "should provide valid links from collection to an operation" do
    get '/docs/sample'
    html.css('html body .operations tbody .name a').each do |a|
      get a[:href]
      last_response.status.must_equal 200
    end
  end

end
