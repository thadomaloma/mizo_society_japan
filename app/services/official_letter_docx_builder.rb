require "erb"
require "zip"

class OfficialLetterDocxBuilder
  CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  PAGE_WIDTH = 11_906
  PAGE_HEIGHT = 16_838
  MARGIN_TOP = 907
  MARGIN_RIGHT = 1_021
  MARGIN_BOTTOM = 907
  MARGIN_LEFT = 1_021
  CONTENT_WIDTH = PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT

  def self.call(attributes)
    new(attributes).call
  end

  def self.default_for(key)
    {
      organization_name: "Mizo Society of Japan",
      organization_location: "Tokyo : Japan",
      reference_number: "MSJ/LET/#{Date.current.year}/001",
      dated_place: "Tokyo",
      letter_date: Date.current.strftime("%-d %B, %Y"),
      president_name: "President",
      president_phone: "+81-XX-XXXX-XXXX",
      secretary_name: "Secretary",
      secretary_phone: "+81-XX-XXXX-XXXX",
      motto: "Unity\nCulture\nWelfare",
      recipient_block: "The President/General Secretary,\nOrganization Name,\nAddress.",
      salutation: "Dear Sir/Madam,",
      subject: "Official communication",
      body: "Mizo Society of Japan hmingin chibai kan buk a che.\n\nHe lehkha hi official communication atan kan siam a ni.",
      closing: "Yours faithfully,",
      signer_name: "Authorized Name",
      signer_title: "General Secretary"
    }.fetch(key.to_sym, nil)
  end

  def initialize(attributes)
    @attributes = attributes.to_h.symbolize_keys
  end

  def call
    buffer = Zip::OutputStream.write_buffer do |zip|
      add_file(zip, "[Content_Types].xml", content_types_xml)
      add_file(zip, "_rels/.rels", relationships_xml)
      add_file(zip, "word/_rels/document.xml.rels", document_relationships_xml)
      add_file(zip, "word/styles.xml", styles_xml)
      add_file(zip, "word/document.xml", document_xml)
    end

    buffer.string
  end

  private

  attr_reader :attributes

  def add_file(zip, path, content)
    zip.put_next_entry(path)
    zip.write(content)
  end

  def document_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          #{paragraph(organization_name.upcase, align: :center, bold: true, size: 34)}
          #{paragraph(organization_location.upcase, align: :center, bold: true, size: 28)}
          #{letterhead_table}
          #{horizontal_rule}
          #{two_column_line("No. #{reference_number}", "Dated #{dated_place} the #{letter_date}")}
          #{blank_paragraph}
          #{paragraph("To")}
          #{indented_multiline(recipient_block, indent: 1440)}
          #{blank_paragraph}
          #{two_column_line("Subject :", subject, left_width: 1500, left_bold: true, right_bold: true, right_align: :left)}
          #{blank_paragraph}
          #{paragraph(salutation)}
          #{blank_paragraph}
          #{body_paragraphs}
          #{blank_paragraph}
          #{signature_block}
          <w:sectPr>
            <w:pgSz w:w="#{PAGE_WIDTH}" w:h="#{PAGE_HEIGHT}"/>
            <w:pgMar w:top="#{MARGIN_TOP}" w:right="#{MARGIN_RIGHT}" w:bottom="#{MARGIN_BOTTOM}" w:left="#{MARGIN_LEFT}" w:header="720" w:footer="720" w:gutter="0"/>
          </w:sectPr>
        </w:body>
      </w:document>
    XML
  end

  def letterhead_table
    left_width = 4_050
    center_width = 1_764
    right_width = CONTENT_WIDTH - left_width - center_width

    <<~XML
      <w:tbl>
        <w:tblPr>
          <w:tblW w:w="#{CONTENT_WIDTH}" w:type="dxa"/>
          <w:tblLayout w:type="fixed"/>
          <w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="0" w:type="dxa"/><w:bottom w:w="0" w:type="dxa"/><w:right w:w="0" w:type="dxa"/></w:tblCellMar>
          <w:tblBorders>#{empty_borders}</w:tblBorders>
        </w:tblPr>
        <w:tblGrid><w:gridCol w:w="#{left_width}"/><w:gridCol w:w="#{center_width}"/><w:gridCol w:w="#{right_width}"/></w:tblGrid>
        <w:tr>
          <w:tc><w:tcPr><w:tcW w:w="#{left_width}" w:type="dxa"/></w:tcPr>
            #{paragraph("MOTTO:", bold: true, size: 18)}
            #{motto_lines.map.with_index { |line, index| paragraph("#{index + 1}. #{line}", size: 18) }.join}
          </w:tc>
          <w:tc><w:tcPr><w:tcW w:w="#{center_width}" w:type="dxa"/></w:tcPr>
            #{paragraph("MSJ", align: :center, bold: true, size: 20)}
            #{paragraph("印", align: :center, bold: true, size: 28)}
          </w:tc>
          <w:tc><w:tcPr><w:tcW w:w="#{right_width}" w:type="dxa"/></w:tcPr>
            #{paragraph("President : #{president_name}", align: :right, size: 18)}
            #{paragraph("Phone : #{president_phone}", align: :right, size: 18)}
            #{paragraph("Secretary : #{secretary_name}", align: :right, size: 18)}
            #{paragraph("Phone : #{secretary_phone}", align: :right, size: 18)}
          </w:tc>
        </w:tr>
      </w:tbl>
    XML
  end

  def paragraph(text, align: :left, bold: false, italic: false, size: 22, indent: nil, first_line: nil)
    escaped = xml_escape(text.to_s)
    bold_tag = bold ? "<w:b/>" : ""
    italic_tag = italic ? "<w:i/>" : ""
    align_tag = align == :left ? "" : "<w:jc w:val=\"#{align}\"/>"
    indent_attrs = []
    indent_attrs << "w:left=\"#{indent}\"" if indent
    indent_attrs << "w:firstLine=\"#{first_line}\"" if first_line
    indent_tag = indent_attrs.any? ? "<w:ind #{indent_attrs.join(" ")}/>" : ""

    <<~XML
      <w:p>
        <w:pPr>#{align_tag}#{indent_tag}<w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>
        <w:r>
          <w:rPr>#{bold_tag}#{italic_tag}<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="#{size}"/></w:rPr>
          <w:t xml:space="preserve">#{escaped}</w:t>
        </w:r>
      </w:p>
    XML
  end

  def two_column_line(left, right, left_width: 4800, left_bold: false, right_bold: false, right_align: :right)
    right_width = CONTENT_WIDTH - left_width

    <<~XML
      <w:tbl>
        <w:tblPr>
          <w:tblW w:w="#{CONTENT_WIDTH}" w:type="dxa"/>
          <w:tblLayout w:type="fixed"/>
          <w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="0" w:type="dxa"/><w:bottom w:w="0" w:type="dxa"/><w:right w:w="0" w:type="dxa"/></w:tblCellMar>
          <w:tblBorders>#{empty_borders}</w:tblBorders>
        </w:tblPr>
        <w:tblGrid><w:gridCol w:w="#{left_width}"/><w:gridCol w:w="#{right_width}"/></w:tblGrid>
        <w:tr>
          <w:tc><w:tcPr><w:tcW w:w="#{left_width}" w:type="dxa"/></w:tcPr>#{paragraph(left, bold: left_bold)}</w:tc>
          <w:tc><w:tcPr><w:tcW w:w="#{right_width}" w:type="dxa"/></w:tcPr>#{paragraph(right, align: right_align, bold: right_bold)}</w:tc>
        </w:tr>
      </w:tbl>
    XML
  end

  def signature_block
    <<~XML
      <w:tbl>
        <w:tblPr>
          <w:tblW w:w="#{CONTENT_WIDTH}" w:type="dxa"/>
          <w:tblLayout w:type="fixed"/>
          <w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="0" w:type="dxa"/><w:bottom w:w="0" w:type="dxa"/><w:right w:w="0" w:type="dxa"/></w:tblCellMar>
          <w:tblBorders>#{empty_borders}</w:tblBorders>
        </w:tblPr>
        <w:tblGrid><w:gridCol w:w="#{CONTENT_WIDTH - 2520}"/><w:gridCol w:w="2520"/></w:tblGrid>
        <w:tr>
          <w:tc><w:tcPr><w:tcW w:w="#{CONTENT_WIDTH - 2520}" w:type="dxa"/></w:tcPr>#{blank_paragraph}</w:tc>
          <w:tc><w:tcPr><w:tcW w:w="2520" w:type="dxa"/></w:tcPr>
            #{paragraph(closing, align: :center)}
            #{blank_paragraph}
            #{blank_paragraph}
            #{paragraph(signer_name, align: :center, bold: true)}
            #{paragraph(signer_title, align: :center)}
            #{paragraph(organization_name, align: :center)}
          </w:tc>
        </w:tr>
      </w:tbl>
    XML
  end

  def indented_multiline(value, indent:)
    value.to_s.split(/\r?\n/).reject(&:blank?).map { |line| paragraph(line, indent: indent) }.join
  end

  def body_paragraphs
    body.to_s.split(/\n{2,}/).map(&:strip).reject(&:blank?).map do |line|
      paragraph(line.gsub(/\r?\n/, " "), first_line: 720)
    end.join
  end

  def blank_paragraph
    "<w:p/>"
  end

  def empty_borders
    %w[top left bottom right insideH insideV].map { |side| "<w:#{side} w:val=\"nil\"/>" }.join
  end

  def horizontal_rule
    <<~XML
      <w:p>
        <w:pPr>
          <w:spacing w:before="0" w:after="180" w:line="240" w:lineRule="auto"/>
          <w:pBdr><w:bottom w:val="single" w:sz="8" w:space="1" w:color="000000"/></w:pBdr>
        </w:pPr>
      </w:p>
    XML
  end

  def xml_escape(value)
    ERB::Util.html_escape(value)
  end

  def content_types_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
        <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
      </Types>
    XML
  end

  def relationships_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
      </Relationships>
    XML
  end

  def document_relationships_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
    XML
  end

  def styles_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
          <w:name w:val="Normal"/>
          <w:rPr>
            <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
            <w:sz w:val="22"/>
          </w:rPr>
        </w:style>
      </w:styles>
    XML
  end

  def organization_name
    attributes[:organization_name].presence || self.class.default_for(:organization_name)
  end

  def organization_location
    attributes[:organization_location].presence || self.class.default_for(:organization_location)
  end

  def reference_number
    attributes[:reference_number].presence || self.class.default_for(:reference_number)
  end

  def dated_place
    attributes[:dated_place].presence || self.class.default_for(:dated_place)
  end

  def letter_date
    attributes[:letter_date].presence || self.class.default_for(:letter_date)
  end

  def president_name
    attributes[:president_name].presence || self.class.default_for(:president_name)
  end

  def president_phone
    attributes[:president_phone].presence || self.class.default_for(:president_phone)
  end

  def secretary_name
    attributes[:secretary_name].presence || self.class.default_for(:secretary_name)
  end

  def secretary_phone
    attributes[:secretary_phone].presence || self.class.default_for(:secretary_phone)
  end

  def motto_lines
    lines = attributes[:motto].to_s.split(/\r?\n/).map(&:strip).reject(&:blank?)
    return lines if lines.any?

    [
      attributes[:motto_1].presence,
      attributes[:motto_2].presence,
      attributes[:motto_3].presence
    ].compact_blank.presence || self.class.default_for(:motto).split("\n")
  end

  def recipient_block
    attributes[:recipient_block].presence || self.class.default_for(:recipient_block)
  end

  def salutation
    attributes[:salutation].presence || self.class.default_for(:salutation)
  end

  def subject
    attributes[:subject].presence || self.class.default_for(:subject)
  end

  def body
    attributes[:body].presence || self.class.default_for(:body)
  end

  def closing
    attributes[:closing].presence || self.class.default_for(:closing)
  end

  def signer_name
    attributes[:signer_name].presence || self.class.default_for(:signer_name)
  end

  def signer_title
    attributes[:signer_title].presence || self.class.default_for(:signer_title)
  end
end
