describe Sinatra::Rabbit::Param do

  def index_operation
    Sample.collection(:sample).operation(:rindex)
  end

  it "should return string representation of param" do
    "#{index_operation.param(:r_string)}".must_equal 'r_string:string:required'
  end

  it "should allow define required string param with description" do
    index_operation.param(:r_string).wont_be_nil
    index_operation.param(:r_string).description.must_equal 'TestParam'
    index_operation.param(:r_string).klass.must_equal :string
    index_operation.param(:r_string).values
    index_operation.param(:r_string).required?.must_equal true
    index_operation.param(:r_string).string?.must_equal true
    index_operation.param(:r_string).optional?.must_equal false
    index_operation.param(:r_string).enum?.must_equal false
    index_operation.param(:r_string).number?.must_equal false
  end

  it "should allow define optional string param with description" do
    index_operation.param(:o_string).wont_be_nil
    index_operation.param(:o_string).description.must_equal 'TestParam'
    index_operation.param(:o_string).klass.must_equal :string
    index_operation.param(:o_string).values
    index_operation.param(:o_string).required?.must_equal false
    index_operation.param(:o_string).string?.must_equal true
    index_operation.param(:o_string).optional?.must_equal true
    index_operation.param(:o_string).enum?.must_equal false
    index_operation.param(:o_string).number?.must_equal false
  end

  it "should allow define required number param with description" do
    index_operation.param(:r_number).wont_be_nil
    index_operation.param(:r_number).description.must_equal 'TestParam'
    index_operation.param(:r_number).klass.must_equal :number
    index_operation.param(:r_number).values
    index_operation.param(:r_number).required?.must_equal true
    index_operation.param(:r_number).string?.must_equal false
    index_operation.param(:r_number).optional?.must_equal false
    index_operation.param(:r_number).enum?.must_equal false
    index_operation.param(:r_number).number?.must_equal true
  end

  it "should allow define optional number param with description" do
    index_operation.param(:o_number).wont_be_nil
    index_operation.param(:o_number).description.must_equal 'TestParam'
    index_operation.param(:o_number).klass.must_equal :number
    index_operation.param(:o_number).required?.must_equal false
    index_operation.param(:o_number).string?.must_equal false
    index_operation.param(:o_number).optional?.must_equal true
    index_operation.param(:o_number).enum?.must_equal false
    index_operation.param(:o_number).number?.must_equal true
  end

  it "should allow define param just by name and type" do
    index_operation.param(:free_param).wont_be_nil
    index_operation.param(:free_param).description.must_equal 'Description not available'
    index_operation.param(:free_param).klass.must_equal :string
    index_operation.param(:free_param).values.must_be_nil
    index_operation.param(:free_param).required?.must_equal false
    index_operation.param(:free_param).string?.must_equal true
    index_operation.param(:free_param).optional?.must_equal true
    index_operation.param(:free_param).enum?.must_equal false
    index_operation.param(:free_param).number?.must_equal false
  end

  it "should allow to define optional enum param" do
    index_operation.param(:enum_param).wont_be_nil
    index_operation.param(:enum_param).description.must_equal 'Description not available'
    index_operation.param(:enum_param).klass.must_equal :enum
    index_operation.param(:enum_param).values.wont_be_empty
    index_operation.param(:enum_param).values.must_include 2
    index_operation.param(:enum_param).required?.must_equal false
    index_operation.param(:enum_param).string?.must_equal false
    index_operation.param(:enum_param).optional?.must_equal true
    index_operation.param(:enum_param).enum?.must_equal true
    index_operation.param(:enum_param).number?.must_equal false
  end

  it "should allow to define required enum param" do
    index_operation.param(:r_enum_param).wont_be_nil
    #index_operation.param(:r_enum_param).description.must_equal 'Description not available'
    index_operation.param(:r_enum_param).klass.must_equal :enum
    #index_operation.param(:r_enum_param).values.wont_be_empty
    #index_operation.param(:r_enum_param).values.must_include 2
    index_operation.param(:r_enum_param).required?.must_equal true
    index_operation.param(:r_enum_param).string?.must_equal false
    index_operation.param(:r_enum_param).optional?.must_equal false
    #index_operation.param(:r_enum_param).enum?.must_equal true
    index_operation.param(:r_enum_param).number?.must_equal false
  end

end
