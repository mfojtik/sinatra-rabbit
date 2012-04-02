require 'rubygems'
begin
  require 'simplecov'
  if ENV['COVERAGE']
    SimpleCov.start
    SimpleCov.command_name 'Minitest Tests'
  end
rescue LoadError
end

require 'minitest/autorun'

require 'sinatra/base'
$:.unshift File.join(File::dirname(__FILE__), '..')
require 'lib/sinatra/rabbit'

class Sample < Sinatra::Base
  include Sinatra::Rabbit
  include Sinatra::Rabbit::Features

  get '/' do
    halt 200
  end

  features do
    feature :user_data, :for => :sample do
      operation :index do
        param :feature_data, :string
      end
    end
    feature :user_name, :for => :sample do
      operation :index do
        param :feature_name, :string
      end
    end
    feature :profile_sample, :for => :second_sample do
      operation :index do
        param :feature_second, :string
      end
    end
  end

  collection :sample do

    collection :subsample, :with_id => :sub_id do

      collection :secondsubsample do
        description "SecondSubCollection"
        operation :index do
          control do
            status 200
          end
        end

      end

      description "Subcollection"

      operation :start do
        param :id, :required
        control do
          status 200
        end
      end
      operation :show do
        control do
          params[:id]
        end
      end
    end

    description "Test"

    operation :index do
      description "TestIndex"
      param :id, :string, :required, "TestParam"
      control do
        status 200
      end
    end

    operation :rindex do
      description "TestIndex"
      param :r_string, :string, :required, "TestParam"
      param :o_string, :string, :optional, "TestParam"
      param :r_number, :number, :required, "TestParam"
      param :o_number, :number, :optional, "TestParam"
      param :free_param, :string
      param :enum_param, :enum, [1,2,3]
      param :r_enum_param, :enum, :required, [1,2,3]
      control {}
    end

    operation :show do
      description "TestIndex"
      control do
        [200, {}, params[:id]]
      end
    end

    operation :create do
      description "TestIndex"
      param :id, :string, :required, "TestParam"
      param :arch, :enum, [1, 2]
      control do
        status 200
      end
    end

    operation :destroy do
      description "TestIndex"
      control do
        status 201
      end
    end

    operation :stop, :if => (1==1) do
      description "TestIndex"
      param :id, :string, :required, "TestParam"
      control do
        status 200
      end
    end

  end

  collection :second_sample do
    description "SecondTest"

    action :restart do
      description "Action operation"
      param :id, :string, :required, "Test"
      control do
        status 200
      end
    end

    operation :index do
      description "SecondTestIndex"
      param :second_id, :string, :required, "TestSecondParam"
      control do
        status 200
      end
    end
  end

end


