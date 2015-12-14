require "jsduck/options/parser"
require "jsduck/util/null_object"

describe JsDuck::Options::Parser do
  before :all do
    file_class = JsDuck::Util::NullObject.new({
        :dirname => Proc.new {|x| x },
        :expand_path => Proc.new {|x, pwd| x },
        :exists? => false,
      })
    @parser = JsDuck::Options::Parser.new(file_class)
  end

  def parse(*argv)
    @parser.parse(argv)
  end

  describe :input_files do
    it "defaults to empty array" do
      parse("-o", "foo/").input_files.should == []
    end

    it "treats empty input files list as invalid" do
      parse("-o", "foo/").validate!(:input_files).should_not == nil
    end

    it "contains all non-option arguments" do
      parse("foo.js", "bar.js").input_files.should == ["foo.js", "bar.js"]
    end

    it "is populated by --builtin-classes" do
      parse("--builtin-classes").input_files[0].should =~ /js-classes$/
    end

    it "is valid when populated by --builtin-classes" do
      parse("--builtin-classes").validate!(:input_files).should == nil
    end
  end

  describe :export do
    it "accepts --export=full" do
      opts = parse("--export", "full")
      opts.validate!(:export).should == nil
      opts.export.should == :full
    end

    it "accepts --export=examples" do
      opts = parse("--export", "examples")
      opts.validate!(:export).should == nil
      opts.export.should == :examples
    end

    it "doesn't accept --export=foo" do
      opts = parse("--export", "foo")
      opts.validate!(:export).should_not == nil
    end

    it "is valid when no export option specified" do
      opts = parse()
      opts.validate!(:export).should == nil
    end
  end

  describe :guides_toc_level do
    it "defaults to 2" do
      parse().guides_toc_level.should == 2
    end

    it "gets converted to integer" do
      parse("--guides-toc-level", "6").guides_toc_level.should == 6
    end

    it "is valid when between 1..6" do
      opts = parse("--guides-toc-level", "1")
      opts.validate!(:guides_toc_level).should == nil
    end

    it "is invalid when not a number" do
      opts = parse("--guides-toc-level", "hello")
      opts.validate!(:guides_toc_level).should_not == nil
    end

    it "is invalid when larger then 6" do
      opts = parse("--guides-toc-level", "7")
      opts.validate!(:guides_toc_level).should_not == nil
    end
  end

  describe :processes do
    it "defaults to nil" do
      opts = parse()
      opts.validate!(:processes).should == nil
      opts.processes.should == nil
    end

    it "can be set to 0" do
      opts = parse("--processes", "0")
      opts.validate!(:processes).should == nil
      opts.processes.should == 0
    end

    it "can be set to any positive number" do
      opts = parse("--processes", "4")
      opts.validate!(:processes).should == nil
      opts.processes.should == 4
    end

    it "can not be set to a negative number" do
      opts = parse("--processes", "-6")
      opts.validate!(:processes).should_not == nil
    end
  end

  describe :import do
    it "defaults to empty array" do
      parse().import.should == []
    end

    it "expands into version and path components" do
      parse("--import", "1.0:/vers/1", "--import", "2.0:/vers/2").import.should == [
        {:version => "1.0", :path => "/vers/1"},
        {:version => "2.0", :path => "/vers/2"},
      ]
    end

    it "expands pathless version number into just :version" do
      parse("--import", "3.0").import.should == [
        {:version => "3.0"},
      ]
    end
  end

  describe :ext_namespaces do
    it "defaults to nil" do
      parse().ext_namespaces.should == nil
    end

    it "can be used with comma-separated list" do
      parse("--ext-namespaces", "Foo,Bar").ext_namespaces.should == ["Foo", "Bar"]
    end

    it "can not be used multiple times" do
      parse("--ext-namespaces", "Foo", "--ext-namespaces", "Bar").ext_namespaces.should == ["Bar"]
    end
  end

  describe :ignore_html do
    it "defaults to empty hash" do
      parse().ignore_html.should == {}
    end

    it "can be used with comma-separated list" do
      html = parse("--ignore-html", "em,strong").ignore_html
      html.should include("em")
      html.should include("strong")
    end

    it "can be used multiple times" do
      html = parse("--ignore-html", "em", "--ignore-html", "strong").ignore_html
      html.should include("em")
      html.should include("strong")
    end
  end

  describe "--debug" do
    it "is equivalent of --template=template --template-links" do
      opts = parse("--debug")
      opts.template.should == "template"
      opts.template_links.should == true
    end

    it "has a shorthand -d" do
      opts = parse("-d")
      opts.template.should == "template"
      opts.template_links.should == true
    end
  end

  describe :warnings do
    it "default to empty array" do
      parse().warnings.should == []
    end

    it "are parsed with Warnings::Parser" do
      ws = parse("--warnings", "+foo,-bar").warnings
      ws.length.should == 2
      ws[0][:type].should == :foo
      ws[0][:enabled].should == true
      ws[1][:type].should == :bar
      ws[1][:enabled].should == false
    end
  end

  describe :verbose do
    it "defaults to false" do
      parse().verbose.should == false
    end

    it "set to true when --verbose used" do
      parse("--verbose").verbose.should == true
    end

    it "set to true when -v used" do
      parse("-v").verbose.should == true
    end
  end

  describe :external do
    it "contains JavaScript builtins by default" do
      exts = parse().external
      %w(Object String Number Boolean RegExp Function Array Arguments Date).each do |name|
        exts.should include(name)
      end
    end

    it "contains JavaScript builtin error classes by default" do
      exts = parse().external
      exts.should include("Error")
      %w(Eval Range Reference Syntax Type URI).each do |name|
        exts.should include("#{name}Error")
      end
    end

    it "contains the special anything-goes Mixed type" do
      parse().external.should include("Mixed")
    end

    it "can be used multiple times" do
      exts = parse("--external", "MyClass", "--external", "YourClass").external
      exts.should include("MyClass")
      exts.should include("YourClass")
    end

    it "can be used with comma-separated list" do
      exts = parse("--external", "MyClass,YourClass").external
      exts.should include("MyClass")
      exts.should include("YourClass")
    end
  end

  # Turns :attribute_name into "--option-name" or "--no-option-name"
  def opt(attr, negate=false)
    (negate ? "--no-" : "--") + attr.to_s.gsub(/_/, '-')
  end

  # Boolean options
  {
    :seo => false,
    :tests => false,
    :source => true, # TODO
    :ignore_global => false,
    :ext4_events => nil, # TODO
    :touch_examples_ui => false,
    :cache => false,
    :warnings_exit_nonzero => false,
    :color => nil, # TODO
    :pretty_json => nil,
    :template_links => false,
  }.each do |attr, default|
    describe attr do
      it "defaults to #{default.inspect}" do
        parse().send(attr).should == default
      end

      it "set to true when --#{attr} used" do
        parse(opt(attr)).send(attr).should == true
      end

      it "set to false when --no-#{attr} used" do
        parse(opt(attr, true)).send(attr).should == false
      end
    end
  end

  # Simple setters
  {
    :encoding => nil,
    :title => "Documentation - JSDuck",
    :footer => "Generated on {DATE} by {JSDUCK} {VERSION}.",
    :welcome => nil,
    :guides => nil,
    :videos => nil,
    :examples => nil,
    :categories => nil,
    :new_since => nil,
    :comments_url => nil,
    :comments_domain => nil,
    :examples_base_url => nil,
    :link => '<a href="#!/api/%c%-%m" rel="%c%-%m" class="docClass">%a</a>',
    :img => '<p><img src="%u" alt="%a" width="%w" height="%h"></p>',
    :eg_iframe => nil,
    :cache_dir => nil,
    :extjs_path => "extjs/ext-all.js",
    :local_storage_db => "docs",
  }.each do |attr, default|
    describe attr do
      it "defaults to #{default.inspect}" do
        parse().send(attr).should == default
      end
      it "is set to given string value" do
        parse(opt(attr), "some string").send(attr).should == "some string"
      end
    end
  end

  # HTML and CSS options that get concatenated
  [
    :head_html,
    :body_html,
    :css,
    :message,
  ].each do |attr|
    describe attr do
      it "defaults to empty string" do
        parse().send(attr).should == ""
      end

      it "can be used multiple times" do
        parse(opt(attr), "Some ", opt(attr), "text").send(attr).should == "Some text"
      end
    end
  end

  # Multiple paths
  [
    :exclude,
    :images,
    :tags,
  ].each do |attr|
    describe attr do
      it "defaults to empty array" do
        parse().send(attr).should == []
      end

      it "can be used multiple times" do
        parse(opt(attr), "foo", opt(attr), "bar").send(attr).should == ["foo", "bar"]
      end

      it "can be used with comma-separated list" do
        parse(opt(attr), "foo,bar").send(attr).should == ["foo", "bar"]
      end
    end
  end

end
