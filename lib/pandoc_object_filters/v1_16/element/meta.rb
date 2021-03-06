require "pandoc_object_filters"

module PandocObjectFilters
  module V1_16
    module Element
      class Meta < PandocObjectFilters::V1_16::Element::Base
        include PandocObjectFilters::V1_16::Element::Enum
        alias elements contents

        def initialize(contents = {})
          super
        end

        def to_ast
          { "unMeta" => PandocObjectFilters::Element.to_ast(contents) }
        end
      end
    end
  end
end
