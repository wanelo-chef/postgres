require 'spec_helper'

RSpec.describe 'postgres::server' do
  describe service('postgres945') do
    it { should be_running }
  end
end
