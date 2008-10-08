module Fiveruns
  module Tuneup
    
    class Bar
      include Templating
      
      attr_reader :step
      def initialize(step)
        @step = step
      end
      
      private
      
      def template
        %(
          <ul id="<%= 'tuneup-root-bar' if step.is_a?(RootStep) %>" class="tuneup-bar">
            <% %w(model view controller).each do |layer| %>
              <%= component layer %>
            <% end %>
          </ul>
        )
      end
      
      def component(layer)
        width = width_of(layer)
        return '' unless width > 0
        %(
          <li title="#{layer.to_s.capitalize}" style="width: #{width}px;" class="tuneup-layer-#{layer}">#{layer.to_s[0,1].capitalize if width >= 12}</li>
        )
      end
      
      def width_of(layer)
        portion = step.layer_portions[layer.to_sym]
        result = portion * 200 * step.proportion
        result < 1 && portion != 0 ? 1 : result
      end
      
    end
    
  end
end