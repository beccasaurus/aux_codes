#! /usr/bin/env ruby
require File.dirname(__FILE__) + '/lib/aux_codes'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'
AuxCodes::CreateAuxCodes.verbose = false
AuxCodes::CreateAuxCodes.migrate :up

require 'irb'

puts "Welcome to the AuxCode Testing Console"
puts ""
puts "enjoy!"
puts ""

IRB.start
