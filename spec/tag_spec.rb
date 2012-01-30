require File.dirname(__FILE__) + '/spec_helper'

describe Beaver do
  describe 'Tags' do
    before do
      @beaver = Beaver.new(LOG_FILES)
      @beaver.parse
    end

    context 'simple matches' do
      it "should match against the request tags (using a string)" do
        dam = @beaver.hit :tags, :tagged => 'steve, bar'
        @beaver.filter
        dam.hits.size.should == 1
      end

      it "should match against the request tags (using an array)" do
        dam = @beaver.hit :tags, :tagged => %w[bar steve]
        @beaver.filter
        dam.hits.size.should == 1
      end

      it "should match against the request tags (using an array)" do
        dam = @beaver.hit :tags, :tagged => %w[bar]
        @beaver.filter
        dam.hits.size.should == 2
      end

      it "should match against the request tags (using string)" do
        dam = @beaver.hit :tags, :tagged => %w[foo]
        @beaver.filter
        dam.hits.size.should == 1
      end

      it "should find the correct tags" do
        dam = @beaver.hit :tags, :tagged => %w[steve]
        @beaver.filter
        dam.hits.first.tags.should == %w[steve bar]
      end

      it "should not match against the wrong request tag" do
        dam = @beaver.hit :tags, :tagged => %w[eve]
        @beaver.filter
        dam.hits.size.should == 0
      end

      it "should not match against the wrong request tags" do
        dam = @beaver.hit :tags, :tagged => %w[bar eve]
        @beaver.filter
        dam.hits.size.should == 0
      end
    end

    context 'deep matches' do
      it "should match" do
        dam = @beaver.hit :tags, :tagged => [['foo', 'bar']]
        @beaver.filter
        dam.hits.size.should == 1
      end

      it "should match" do
        dam = @beaver.hit :tags, :tagged => [['foo'], ['bar']]
        @beaver.filter
        dam.hits.size.should == 2
      end

      it "should match" do
        dam = @beaver.hit :tags, :tagged => [['foo', 'bar'], ['steve', 'bla']]
        @beaver.filter
        dam.hits.size.should == 1
      end

      it "should match" do
        dam = @beaver.hit :tags, :tagged => [['foo', 'bar'], ['steve', 'bar']]
        @beaver.filter
        dam.hits.size.should == 2
      end
    end
  end
end
