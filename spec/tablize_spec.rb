require File.dirname(__FILE__) + '/spec_helper'

describe Beaver do
  before do
    @beaver = Beaver.new(RAILS_LOGS)
    @beaver.parse
  end

  context 'tablize' do
    it "should create a table of hits" do
      dam = @beaver.hit :widgets_updated, :controller => 'WidgetsController', :action => 'update'
      @beaver.filter
      table = dam.tablize(' | ') do |hit|
        [hit.path, hit.ip]
      end
      table.should == ['/widgets/2 | 216.84.130.30', '/big_form  | 216.84.130.30']
    end
  end
end
