require 'jsduck/util/null_object'
require 'jsduck/util/io'

module JsDuck

  class Welcome
    # Creates Welcome object from filename.
    def self.create(filename)
      if filename
        Welcome.new(filename)
      else
        Util::NullObject.new(:to_html => "")
      end
    end

    # Parses welcome HTML file with content for welcome page.
    def initialize(filename)
      @html = Util::IO.read(filename)
    end

    # Returns the HTML
    def to_html(style="")
      "<div id='welcome-content' style='#{style}'>#{@html}</div>"
    end

  end

end
