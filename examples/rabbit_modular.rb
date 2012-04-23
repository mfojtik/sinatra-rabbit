require 'rubygems'
require 'sinatra/base'

$:.unshift File.join(File::dirname(__FILE__), '..', 'lib')
require 'sinatra/rabbit'

API_ROOT_URL = '/'

############## EXAMPLE #################

Sinatra::Rabbit.configure do
  enable :documentation
  enable :head_routes
  enable :options_routes
end

class Example < Sinatra::Base

  include Sinatra::Rabbit
  include Sinatra::Rabbit::Features

  features do

    feature :user_name, :for => :images do
      description 'Hello world'
      operation :show do
        param :name, :string, :optional, 'Hello parameter'
      end
    end

  end

  collection :instances do
    description "Instances description"

    operation :index do
      description "Index operation description"
      control do
        status 200
        "Hello from instances index operation"
      end
    end

    operation :show do
      description "Index operation description"
      param :id,  :string, :required, "Instance identifier"
      control do
        "Hey #{params[:id]}"
      end
    end
  end

  collection :images do
    description "Images description"

    operation :index do
      description "Index operation description"
      control do
        status 200
        "Hello from index operation"
      end
    end

    operation :destroy do
      description "Index operation description"
      control do
        status 200
        "Hello from index operation"
      end
    end

    operation :show, :with_capability => :test1 do
      description "Index operation description"
      param :id,  :string, :required
      param :r1,  :string, :optional, "Optional parameter"
      param :v1,  :string, :optional, [ 'test1', 'test2', 'test3' ], "Optional parameter"
      param :v2,  :string, :optional, "Optional parameter"
      control do
        "Hey #{params[:id]}"
      end
    end
  end

end

Example.run!
