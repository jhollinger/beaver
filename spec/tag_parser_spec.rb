require File.dirname(__FILE__) + '/spec_helper'

describe Beaver do
  describe 'TagParser' do
    before do
      @dam = Beaver::Dam.new :test
    end

    a = 'tag1'
    it "should parse #{a}" do
      @dam.build(:tagged => a).instance_variable_get('@match_tags').should == ['tag1']
    end

    b = 'tag1, tag2'
    it "should parse #{b}" do
      @dam.build(:tagged => b).instance_variable_get('@match_tags').should == ['tag1', 'tag2']
    end

    c = ['tag1', 'tag2']
    it "should parse #{c}" do
      @dam.build(:tagged => c).instance_variable_get('@match_tags').should == c
    end

    d = ['tag1, tag2']
    it "should parse #{d}" do
      @dam.build(:tagged => d).instance_variable_get('@match_tags').should == [['tag1', 'tag2']]
    end

    e = ['tag1, tag2', ['tag3', 'tag4'], 'tag5']
    it "should parse #{e}" do
      @dam.build(:tagged => e).instance_variable_get('@match_tags').should == [['tag1', 'tag2'], ['tag3', 'tag4'], 'tag5']
    end
  end
end
