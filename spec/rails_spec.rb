require File.dirname(__FILE__) + '/spec_helper'

describe Beaver do
  before do
    @beaver = Beaver.new(RAILS_LOGS)
    @beaver.parse
  end

  it "should count the number of created widgets" do
    dam = @beaver.hit :created_widget, :path => '/widgets', :method => :post
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should skip all of the created widgets" do
    dam = @beaver.hit :created_widget, :path => '/widgets', :method => :post do
      skip!
    end
    @beaver.filter
    dam.hits.size.should == 0
  end

  it "should only count the created widgets twice" do
    dam = @beaver.hit :created_widgets_1, :path => '/widgets', :method => :post
    dam = @beaver.hit :created_widgets_2, :path => '/widgets', :method => :post
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should only count the created widgets once" do
    dam = @beaver.hit :created_widgets_1, :path => '/widgets', :method => :post do
      final!
    end
    dam = @beaver.hit :created_widgets_2, :path => '/widgets', :method => :post
    @beaver.filter
    dam.hits.size.should == 0
  end

  it "should count the number of updated widgets" do
    dam = @beaver.hit :update_widget, :path => %r|^/widgets/\d+|, :method => :put
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should match on the controller and action" do
    dam = @beaver.hit :widgets_updated, :controller => 'WidgetsController', :action => 'update'
    @beaver.filter
    dam.hits.size.should == 2
  end

  it "should match on the controller and action" do
    dam = @beaver.hit :widgets_updated, :controller => /widgets/i, :action => /update/
    @beaver.filter
    dam.hits.size.should == 2
  end

  it "should match on the controller and action" do
    dam = @beaver.hit :widgets_updated, :controller => /widgets/i, :action => :update
    @beaver.filter
    dam.hits.size.should == 2
  end

  it "should match the request status" do
    dam = @beaver.hit :okay, :status => 200
    @beaver.filter
    dam.hits.size.should == 3
  end

  it "should match the request status range" do
    dam = @beaver.hit :okay, :status => (200..302)
    @beaver.filter
    dam.hits.size.should == 6
  end

  it "should capture all IP addresses" do
    dam = @beaver.hit :all
    @beaver.filter
    dam.ips.size.should == 3
  end

  it "should find the HTML responses" do
    dam = @beaver.hit :html, :format => :html
    @beaver.filter
    dam.hits.size.should == 5
  end

  it "should find the HTML and JSON responses" do
    dam = @beaver.hit :html, :format => [:html, :json]
    @beaver.filter
    dam.hits.size.should == 5
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

  it "should parse the response time" do
    dam = @beaver.hit :hash, :path => '/big_form', :method => :post
    @beaver.filter
    dam.hits.first.ms.should == 26
  end

  it "should find requests based on the response time" do
    dam = @beaver.hit :hash, :longer_than => 26, :shorter_than => 28
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should parse the request time" do
    dam = @beaver.hit :times, :method => :put
    @beaver.filter
    dam.hits.first.time.should == NormalizedTime.new(2011, 8, 30, 10, 7, 40, '-04:00')
  end

  it "should match before the request time" do
    dam = @beaver.hit :times, :before => Date.new(2011, 8, 1)
    @beaver.filter
    dam.hits.size.should == 2
  end

  it "should match after the request time" do
    dam = @beaver.hit :times, :after => NormalizedTime.new(2011, 8, 1, 0, 0, 0)
    @beaver.filter
    dam.hits.size.should == 4
  end

  it "should match on the request time" do
    dam = @beaver.hit :times, :on => Date.new(2011, 8, 30)
    @beaver.filter
    dam.hits.size.should == 2
  end

  it "should match against the entire request" do
    dam = @beaver.hit :db_hits, :match => /ActiveRecord: \d/
    @beaver.filter
    dam.hits.size.should == 3
  end
end
