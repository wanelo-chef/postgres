require 'spec_helper'

RSpec.describe 'postgres::server' do
  describe service('postgres945') do
    it { should be_running }
  end

  describe 'data directory configuration' do
    it 'uses the correct data directory' do
      postgres_arguments = `ptree postgres | grep postgres | head -1 | sed -e 's/^[ ]*//' | cut -d' ' -f2-`
      expect(postgres_arguments).to match('-D /var/pgsql/data94')
    end
  end
end
