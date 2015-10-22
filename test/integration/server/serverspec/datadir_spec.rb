require 'spec_helper'

RSpec.describe 'postgres::server' do
  describe file('/var/pgsql/data94') do
    it { should be_directory }
  end
end
