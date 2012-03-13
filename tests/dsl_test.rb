require 'sinatra/base'
require 'minitest/autorun'
require 'pp'

$:.unshift File.join(File::dirname(__FILE__), '..')
require 'lib/sinatra/rabbit'

class Sample < Sinatra::Base
  include Sinatra::Rabbit

  collection :sample do

    collection :subsample do

      collection :secondsubsample do
        description "SecondSubCollection"
        operation :index do
          control do
            status 200
          end
        end

      end

      description "Subcollection"

      operation :index do
        control do
          status 200
        end
      end

      operation :start do
        control do
          status 200
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

    operation :show do
      description "TestIndex"
      param :id, :string, :required, "TestParam"
      control do
        status 200
      end
    end

    operation :create do
      description "TestIndex"
      param :id, :string, :required, "TestParam"
      control do
        status 200
      end
    end

    operation :destroy do
      description "TestIndex"
      param :id, :string, :required, "TestParam"
      control do
        status 200
      end
    end

    operation :stop do
      description "TestIndex"
      param :id, :string, :required, "TestParam"
      control do
        status 200
      end
    end

  end

  collection :second_sample do
    description "SecondTest"

    operation :index do
      description "SecondTestIndex"
      param :second_id, :string, :required, "TestSecondParam"
      control do
        status 200
      end
    end
  end

end

describe Sinatra::Rabbit::DSL do

  it "should have collection method" do
    Sample.respond_to?(:collection).must_equal true
  end

  it "should be Sinatra::Base class" do
    Sample.respond_to?(:configure).must_equal true
  end

end

describe Sinatra::Rabbit::Collection do

  it "should include SampleCollection and SecondSampleCollection" do
    Sample.collections.wont_be_empty
    Sample.collections.must_include Sinatra::Rabbit::SampleCollection
    Sample.collections.must_include Sinatra::Rabbit::SecondSampleCollection
  end

  it "should return SampleCollection using .collection method" do
    Sample.collection(:sample).must_equal Sinatra::Rabbit::SampleCollection
    Sample.collection(:non_existing_sample).must_be_nil
  end

  it "should allow to register new collection dynamically" do
    Sample.collection(:dynamic) do
      description 'DynamicTest'
      operation :index do
        control do
          status 200
        end
      end
    end
    Sample.collection(:dynamic).must_equal Sinatra::Rabbit::DynamicCollection
  end

  it "should return correct collection name" do
    Sample.collection(:sample).collection_name.must_equal :sample
    Sample.collection(:second_sample).collection_name.must_equal :second_sample
  end

  it "should have correct URI set" do
    Sample.collection(:sample).full_path.must_equal '/sample'
  end

  it "should return correct collection description" do
    Sample.collection(:sample).description.must_equal 'Test'
    Sample.collection(:second_sample).description.must_equal 'SecondTest'
  end

  it "should return operations and find index operation" do
    Sample.collection(:sample).operations.wont_be_empty
    Sample.collection(:sample).operations.must_include Sinatra::Rabbit::SampleCollection::IndexOperation
  end

  it "should allow to define subcollection" do
    Sample.collection(:sample).collections.wont_be_empty
    Sample.collection(:sample).collections.must_include Sinatra::Rabbit::SampleCollection::SubsampleCollection
  end

  it "should allow to retrieve subcollection from collection" do
    Sample.collection(:sample).collection(:subsample).must_equal Sinatra::Rabbit::SampleCollection::SubsampleCollection
  end

  it "should allow to retrieve subcollection parent collection" do
    Sample.collection(:sample).collection(:subsample).parent_collection.must_equal Sinatra::Rabbit::SampleCollection
  end

  it "should allow to get all operations defined for subcollection" do
    Sample.collection(:sample).collection(:subsample).operations.must_include Sinatra::Rabbit::SampleCollection::SubsampleCollection::IndexOperation
    Sample.collection(:sample).collection(:subsample).operations.must_include Sinatra::Rabbit::SampleCollection::SubsampleCollection::StartOperation
  end

  it "should have correct URI set for operations in subcollection" do
    Sample.collection(:sample).collection(:subsample).operation(:index).full_path.must_equal '/sample/subsample'
    Sample.collection(:sample).collection(:subsample).operation(:start).full_path.must_equal '/sample/subsample/:id/start'
  end

  it "should have correct URI set for subcollection" do
    Sample.collection(:sample).collection(:subsample).full_path.must_equal '/sample/subsample'
  end

  it "should allow to have deeper subcollections" do
    Sample.collection(:sample).collection(:subsample).collection(:secondsubsample).must_equal Sinatra::Rabbit::SampleCollection::SubsampleCollection::SecondsubsampleCollection
  end

end

describe Sinatra::Rabbit::Collection::Operation do

  it "should return :index operation" do
    Sample.collection(:sample).operation(:index).must_equal Sinatra::Rabbit::SampleCollection::IndexOperation
  end

  it "should return correct name" do
    Sample.collection(:sample).operation(:index).operation_name.must_equal :index
  end

  it "should return correct description" do
    Sample.collection(:sample).operation(:index).description.must_equal 'TestIndex'
  end

  it "should have :id param defined" do
    Sample.collection(:sample).operation(:index).param(:id).must_be_kind_of Sinatra::Rabbit::Param
    Sample.collection(:sample).operation(:index).param(:id).name.must_equal :id
  end

  it "should not return non-existing param" do
    Sample.collection(:sample).operation(:index).param(:non_existing).must_be_nil
  end

  it "should allow to add new param" do
    Sample.collection(:sample).operation(:index).param(:next_id, :string)
    Sample.collection(:sample).operation(:index).param(:next_id).must_be_kind_of Sinatra::Rabbit::Param
  end

  it "should return all params" do
    Sample.collection(:sample).operation(:index).params.wont_be_empty
  end

  it "should have control block" do
    Sample.collection(:sample).operation(:index).respond_to?(:control).must_equal true
  end

  it "should have correct path for index operation" do
    Sample.collection(:sample).operation(:index).full_path.must_equal '/sample'
  end

  it "should have correct path for create operation" do
    Sample.collection(:sample).operation(:create).full_path.must_equal '/sample'
  end

  it "should have correct path for show operation" do
    Sample.collection(:sample).operation(:show).full_path.must_equal '/sample/:id'
  end

  it "should have correct path for destroy operation" do
    Sample.collection(:sample).operation(:show).full_path.must_equal '/sample/:id'
  end

  it "should have correct path for stop operation" do
    Sample.collection(:sample).operation(:stop).full_path.must_equal '/sample/:id/stop'
  end

end
