module RestfulSync
  require 'draper'
  class BaseDecorator < Draper::Decorator
    attr_accessor :has_many_attributes, :has_many_through_attributes
    
    def as_json
      attributes = source.attributes
      attributes = attributes.as_json.delete_if { |key, value| ["updated_at", "created_at"].include? key }
      
      nested_resources = source.class.reflect_on_all_associations

      nested_resources.each do |association|
        p association.name
        if source.nested_attributes_options.keys.include? association.name
          p "ASSOCIATION"
          
          if (associated = source.send(association.name))
            p "exists"
            attributes["#{association.name}_attributes"] = {}
            # Has many
            if associated.is_a?(ActiveRecord::Relation)
              p "HAS MANY"
              associated.each_with_index do |associated_object, i|
                attributes["#{association.name}_attributes"][i.to_s] = self.class.decorate(associated_object).as_json
              end
            # Has one
            else
              p "HAS ONE"
              attributes["#{association.name}_attributes"] = self.class.decorate(associated).as_json
            end
          end
        else
          p "IDS"
          if [:has_many, :has_and_belongs_to_many].include? association.macro
            key = association.name.to_s.singularize
            attributes["#{key}_ids"] = []
            attributes["#{key}_ids"] = source.send(association.name).map { |obj| obj.id.to_s }
          end
        end
      end

      attributes
    end
  end
end