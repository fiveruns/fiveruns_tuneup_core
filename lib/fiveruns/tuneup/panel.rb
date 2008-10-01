module Fiveruns
  module Tuneup
    
    class << self
      attr_accessor :javascripts_path
      attr_accessor :stylesheets_path
    end
  
    def self.insert_panel(body, run)
      return body unless run
      tag = body[/(<body[^>]*>)/i, 1]
      return body unless tag
      panel = Panel.new(run)
      body.sub(/<\/head>/i, head << '</head>').sub(tag, tag + panel.to_html)
    end

    def self.head
      %(
        <script src='#{javascripts_path}/init.js' type='text/javascript'></script>
        <link rel='stylesheet' type='text/css' href='#{stylesheets_path}/tuneup.css'/>
      )
    end
    
    class Panel
      include Templating
      
      attr_reader :root
      def initialize(root)
        @root = root
      end
      
      private
      
      def template
        %(
          <div id="tuneup"><h1>FiveRuns TuneUp</h1><div style="display: block;" id="tuneup-content"><div id="tuneup-panel">
            <div id="tuneup-data">
            <div id="tuneup-top">
              <%= root.to_html %>
              <%# In later version... %>
              <!-- <a href="#" id="tuneup-save-link">Share this Run</a> -->
            </div>
            <ul id="tuneup-details">
              <% root.children.each do |child| %>
                <%= child.to_html %>
              <% end %>
              <li style="clear: both;"/>
            </ul>
          </div>
          </div></div></div>
        )
      end
      
    end
   
  end
end