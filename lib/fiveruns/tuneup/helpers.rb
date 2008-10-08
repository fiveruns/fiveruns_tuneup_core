module Fiveruns
  module Tuneup
    
    def self.format_caller(trace)
      valid_lines = trace.reject { |line| line =~ /fiveruns_tuneup/ }[0,5]
      linked_lines = valid_lines.map { |line| editor_link_line(line) }
      '<pre>%s</pre>' % linked_lines.join("\n")
    end
    
    def self.strip_root(text)
      if defined?(::Fiveruns::Tuneup::STRIP_ROOT)
        pattern = /^#{Regexp.quote ::Fiveruns::Tuneup::STRIP_ROOT}\/?/o
        if text =~ pattern
          result = text.sub(pattern, '')
          in_app = result !~ /^gems\//
          return [in_app, result]
        end
      end
      [false, text]
    end
    
    # TODO: Refactor
    def self.editor_link_line(line)
      filename, number, extra = line.match(/^(.+?):(\d+)(?::in\b(.*?))?/)[1, 2]
      in_app, line = strip_root(line)
      name = if line.size > 87
        "&hellip;#{CGI.escapeHTML line.sub(/^.*?(.{84})$/, '\1')}"
      else 
        line
      end
      name = if in_app
        if name =~ /`/
          name.sub(/^(.*?)\s+`(.*?)'$/, %q(<span class='tuneup-app-line'>\1</span> `<b class='tuneup-app-line'>\2</b>'))
        else
          %(<span class='tuneup-app-line'>#{name}</span>)
        end
      else
        name.sub(/([^\/\\]+\.\S+:\d+:in)\s+`(.*?)'$/, %q(\1 `<b>\2</b>'))
      end
      %(<a title='%s' href='txmt://open/?url=file://%s&line=%d'>%s</a>%s) % [CGI.escapeHTML(line), filename, number, name, extra]
    end
    
  end
end