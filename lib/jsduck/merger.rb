require 'jsduck/class'

module JsDuck

  # Takes data from comment and code that follows it and combines
  # these two pieces of information into one.  The code comes from
  # JsDuck::Ast and comment from JsDuck::DocAst.
  #
  # The main method merge() produces a hash as a result.
  class Merger

    # Takes a docset and merges the :comment and :code inside it,
    # producing hash as a result.
    def merge(docset)
      docs = docset[:comment]
      code = docset[:code]

      case docset[:tagname]
      when :class
        result = merge_class(docs, code)
      when :method, :event, :css_mixin
        result = merge_like_method(docs, code)
      when :cfg, :property, :css_var
        result = merge_like_property(docs, code)
      end

      result[:linenr] = docset[:linenr]

      result
    end

    private

    def merge_class(docs, code)
      h = do_merge(docs, code, {
        :mixins => [],
        :alternateClassNames => [],
        :requires => [],
        :uses => [],
        :singleton => false,
      })

      # Ignore extending of the Object class
      h[:extends] = nil if h[:extends] == "Object"

      h[:aliases] = build_aliases_hash(h[:aliases] || [])

      # Used by Aggregator to determine if we're dealing with Ext4 code
      h[:code_type] = code[:code_type] if code[:code_type]

      h[:members] = Class.default_members_hash
      h[:statics] = Class.default_members_hash

      h
    end

    def merge_like_method(docs, code)
      h = do_merge(docs, code)
      h[:params] = merge_params(docs, code)
      h
    end

    def merge_like_property(docs, code)
      h = do_merge(docs, code)

      h[:type] = merge_if_code_matches(:type, docs, code)
      if h[:type] == nil
        h[:type] = code[:tagname] == :method ? "Function" : "Object"
      end

      h[:default] = merge_if_code_matches(:default, docs, code)
      h
    end

    # --- helpers ---

    def do_merge(docs, code, defaults={})
      h = {}
      docs.each_pair do |key, value|
        h[key] = docs[key] || code[key] || defaults[key]
      end

      h[:name] = merge_name(docs, code)
      h[:id] = create_member_id(h)

      # Copy private to meta
      h[:meta][:private] = h[:private] if h[:private]

      # Copy :static and :inheritable flags from code if present
      h[:meta][:static] = true if code[:meta] && code[:meta][:static]
      h[:inheritable] = true if code[:inheritable]

      # Remember auto-detection info
      h[:autodetected] = code[:autodetected] if code[:autodetected]

      h
    end

    def create_member_id(m)
      # Sanitize $ in member names with something safer
      name = m[:name].gsub(/\$/, 'S-')
      "#{m[:meta][:static] ? 'static-' : ''}#{m[:tagname]}-#{name}"
    end

    # Given array of full alias names like "foo.bar", "foo.baz"
    # build hash like {"foo" => ["bar", "baz"]}
    def build_aliases_hash(aliases)
      hash={}
      aliases.each do |a|
        if a =~ /^([^.]+)\.(.+)$/
          if hash[$1]
            hash[$1] << $2
          else
            hash[$1] = [$2]
          end
        end
      end
      hash
    end

    def merge_params(docs, code)
      explicit = docs[:params] || []
      implicit = code_matches_doc?(docs, code) ? (code[:params] || []) : []
      # Override implicit parameters with explicit ones
      # But if explicit ones exist, don't append the implicit ones.
      params = []
      (explicit.length > 0 ? explicit.length : implicit.length).times do |i|
        im = implicit[i] || {}
        ex = explicit[i] || {}
        params << {
          :type => ex[:type] || im[:type] || "Object",
          :name => ex[:name] || im[:name] || "",
          :doc => ex[:doc] || im[:doc] || "",
          ## merge conflict old code 
          ## :doc => doc,
          :deprecated => ex[:deprecated] || false,
          :platforms => ex[:platforms] || nil,
          :inline_platforms => ex[:inline_platforms] || nil,
          :optional => ex[:optional] || false,
          :default => ex[:default],
          :properties => ex[:properties] || [],
        }
      end
      params
    end

    def merge_name(docs, code)
      if docs[:name]
        docs[:name]
      elsif code[:name]
        if docs[:tagname] == :class
          code[:name]
        else
          code[:name].split(/\./).last
        end
      else
        ""
      end
    end

    def merge_if_code_matches(key, docs, code, default=nil)
      if docs[key]
        docs[key]
      elsif code[key] && code_matches_doc?(docs, code)
        code[key]
      else
        default
      end
    end

    # True if the name detected from code matches with explicitly documented name.
    # Also true when no explicit name documented.
    def code_matches_doc?(docs, code)
      return docs[:name] == nil || docs[:name] == code[:name]
    end

  end

end
