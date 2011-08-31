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
end
