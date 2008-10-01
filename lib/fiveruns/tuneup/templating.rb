require 'erb'

module Fiveruns
  module Tuneup
    
    module Templating
      
      def h(text)
        CGI.escapeHTML(text)
      end
      
      def to_html
        ERB.new(template).result(binding)
      end
      
    end
    
  end
end