require File.dirname(__FILE__) + '/../lib/aux_codes'
require 'spec'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
CreateAuxCodes.verbose = false
CreateAuxCodes.migrate :up

# use transactions
AuxCode; # hit one of the AR classes
Spec::Runner.configure do |config|
  config.before(:each) do
    ActiveRecord::Base.active_connections.values.uniq.each do |conn|
      Thread.current['open_transactions'] ||= 0
      Thread.current['open_transactions'] += 1
      conn.begin_db_transaction
    end
  end
  config.after(:each) do
    ActiveRecord::Base.active_connections.values.uniq.each do |conn|                  
      conn.rollback_db_transaction
      Thread.current['open_transactions'] = 0
    end
  end
end
