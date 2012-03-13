require 'rubygems'
require 'sinatra/base'

$:.unshift File.join(File::dirname(__FILE__), '..', '..', 'lib')
require 'sinatra/rabbit'

############## EXAMPLE #################


class Example < Sinatra::Base

  include Sinatra::Rabbit

  configure do
    enable :logging
  end

  collection :images do
    description "Images description"

    operation :index, :if => (1 == 2) do
      description "Index operation description"
      control do
        status 200
        "Hello from index operation"
      end
    end

    operation :show do
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
