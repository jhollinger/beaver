require File.dirname(__FILE__) + '/spec_helper'

describe Beaver do
  before do
    @beaver = Beaver.new(LOG_FILES)
    @beaver.parse
  end

  it "should count the number of created widgets" do
    dam = @beaver.hit :created_widget, :path => '/widgets', :method => :post
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should count the number of updated widgets" do
    dam = @beaver.hit :update_widget, :path => %r|^/widgets/\d+|, :method => :put
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should capture all IP addresses" do
    dam = @beaver.hit :all
    @beaver.filter
    dam.ips.size.should == 2
  end

  it "should find requests based on the params string" do
    dam = @beaver.hit :with_params_str, :params_str => /"hi"=>"Hello"/
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should find requests based on the params hash matching against a string" do
    dam = @beaver.hit :with_params_str, :params => {:hi => 'Hello'}
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should find requests based on the params hash matching against a regex" do
    dam = @beaver.hit :with_params_str, :params => {:hi => /^hell/i}
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should parse params into a Hash" do
    dam = @beaver.hit :hash, :path => '/big_form', :method => :post
    @beaver.filter
    dam.hits.first.params.should == {:hi => "Hello", :boo => "Boo", :sub => {1 => 5, :eight => 8, 2=> 3, 7=>10}, :end => "The End", :a => ["1", "2", "3"], :"another end"=>"The End 2"}
  end
end
