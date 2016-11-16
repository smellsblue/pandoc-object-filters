require "pandoc_object_filters"

module PandocObjectFilters
  module V1_17
    module Element
      class Target < PandocObjectFilters::V1_17::Element::Base
        include PandocObjectFilters::V1_16::Element::Target::Behavior
      end
    end
  end
end
