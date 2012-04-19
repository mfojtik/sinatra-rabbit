describe Sinatra::Rabbit::DSL do

  it "should allow to set configuration" do
    Sinatra::Rabbit.configure do
      enable :documentation
      enable :head_routes
      enable :options_routes
      disable :sample_setting
    end
    Sinatra::Rabbit.enabled?(:documentation).must_equal true
    Sinatra::Rabbit.disabled?(:documentation).must_equal false
    Sinatra::Rabbit.enabled?(:sample_setting).must_equal false
    Sinatra::Rabbit.disabled?(:sample_setting).must_equal true
  end

  it "should allow to set any property" do
    Sinatra::Rabbit.set(:test_property, '1')
    Sinatra::Rabbit.configuration[:test_property].must_equal '1'
  end

  it "should have collection method" do
    Sample.respond_to?(:collection).must_equal true
  end

  it "should be Sinatra::Base class" do
    Sample.respond_to?(:configure).must_equal true
  end

  it "should return list of all collections" do
    Sample.collections.wont_be_empty
    Sample.collections.size.must_equal 3
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

  it 'should return SampleCollection using [] method' do
    Sample[:sample].must_equal Sinatra::Rabbit::SampleCollection
    Sample[:non_existing_sample].must_be_nil
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

  it "should raise exception when contain control block" do
    lambda {
      Sample.collection(:raise) do
        description 'RaiseTest'
        control do
          status 200
        end
      end
    }.must_raise RuntimeError
  end

  it "should allow to return base class" do
    Sample.collection(:second_sample).base_class.must_equal Sample
    Sample.collection(:sample).collection(:subsample).base_class.must_equal Sample
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

  it "should return operation using [] syntax" do
    Sample[:sample][:index].must_equal Sinatra::Rabbit::SampleCollection::IndexOperation 
  end

  it "should return subcollection using [] syntax" do
    Sample[:sample][:subsample].must_equal Sinatra::Rabbit::SampleCollection::SubsampleCollection
  end

  it "should return operation from subcollection using the [] syntax" do
    Sample[:sample][:subsample][:start].must_equal Sinatra::Rabbit::SampleCollection::SubsampleCollection::StartOperation
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
    Sample.collection(:sample).collection(:subsample).operations.must_include Sinatra::Rabbit::SampleCollection::SubsampleCollection::ShowOperation
    Sample.collection(:sample).collection(:subsample).operations.must_include Sinatra::Rabbit::SampleCollection::SubsampleCollection::StartOperation
  end

  it "should have correct URI set for operations in subcollection" do
    Sample.collection(:sample).collection(:subsample).operation(:show).full_path.must_equal '/sample/:id/subsample/:sub_id'
    Sample.collection(:sample).collection(:subsample).operation(:start).full_path.must_equal '/sample/:id/subsample/:sub_id/start'
  end

  it "should have correct URI set for subcollection" do
    Sample.collection(:sample).collection(:subsample).full_path.must_equal '/sample/:id/subsample'
  end

  it "should allow to have deeper subcollections" do
    Sample.collection(:sample).collection(:subsample).collection(:secondsubsample).must_equal Sinatra::Rabbit::SampleCollection::SubsampleCollection::SecondsubsampleCollection
  end

end

describe Sinatra::Rabbit::Collection::Operation do

  it "should have the :restart action" do
    Sample.collection(:second_sample).operation(:restart).must_equal Sinatra::Rabbit::SecondSampleCollection::RestartOperation
    Sample.collection(:second_sample).operation(:restart).full_path.must_equal '/second_sample/:id/restart'
    Sample.collection(:second_sample).operation(:restart).http_method.must_equal :post
  end

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

describe Sinatra::Rabbit::Features do
  
  it "should allow to be defined for Sample collection" do
    Sample.features.wont_be_empty
    Sample.features.size.must_equal 3
  end

  it "should allow to be retrieved by name" do
    Sample.feature(:user_data).wont_be_nil
    Sample.feature(:user_data).name.must_equal :user_data
  end

  it "should allow to be defined more times" do
    Sample.feature(:user_name).wont_be_nil
    Sample.feature(:user_data).wont_be_nil
    Sample.feature(:non_existing_one).must_be_nil
  end

  it "should contain reference to collection" do
    Sample.feature(:user_data).collection.wont_be_nil
    Sample.feature(:user_data).collection.must_equal :sample
  end

  it "should contain array of operations" do
    Sample.feature(:user_data).operations.wont_be_empty
    Sample.feature(:user_data).operations.map {|o| o.class }.must_include Sinatra::Rabbit::Feature::Operation
  end

  it "should allow to return single operation by name" do
    Sample.feature(:user_data).operation(:index).wont_be_nil
    Sample.feature(:user_data).operation(:non_existing_one).must_be_nil
    Sample.feature(:user_data).operation(:index).name.must_equal :index
  end

  it "should be retrieved from collection" do
    Sample.collection(:sample).features.wont_be_nil
    Sample.collection(:sample).features.size.must_equal 2
    Sample.collection(:second_sample).features.size.must_equal 1
  end

  it "should add additionals parameters to given operations" do
    Sample.collection(:sample).operation(:index).params.map { |p| p.name }.must_include :feature_name
    Sample.collection(:sample).operation(:index).params.map { |p| p.name }.must_include :feature_data
    Sample.collection(:second_sample).operation(:index).params.map { |p| p.name }.must_include :feature_second
  end

  it "should not add additional parameters to other operations" do
    Sample.collection(:sample).operation(:show).params.map { |p| p.name }.wont_include :feature_name
  end

end
