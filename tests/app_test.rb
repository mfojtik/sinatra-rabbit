require 'rack/test'

include Rack::Test::Methods

def app
  Sample
end

def status
  last_response.status
end

describe Sample do

  it "should respond with status OK for root" do
    get '/'
    status.must_equal 200
  end

  it "should respond 400 to index operation for sample collection without param" do
    get '/sample'
    status.must_equal 400
  end

  it "should respond 200 to index operation for sample collection with param" do
    get '/sample', { :id => :sample }
    status.must_equal 200
  end

  it "should respond to OPTIONS request for sample collection" do
    options '/sample'
    status.must_equal 200
    allow_header = last_response.headers['Allow'].split(',')
    allow_header.wont_be_empty
    allow_header.must_include 'OPTIONS'
    allow_header.must_include 'GET'
    allow_header.must_include 'POST'
    allow_header.must_include 'DELETE'
    last_response.headers['Content-Length'].must_equal '0'
    last_response.body.must_be_empty
  end

  it "should respond 200 to HEAD request for index operation in sample collection" do
    head '/sample/index'
    status.must_equal 200
  end

  it "should respond to OPTIONS request for index operation in sample collection" do
    options '/sample/index'
    status.must_equal 200
    allow_header = last_response.headers['Allow'].split(',')
    allow_header.wont_be_empty
    allow_header.must_include 'feature_data:string:optional'
    allow_header.must_include 'id:string:required'
  end

  it "should respond 200 to show operation for sample collection" do
    get '/sample/100'
    status.must_equal 200
    last_response.body.must_equal '100'
  end

  it "should respond 201 to delete operation on sample collection" do
    delete '/sample/100'
    status.must_equal 201
  end

  it "should respond 200 to stop operation with condition routes" do
    get '/sample/100/stop'
    status.must_equal 200
  end

  it "should respond 200 to sample subcollection index operation" do
    get '/sample/10/subsample/20'
    status.must_equal 200
  end

  it "should raise an exception when posting data with unknown values" do
    post '/sample', { :id => '1', :arch => '3'}
    last_response.status.must_equal 400
    last_response.body.must_equal "Parameter 'arch' value '3' not found in list of allowed values [1,2]"
  end

end
