require 'json'

module Fiveruns
  module Tuneup
    
    class CalculationError < ::RuntimeError; end

    def self.record(&block)
      Step.reset!
      root = RootStep.new
      root.record(&block)
      root
    end

    def self.step(name, layer, extras = {}, &block)
      trace = format_caller(caller)
      Step.new(name, layer, extras.merge('Caller' => trace), nil).record(&block)
    end
    
    class RootStep
      
      include Templating
      attr_reader :children, :bar
      attr_accessor :time, :parent
      def initialize(time = nil)
        @time = time
        @children = []
        @bar = Bar.new(self)
      end
      
      def root
        parent ? parent.root : self
      end
      
      def record
        start = Time.now
        result = Step.inside(self) { yield }
        @time = Time.now - start
        result
      end
      def disparity
        result = time - children.inject(0) { |sum, child| sum + child.time }
        if result < 0
          raise CalculationError, "Child steps exceed parent step size"
        end
        result
      end
      def add_child(child)
        child.parent = self
        children << child
      end
      def format_time(time)
        '%.1fms' % (time * 1000)
      end
      def layer_portions
        children.first.layer_portions
      end
      def to_json
        {:children => children, :time => time}.to_json
      end
      
      def proportion
        time / root.time
      end
      
      def to_html_with_children
        to_html << children.map { |c| c.to_html }.join
      end

      def template
        %(
          <div id="tuneup-summary">
            <%= bar.to_html %>
            <%= (time * 1000).to_i %> ms
          </div>
        )
      end

    end

    class Step < RootStep
      
      def self.load(source, depth = 0)
        hash = source.is_a?(Hash) ? source : JSON.load(source)
        step = if hash['layer']
          Step.new(hash['name'], hash['layer'], hash['extras'], hash['time'])
        elsif depth == 0
          RootStep.new(hash['time'])
        else
          raise ArgumentError, "Could not find data for step in #{hash.inspect}"
        end
        hash['children'].each do |child_hash|
          child = load(child_hash)
          step.add_child(child)
        end
        step
      end

      def self.stack
        @stack ||= []
      end

      def self.reset!
        stack.clear
      end

      def self.inside(step)
        unless stack.empty?
          stack.last.add_child(step)
        end
        stack << step
        result = yield
        stack.pop
        result
      end

      attr_reader :name, :layer, :extras
      def initialize(name, layer, raw_extras = {}, time = nil)
        super(time)
        @name = name
        @layer = layer.to_sym
        @extras = build_extras(raw_extras)
      end

      def children_with_disparity
        return children if children.empty?
        layer_name = layer if respond_to?(:layer)
        extra_step = DisparityStep.new(layer_name, disparity)
        extra_step.parent = parent
        children + [extra_step]
      end

      def layer_portions
        @layer_portions ||= begin
          result = {:model => 0, :view => 0, :controller => 0}
          if children.empty?
            result[layer] = 1
          else
            times = children.inject({}) do |totals, child|
              totals[child.layer] ||= 0
              totals[child.layer] += child.time
              totals
            end
            times[layer] ||= 0
            times[layer] += disparity
            times.inject(result) do |all, (l, t)|
              result[l] = t / time
              result            
            end
          end
          result
        end
      end
      
      def to_json
        {:children => children, :time => time, :extras => extras}.to_json
      end
      
      private
      
      def build_extras(raw_extras)
        raw_extras.sort_by { |k, v| k.to_s }.map do |name, data|
          data = case data
          when Array
            data
          when Hash
            [data['content'], data['extended']]
          else
            [data]
          end
          Extra.new(name, *data )
        end
      end
      
      def template
        %(
          <li class="<%= html_class %>">
            <ul class="tuneup-step-info">
              <li class="tuneup-title">
                <span class="time"><%= '%.1f' % (time * 1000) %> ms</span>
                <a class='tuneup-step-name' title="<%=h name %>"><%=h name %></a>
                <% if !extras.empty? %>
                  <a class='tuneup-step-extras-link'>(?)</a>
                <% end %>
              </li>
              <li class="tuneup-detail-bar"><%= bar.to_html %></li>
              <li style="clear: both;"/>
           </ul>
           <% if !extras.empty? %>
             <div class='tuneup-step-extras'>
               <div>
                 <dl>
                   <% extras.each do |extra| %>
                     <%= extra.to_html %>
                   <% end %>
                 </dl>
               </div>
             </div>
           <% end %>
           <%= html_children %>
          </li>
        )
      end
      
      private
      
      def html_class
        %W(fiveruns_tuneup_step #{'with_children' if children.any?} #{'tuneup-opened' if root.children.first.object_id == self.object_id}).compact.join(' ')
      end
      
      def html_children
        return unless children.any?
        %(<ul class='fiveruns_tuneup_children'>%s</ul>) % children_with_disparity.map { |child| child.to_html }.join
      end
      
      class Extra
        include Templating
        
        attr_reader :name, :content, :extended
        def initialize(name, content, extended = {})
          @name = name
          @content = content
          @extended = extended
        end
        
        def to_json
          {:name => name, :content => content, :extended => extended}.to_json
        end
        
        private
        
        def template
          %(
            <dt><%= h name %></dt>
            <dd>
              <%= content %>
              <% if extended.any? %>
                <% extended.each do |name, value| %>
                  <div class='tuneup-step-extra-extended' title='<%= h name %>'><%= value %></div>
                <% end %>
              <% end %>
            </dd>            
          )
        end
        
      end

    end
    
    class DisparityStep < Step
      
      def initialize(layer_name, disparity)
        super '(Other)', layer_name, {}, disparity
        @extras = build_extras description
      end
      
      private
      
      def description
        {
          'What is this?' => %(
            <p>
              <b>Other</b> is the amount of time spent executing
              code that TuneUp doesn't wrap to extract more information.
              To reduce overhead and make the listing more
              manageable, we don't generate steps for every operation.
            </p>
            <p>#{layer_description}</p>
          )
        }
      end
      
      def layer_description
        case layer
        when :model
          "In the <i>model</i> layer, this is probably ORM overhead (out of your control)."
        when :view
          "In the <i>view</i> layer, this is probably framework overhead during render (out of your control)."
        when :controller
          %(
            In the <i>controller</i> layer, this is probably framework overhead during action execution (out of your control),
            or time spent executing your code in the action (calls to private methods, libraries, etc).
          )
        end
      end
      
    end
    
  end
end