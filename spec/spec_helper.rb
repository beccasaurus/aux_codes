require File.dirname(__FILE__) + '/../lib/aux_codes'
require 'spec'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
CreateAuxCodes.verbose = false
CreateAuxCodes.migrate :up

# use transactions
AuxCode; # hit one of the AR classes
Spec::Runner.configure do |config|
  config.before(:each) do
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
  end
  config.after(:each) do
    if ActiveRecord::Base.connection.open_transactions != 0
      ActiveRecord::Base.connection.rollback_db_transaction
      ActiveRecord::Base.connection.decrement_open_transactions
    end
  end
end
