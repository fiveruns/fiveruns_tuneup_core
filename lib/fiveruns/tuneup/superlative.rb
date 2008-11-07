module Fiveruns
  module Tuneup
  
    module Superlative

      def self.wedges
        @wedges ||= []
      end

      def self.on(target, level = :singleton, &block)
        wedge = Module.new(&block)
        case level
        when :singleton
          save = Module.new
          wedge.instance_methods.each do |meth|
            save.send(:define_method, meth, target.method(meth))
            if target.metaclass.instance_methods.include?(meth.to_s)
              target.metaclass.send(:remove_method, meth)
            end
          end
          target.extend save
          target.extend wedge
        when :instances # Instance
          wedges << wedge
          offset = wedges.size - 1
          hook = Module.new
          hook.module_eval %{
            def new(*args, &block)
              super.extend(Fiveruns::Tuneup::Superlative.wedges[#{offset}])
            end
          }
          target.extend hook
        end
      end
    end
    
  end
end