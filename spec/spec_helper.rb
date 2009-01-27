require File.dirname(__FILE__) + '/../lib/aux_codes'
require 'spec'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
CreateAuxCodes.verbose = false
CreateAuxCodes.migrate :up

# use transactions
AuxCode; # hit one of the AR classes
Spec::Runner.configure do |config|

  def begin_transaction
    Thread.current['open_transactions'] ||= 1
    ActiveRecord::Base.connection.begin_db_transaction
  end

  def rollback_transaction
    if Thread.current['open_transactions'] != 0
      ActiveRecord::Base.connection.rollback_db_transaction
      Thread.current['open_transactions'] = 0
    end
  end

  config.before(:each) { begin_transaction }
  config.after(:each) { rollback_transaction }

end
