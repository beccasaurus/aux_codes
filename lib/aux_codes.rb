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
  end

protected

  def set_default_values
    self.aux_code_id = 0 unless aux_code_id
  end

end
