# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{aux_codes}
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["remi"]
  s.date = %q{2009-02-08}
  s.description = %q{ActiveRecord plugin for easily managing lots of enumeration-type data}
  s.email = %q{remi@remitaylor.com}
  s.files = ["Rakefile", "VERSION.yml", "README.markdown", "LICENSE", "lib/aux_codes", "lib/aux_codes/aux_code_class.rb", "lib/aux_codes/migration.rb", "lib/aux_codes.rb", "spec/more_example_aux_codes.yml", "spec/aux_code_spec.rb", "spec/spec_helper.rb", "spec/example_aux_codes.yml", "rails_generators/aux_codes", "rails_generators/aux_codes/aux_codes_generator.rb", "rails_generators/aux_codes/USAGE", "rails_generators/aux_codes/templates", "rails_generators/aux_codes/templates/aux_codes.yml", "rails_generators/aux_codes/templates/migration.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/remi/aux_codes}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{ActiveRecord plugin for easily managing lots of enumeration-type data}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
