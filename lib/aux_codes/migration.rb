#
# ActiveRecord migration for creating the aux_codes table
#
class AuxCodes
  class CreateAuxCodes < ActiveRecord::Migration
  
    def self.up
      create_table :aux_codes,   :comment => 'Auxilary Codes' do |t|

        t.integer  :aux_code_id, :comment => 'ID of parent aux code (Category)',      :null => false
        t.string   :name,        :comment => 'Name of Category code (or child code)', :null => false

        # disabled for now, as they're not needed - no specs using this functionality
        #
        # %w( integer decimal string text boolean datetime ).each do |field_type|
        #   t.column field_type.to_sym, "#{field_type}_field"
        # end
        
        # this should be added conditionally, based on whether or not meta attributes are desired
        t.text :meta, :comment => 'Serialized meta_attributes'

        t.timestamps
      end
    end

    def self.down
      drop_table :aux_codes
    end

  end
end
