require File.dirname(__FILE__) + '/spec_helper'

describe Beaver do
  before do
    @beaver = Beaver.new(HTTP_LOGS)
    @beaver.parse
  end

  it "should NOT parse and match the controller (Rails-only)" do
    dam = @beaver.hit :someone, :controller => 'foo'
    @beaver.filter
    dam.hits.size.should == 0
  end

  it "should parse and match the path" do
    dam = @beaver.hit :favicon, :path => '/favicon.ico'
    @beaver.filter
    dam.hits.size.should == 6
  end

  it "should parse and match the method" do
    dam = @beaver.hit :posts, :method => :post
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should parse and match the response status" do
    dam = @beaver.hit :posts, :status => 400
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should parse and match the IP" do
    dam = @beaver.hit :someone, :ip => '209.134.64.206'
    @beaver.filter
    dam.hits.size.should == 4
  end

  it "should parse and match the response size (in bytes)" do
    dam = @beaver.hit :favicon, :size => 776
    @beaver.filter
    dam.hits.size.should == 6
  end

  it "should parse and match responses less than n bytes" do
    dam = @beaver.hit :favicon, :smaller_than => 777
    @beaver.filter
    dam.hits.size.should == 11
  end

  it "should parse and match responses larger than n bytes" do
    dam = @beaver.hit :favicon, :larger_than => 776
    @beaver.filter
    dam.hits.size.should == 15
  end

  it "should parse the date" do
    dam = @beaver.hit :date, :after => Date.new(2012, 6, 19)
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should parse the datetime" do
    dam = @beaver.hit :datetime, :before => Time.now + 40000
    @beaver.filter
    dam.hits.size.should == 26
  end

  it "should parse the URL params string" do
    dam = @beaver.hit :faz, :params_str => /foo=bar/
    @beaver.filter
    dam.hits.size.should == 1
  end

  it "should parse the referer [sic]" do
    dam = @beaver.hit :from_blog, :referer => /jordanhollinger\.com/
    @beaver.filter
    dam.hits.size.should == 9
  end

  it "should parse the user agent string" do
    dam = @beaver.hit :from_blog, :user_agent => /Googlebot/
    @beaver.filter
    dam.hits.size.should == 1
  end
end
