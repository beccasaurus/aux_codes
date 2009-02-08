$:.unshift File.dirname(__FILE__)

%w( rubygems activerecord aux_codes/migration ).each {|lib| require lib }

# top-level class for AuxCodes
#
# used for namespacing and global configuration (once added)
#
class AuxCodes
end

#
# the basic AuxCode ActiveRecord class
#
class AuxCode < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :aux_code_id

  belongs_to :aux_code
  alias code aux_code
  alias category aux_code

  has_many :aux_codes
  alias codes aux_codes

  before_create :set_default_values

  def code_names
    codes.map &:name
  end

  def is_a_category?
    aux_code_id == 0
  end

  def class_name
    name.gsub(/[^[:alpha:]]/,'_').titleize.gsub(' ','').singularize
  end

  def to_s
    name
  end

  def [] attribute_or_code_name
    if attributes.include?attribute_or_code_name
      attributes[attribute_or_code_name]
    else
      found = codes.select {|c| c.name.to_s =~ /#{attribute_or_code_name}/ }
        if found.empty? # try case insensitive (sans underscores)
          found = codes.select {|c| c.name.downcase.gsub('_',' ').to_s =~ 
            /#{attribute_or_code_name.to_s.downcase.gsub('_',' ')}/ }
        end
      found.first if found
    end
  end

  def deserialized_meta_hash
    require 'yaml'
    self.meta ||= ""
    YAML::load(self.meta) || { }
  end

  def get_meta_attribute meta_attribute
    deserialized_meta_hash[meta_attribute.to_s]
  end

  def set_meta_attribute meta_attribute, value
    require 'yaml'
    meta_hash = deserialized_meta_hash
    meta_hash[meta_attribute.to_s] = value
    self.meta = meta_hash.to_yaml
  end

  # this allows us to say things like:
  #
  #   foo = AuxCode.create :name => 'foo'
  #   foo.codes.create :name => 'bar'
  #
  #   foo.bar # should return the bar aux code under the foo category
  #
  #   if bar doesn't exist, we throw a normal NoMethodError
  #
  #   this should check meta_attributes on the object too
  #
  def method_missing_with_indifferent_hash_style_values name, *args, &block
    method_missing_without_indifferent_hash_style_values name, *args, &block
  rescue NoMethodError => ex
    begin
      if name.to_s[/=$/]
        self.set_meta_attribute(name.to_s.sub(/=$/,''), args.first) # we said `code.foo= X` so we should set the foo meta attribute to X
        save
      else
        code = self[name]
        code = self.get_meta_attribute(name) unless code
        raise ex unless code
        return code
      end
    rescue
      raise ex
    end
  end
  alias_method_chain :method_missing, :indifferent_hash_style_values

  # class methods
  class << self

    def categories
      AuxCode.find_all_by_aux_code_id(0)
    end

    def category_names
      AuxCode.categories.map &:name
    end

    def category category_object_or_id_or_name
      obj = category_object_or_id_or_name
      return obj if obj.is_a?AuxCode
      return AuxCode.find(obj) if obj.is_a?Fixnum
      if obj.is_a?(String) || obj.is_a?(Symbol)
        obj = obj.to_s
        found = AuxCode.find_by_name_and_aux_code_id(obj, 0)
        if found.nil?
          # try replacing underscores with spaces and doing a 'LIKE' search
          found = AuxCode.find :first, :conditions => ["name LIKE ? AND aux_code_id = ?", obj.gsub('_', ' '), 0]
        end
        return found
      end
      raise "I don't know how to find an AuxCode of type #{ obj.class }"
    end
    alias [] category

    def category_codes category_object_or_id_or_name
      category( category_object_or_id_or_name ).codes
    end
    alias category_values category_codes

    def category_code_names category_object_or_id_or_name
      category( category_object_or_id_or_name ).code_names
    end

    def create_classes!
      AuxCode.categories.each do |category|
        Kernel::const_set category.class_name, category.aux_code_class
      end
    end

    # this allows us to say things like:
    #
    #   AuxCode.create :name => 'foo'
    #
    #   AuxCode.foo # should return the foo category aux code
    #
    def method_missing_with_indifferent_hash_style_values name, *args, &block
      unless self.respond_to?:aux_code_id # in which case, this is a *derived* class, not AuxCode
        begin
          method_missing_without_indifferent_hash_style_values name, *args, &block
        rescue NoMethodError => ex
          begin
            self[name]
          rescue
            raise ex
          end
        end
      else
        method_missing_without_indifferent_hash_style_values name, *args, &block
      end
    end
    alias_method_chain :method_missing, :indifferent_hash_style_values

    def load_yaml yaml_string
      require 'yaml'
      self.load YAML::load(yaml_string)
    end

    def load_file serialized_yaml_file_path
      load_yaml File.read(serialized_yaml_file_path)
    end

    # initialize AuxCodes ... looks for config/aux_codes.yml
    # and creates classes
    def init # should eventually take configuration options (hash || block)
      aux_codes_yml = File.join 'config', 'aux_codes.yml'
      if File.file? aux_codes_yml
        load_file aux_codes_yml
        create_classes!
      end
    end

    # 
    # loads AuxCodes (creates them) from a Hash, keyed on the name of the aux code categories to create
    #
    # hash: a Hash or an Array [ [key,value], [key,value] ] or anything with an enumerator 
    #       that'll work with `hash.each {|key,value| ... }`
    #
    def load hash
      hash.each do |category_name, codes|
        category = AuxCode.find_or_create_by_name( category_name.to_s ).aux_code_class
        codes.each do |name, values|

          # only a name given
          if values.nil? or values.empty?
            if name.is_a? String or name.is_a? Symbol # we have a String || Symbol, it's likely the code's name, eg. :foo or 'bar'
              category.create :name => name.to_s unless category.code_names.include?(name.to_s)

            elsif name.is_a? Hash # we have a Hash, likely with the create options, eg. { :name => 'hi', :foo =>'bar' }
              category.create name

            else
              raise "not sure how to create code in category #{ category.name } with: #{ name.inspect }"
            end

            # we have a name and values
          else
            if values.is_a? Hash and (name.is_a? String or name.is_a? Symbol) # we have a Hash, likely with the create options ... we'll merge the name in as :name and create
              code = category[ name.to_s ]
              if code
                values.each do |attribute, new_value|
                  code.send "#{attribute}=", new_value # update values
                end
              else
                code = category.create values.merge({ :name => name.to_s })
              end

            else
              raise "not sure how to create code in category #{ category.name } with: #{ name.inspect }, #{ values.inspect }"

            end
          end
        end
      end
    end

  end

  protected

  def set_default_values
    self.aux_code_id = 0 unless aux_code_id
  end

end

%w( aux_codes/aux_code_class ).each {|lib| require lib } # define the class returned by #aux_code_class
