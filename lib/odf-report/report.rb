module ODFReport

class Report
  include Images

  def initialize(template_name = nil, io: nil)

    @template = ODFReport::Template.new(template_name, io: io)

    @texts = []
    @fields = []
    @tables = []
    @images = {}
    @image_names_replacements = {}
    @sections = []
    @actions = []

    yield(self) if block_given?

  end

  def add_field(field_tag, value='')
    opts = {:name => field_tag, :value => value}
    field = Field.new(opts)
    @fields << field
  end

  def add_text(field_tag, value='')
    opts = {:name => field_tag, :value => value}
    text = Text.new(opts)
    @texts << text
  end

  def add_table(table_name, collection, opts={})
    opts.merge!(:name => table_name, :collection => collection)
    tab = Table.new(opts)
    @tables << tab

    yield(tab)
  end

  def add_section(section_name, collection, opts={})
    opts.merge!(:name => section_name, :collection => collection)
    sec = Section.new(opts)
    @sections << sec

    yield(sec)
  end

  def remove_section(section_name)
    @actions << ODFReport::Actions::RemoveSection.new(section_name)
  end

  def add_image(name, path)
    @images[name] = path
  end

  def generate(dest = nil)

    @template.update_content do |file|

      file.update_files do |doc|

        @sections.each { |s| s.replace!(doc) }
        @tables.each   { |t| t.replace!(doc) }

        @texts.each    { |t| t.replace!(doc) }
        @fields.each   { |f| f.replace!(doc) }

        find_image_name_matches(doc)
        avoid_duplicate_image_names(doc)

        @actions.each   { |action| action.process!(doc) }

        find_image_name_matches(doc)
        avoid_duplicate_image_names(doc)

        add_styles(doc)

      end

      include_image_files(file)

    end

    if dest
      ::File.open(dest, "wb") {|f| f.write(@template.data) }
    else
      @template.data
    end

  end

private

  def parse_document(txt)
    doc = Nokogiri::XML(txt)
    yield doc
    txt.replace(doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML))
  end


  def add_styles(doc)
    doc.children.first.children[2].inner_html +=
      "<style:style style:name='PAGEBREAK' style:family='paragraph' style:parent-style-name='Standard'>
         <style:paragraph-properties fo:break-before='page'/>
       </style:style>"
  end
end
end
