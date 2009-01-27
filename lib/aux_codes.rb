$:.unshift File.dirname(__FILE__)

%w( rubygems activerecord aux_codes/migration ).each {|lib| require lib }

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

  def method_missing_with_indifferent_hash_style_values name, *args, &block
    method_missing_without_indifferent_hash_style_values name, *args, &block
  rescue NoMethodError => ex
    begin
      self[name]
    rescue
      raise ex
    end
  end
  alias_method_chain :method_missing, :indifferent_hash_style_values

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
      return AuxCode.find_by_name_and_aux_code_id(obj, 0) if obj.is_a?String
      return AuxCode.find_by_name_and_aux_code_id(obj.to_s, 0) if obj.is_a?Symbol
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
  end

protected

  def set_default_values
    self.aux_code_id = 0 unless aux_code_id
  end

end

%w( aux_codes/aux_code_class ).each {|lib| require lib } # define the class returned by #aux_code_class
