# This generator bootstraps aux_codes into a Rails application
class AuxCodesGenerator < Rails::Generator::Base

  def initialize(runtime_args, runtime_options = {})
    bootstrap
    super
  end

  # bootstrap aux_codes into this project (add a require and a call to #init to environment.rb)
  def bootstrap
    environment_rb = File.join RAILS_ROOT, 'config', 'environment.rb'
    if File.file? environment_rb
      source = File.read environment_rb
      unless source =~ /require .aux_codes./
        File.open(environment_rb, 'a'){|f| f << "\nrequire 'aux_codes'\nAuxCode.init" }
        puts "     updated  config/environment.rb"
      end
    end
  end

  # checks to see whether or not there's already a create_aux_codes migration
  def migration_exists?
    db_dir         = File.join RAILS_ROOT, 'db'
    migrations_dir = File.join db_dir, 'migrate'
    return false unless File.directory? db_dir
    return false unless File.directory? migrations_dir
    return false if Dir[ File.join(migrations_dir, '*_create_aux_codes.rb') ].empty?
    return true
  end

  # copy files into the project, our templates:
  #
  # templates/
  # |-- aux_codes.yml
  # `-- migration.rb
  #
  def manifest
    record do |m|
      m.directory 'config'
      m.file 'aux_codes.yml', 'config/aux_codes.yml'

      unless migration_exists?
        timestamp = Time.now.strftime '%Y%m%d%H%M%S'
        m.directory 'db/migrate'
        m.file 'migration.rb', "db/migrate/#{ timestamp }_create_aux_codes.rb"
      end
    end
  end
 
protected
 
  def banner
    "Usage: #{$0} aux_codes"
  end
 
end
