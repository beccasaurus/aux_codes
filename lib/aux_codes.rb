$:.unshift File.dirname(__FILE__)
%w( rubygems activerecord ).each {|lib| require lib }

class CreateAuxCodes < ActiveRecord::Migration
  def self.up
    create_table :aux_codes,   :comment => 'Auxilary Codes' do |t|
      t.integer  :aux_code_id, :comment => 'ID of parent aux code (Category)',      :null => false
      t.string   :name,        :comment => 'Name of Category code (or child code)', :null => false

      %w( integer decimal string text boolean datetime ).each do |field_type|
        t.column field_type.to_sym, "#{field_type}_field"
      end

      t.timestamps
    end
  end
  def self.down
    drop_table :aux_codes
  end
end

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

  def aux_code_class
    klass = Class.new(AuxCode) do
      class << self
        attr_accessor :aux_code_id, :aux_code

        def aux_code
          # @aux_code ||= AuxCode.find aux_code_id
          AuxCode.find aux_code_id
        end

        def count_with_aux_code_scope options = {}
          with_scope(:find => { :conditions => ['aux_code_id = ?', self.aux_code_id] }) do
            count_without_aux_code_scope options
          end
        end
        def method_missing_with_aux_code_scope name, *args, &block
          if name.to_s[/^find/]
            if name.to_s[/or_create_by_/]
              name = "#{name}_and_aux_code_id".to_sym
              args << self.aux_code_id
              # method_missing_without_aux_code_scope name, *args
              AuxCode.send name, *args, &block
            else
              with_scope(:find => { :conditions => ['aux_code_id = ?', self.aux_code_id] }) do
                method_missing_without_aux_code_scope name, *args, &block
              end
            end
          else
            method_missing_without_aux_code_scope name, *args, &block
          end
        rescue NoMethodError => ex
          begin
            aux_code.send name, *args, &block # try on the AuxCode instance for this class ...
          rescue
            raise ex
          end
        end
        def find_with_aux_code_scope first_or_all, options = {}
          with_scope(:find => { :conditions => ['aux_code_id = ?', self.aux_code_id] }) do
            find_without_aux_code_scope first_or_all, options
          end
        end
        def create_with_aux_code_scope options = {}
          create_without_aux_code_scope options.merge({ :aux_code_id => self.aux_code_id })
        end
        def create_with_aux_code_scope! options = {}
          create_without_aux_code_scope! options.merge({ :aux_code_id => self.aux_code_id })
        end
        def new_with_aux_code_scope options = {}
          new_without_aux_code_scope options.merge({ :aux_code_id => self.aux_code_id })
        end

        alias_method_chain :count, :aux_code_scope
        alias_method_chain :method_missing, :aux_code_scope
        alias_method_chain :find, :aux_code_scope
        alias_method_chain :create, :aux_code_scope
        alias_method_chain :create!, :aux_code_scope
        alias_method_chain :new, :aux_code_scope
      end
    end

    klass.aux_code_id = self.id # the class needs to know its own aux_code_id
    klass
  end

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
    end

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
  end

protected

  def set_default_values
    self.aux_code_id = 0 unless aux_code_id
  end

end
