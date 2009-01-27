#
# extend AuxCode to return a full-blown ActiveRecord class
#
class AuxCode

  def aux_code_class &block
    klass = Class.new(AuxCode) do
      class << self

        attr_accessor :aux_code_id, :aux_code

        def aux_code
          # @aux_code ||= AuxCode.find aux_code_id
          AuxCode.find aux_code_id
        end

        #
        # this handles typical ActiveRecord::Base method_missing features, eg: aux_code.find_by_name 'foo'
        #
        # we wrap these methods in the scope of this aux code (category)
        #
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
        alias_method_chain :method_missing, :aux_code_scope

        def count_with_aux_code_scope options = {}
          with_scope(:find => { :conditions => ['aux_code_id = ?', self.aux_code_id] }) do
            count_without_aux_code_scope options
          end
        end
        alias_method_chain :count, :aux_code_scope

        def find_with_aux_code_scope first_or_all, options = {}
          with_scope(:find => { :conditions => ['aux_code_id = ?', self.aux_code_id] }) do
            find_without_aux_code_scope first_or_all, options
          end
        end
        alias_method_chain :find, :aux_code_scope
        
        def create_with_aux_code_scope options = {}
          create_without_aux_code_scope options.merge({ :aux_code_id => self.aux_code_id })
        end
        alias_method_chain :create, :aux_code_scope
        
        def create_with_aux_code_scope! options = {}
          create_without_aux_code_scope! options.merge({ :aux_code_id => self.aux_code_id })
        end
        alias_method_chain :create!, :aux_code_scope
        
        def new_with_aux_code_scope options = {}
          new_without_aux_code_scope options.merge({ :aux_code_id => self.aux_code_id })
        end
        alias_method_chain :new, :aux_code_scope

      end
    end

    klass.aux_code_id = self.id # the class needs to know its own aux_code_id
    klass.class_eval(&block) if block
    klass
  end

end
