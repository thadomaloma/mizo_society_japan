require "digest"
require "nokogiri"
require "zlib"

class MeetingMinutePdfBuilder
  PAGE_WIDTH = 595.28
  PAGE_HEIGHT = 841.89
  MARGIN = 56
  LINE_HEIGHT = 16

  def self.call(meeting_minute)
    new(meeting_minute).call
  end

  def initialize(meeting_minute)
    @meeting_minute = meeting_minute
    @pages = []
    @images = []
  end

  def call
    start_page
    centered "MIZO SOCIETY OF JAPAN", size: 17, bold: true
    move_down 10
    centered @meeting_minute.title.to_s.upcase, size: 14, bold: true
    move_down 24

    detail_line "A Hun (Date & Time):", "#{@meeting_minute.meeting_date.strftime("%d/%m/%Y")}, #{@meeting_minute.meeting_time_label}"
    detail_line "A Hmun (Venue):", @meeting_minute.venue.presence || "-"
    move_down 18

    section "Kal zat (Members Present)"
    numbered_users(present_users, "No present members recorded.")

    section "Member pha (Members Apology)"
    numbered_users(absent_users, "No apologies recorded.")

    section "I. PROGRAMME TLANGPUI"
    paragraph "Hun serh / Tawngtaina: #{@meeting_minute.opening_prayer}" if @meeting_minute.opening_prayer.present?
    paragraph "Chairman Thuhmahrui: #{@meeting_minute.welcome_speech}" if @meeting_minute.welcome_speech.present?
    labeled_block "Previous Minute Approval", @meeting_minute.previous_minutes_approval
    labeled_block "Reports", @meeting_minute.reports
    labeled_block "Agenda", rich_text_to_plain(@meeting_minute.summary)

    if @meeting_minute.decisions.present?
      section "II. THU RELTE (RESOLUTIONS)"
      formatted_decisions_block @meeting_minute.decisions
    end

    section "MEETING KHARNA"
    text_block @meeting_minute.adjournment.presence || "Minute ngaihthlakna kan nei a, siam rem ngai te kan siam rem. Meeting chu tawngtaina hmanga khar a ni."
    signature_blocks

    build_pdf
  end

  private

  def present_users
    @meeting_minute.meeting_minute_attendances.select { |attendance| attendance.status == "present" }.map(&:user)
  end

  def absent_users
    @meeting_minute.meeting_minute_attendances.select { |attendance| attendance.status == "absent" }.map(&:user)
  end

  def start_page
    @current_content = +""
    @cursor_y = PAGE_HEIGHT - MARGIN
    @pages << @current_content
  end

  def ensure_space(height)
    return if @cursor_y - height >= MARGIN

    start_page
  end

  def move_down(points)
    ensure_space(points)
    @cursor_y -= points
  end

  def centered(text, size:, bold: false)
    ensure_space(size + 6)
    draw_text(text, PAGE_WIDTH / 2, @cursor_y, size: size, bold: bold, align: :center)
    @cursor_y -= size + 8
  end

  def section(title)
    move_down 10
    ensure_space 26
    draw_text(title, MARGIN, @cursor_y, size: 13, bold: true)
    @cursor_y -= 22
  end

  def labeled_block(label, value)
    return if value.blank?

    paragraph "#{label}:"
    text_block value, indent: 14
  end

  def paragraph(text, bold_label: false)
    return if text.blank?

    lines = wrap(text)
    lines.each_with_index do |line, index|
      ensure_space LINE_HEIGHT
      draw_text(line, MARGIN, @cursor_y, size: 11, bold: bold_label && index.zero?)
      @cursor_y -= LINE_HEIGHT
    end
  end

  def detail_line(label, value)
    ensure_space LINE_HEIGHT
    draw_text(label, MARGIN, @cursor_y, size: 11, bold: true)
    draw_text(value, MARGIN + approximate_text_width(label, 11) + 10, @cursor_y, size: 11)
    @cursor_y -= LINE_HEIGHT
  end

  def text_block(text, indent: 0, bold_heading_lines: false)
    plain_text_lines(text).each do |line|
      if line.blank?
        move_down 8
        next
      end

      wrap(line, width: 84 - (indent / 5)).each do |wrapped_line|
        ensure_space LINE_HEIGHT
        draw_text(wrapped_line, MARGIN + indent, @cursor_y, size: 11, bold: bold_heading_lines && heading_line?(line))
        @cursor_y -= LINE_HEIGHT
      end
    end
  end

  def formatted_decisions_block(content)
    decision_rich_lines(content).each do |runs|
      if runs.blank?
        move_down 8
        next
      end

      draw_rich_runs(runs)
    end
  end

  def decision_rich_lines(content)
    fragment = Nokogiri::HTML.fragment(content.to_s.gsub(/&nbsp;|\u00A0/, " "))
    nodes = fragment.children.flat_map do |node|
      node.text? ? node.text.split("\n").map { |text| Nokogiri::XML::Text.new(text, fragment.document) } : [ node ]
    end

    nodes.filter_map do |node|
      runs = decision_node_runs(node)
      runs if runs.any? { |run| run[:text].present? }
    end
  end

  def decision_node_runs(node, bold: false)
    return [ { text: node.text.to_s, bold: bold } ] if node.text?
    return [ { text: "\n", bold: false } ] if node.name == "br"

    node.children.flat_map do |child|
      decision_node_runs(child, bold: bold || node.name.in?([ "strong", "b" ]))
    end
  end

  def draw_rich_runs(runs)
    wrap_rich_runs(runs).each do |line_runs|
      ensure_space LINE_HEIGHT
      draw_pdf_rich_line(line_runs, MARGIN, @cursor_y, size: 11)
      @cursor_y -= LINE_HEIGHT
    end
  end

  def wrap_rich_runs(runs, width: 84)
    lines = [ [] ]
    line_length = 0

    runs.each do |run|
      run[:text].to_s.scan(/\S+\s*|\s+/).each do |token|
        if line_length.positive? && line_length + token.length > width && token.strip.present?
          lines << []
          line_length = 0
          token = token.lstrip
        end

        next if token.blank? && line_length.zero?

        append_rich_run(lines.last, token, run[:bold])
        line_length += token.length
      end
    end

    lines.reject(&:blank?)
  end

  def append_rich_run(line, text, bold)
    if line.last&.dig(:bold) == bold
      line.last[:text] << text
    else
      line << { text: text.dup, bold: bold }
    end
  end

  def draw_pdf_rich_line(runs, x, y, size:)
    @current_content << "BT #{format('%.2f', x)} #{format('%.2f', y)} Td "
    runs.each do |run|
      font = run[:bold] ? "F2" : "F1"
      text = escape_pdf_string(pdf_safe_text(run[:text]))
      @current_content << "/#{font} #{size} Tf (#{text}) Tj "
    end
    @current_content << "ET\n"
  end

  def numbered_users(users, empty_message)
    if users.any?
      users.each_with_index { |user, index| paragraph "#{index + 1}. #{user.display_name}" }
    else
      paragraph empty_message
    end
    move_down 8
  end

  def signature_blocks
    move_down 44
    ensure_space 104

    content_width = PAGE_WIDTH - (MARGIN * 2)
    left_x = MARGIN + (content_width * 0.25)
    right_x = MARGIN + (content_width * 0.75)
    signature_block(
      left_x,
      @meeting_minute.chairman_signature_display_name,
      @meeting_minute.chairman_signature_display_title,
      attachment: @meeting_minute.chairman_signature
    )
    signature_block(
      right_x,
      @meeting_minute.secretary_signature_display_name,
      @meeting_minute.secretary_signature_display_title,
      attachment: @meeting_minute.secretary_signature
    )
    @cursor_y -= 96
  end

  def signature_block(x, name, title, attachment:)
    signature_drawn = draw_signature_image(attachment, x, @cursor_y, name)
    draw_text("Sd/-", x, @cursor_y + 20, size: 11, align: :center) unless signature_drawn
    draw_text(name.to_s.upcase, x, @cursor_y - 34, size: 10.5, bold: true, align: :center)
    draw_text(title, x, @cursor_y - 50, size: 10.5, align: :center)
    draw_text("Mizo Society of Japan", x, @cursor_y - 66, size: 10.5, align: :center)
  end

  def draw_signature_image(attachment, center_x, baseline_y, display_name)
    return false unless attachment&.attached?

    image = prepared_pdf_image(attachment)
    return false if image.blank?

    max_width = signature_image_width_for(display_name)
    max_height = 56.0
    scale = [ max_width / image[:width], max_height / image[:height], 1.0 ].min
    width = image[:width] * scale
    height = image[:height] * scale
    x = center_x - (width / 2)
    y = baseline_y - 2

    image_name = register_image(image)
    @current_content << "q #{format('%.2f', width)} 0 0 #{format('%.2f', height)} #{format('%.2f', x)} #{format('%.2f', y)} cm /#{image_name} Do Q\n"
    true
  rescue StandardError
    false
  end

  def signature_image_width_for(display_name)
    name_width = approximate_text_width(display_name.to_s.upcase, 10.5)
    [ [ name_width * 1.4, 120.0 ].max, 210.0 ].min
  end

  def draw_text(text, x, y, size:, bold: false, align: :left)
    normalized = pdf_safe_text(text)
    approximate_width = approximate_text_width(normalized, size)
    adjusted_x = align == :center ? x - (approximate_width / 2) : x
    font = bold ? "F2" : "F1"
    @current_content << "BT /#{font} #{size} Tf #{format("%.2f", adjusted_x)} #{format("%.2f", y)} Td (#{escape_pdf_string(normalized)}) Tj ET\n"
  end

  def plain_text_lines(text)
    text.to_s.lines.map(&:strip)
  end

  def rich_text_to_plain(content)
    html = content.to_s.gsub(/&nbsp;|\u00A0/, " ")
      .gsub(%r{</(?:div|p|li)>}i, "\n")
      .gsub(%r{<br\s*/?>}i, "\n")
      .gsub(%r{<li>}i, "- ")

    ActionView::Base.full_sanitizer.sanitize(html).lines.map(&:strip).reject(&:blank?).join("\n")
  end

  def wrap(text, width: 90)
    words = text.to_s.split(/\s+/)
    return [ "" ] if words.empty?

    words.each_with_object([ +"" ]) do |word, lines|
      if "#{lines.last} #{word}".strip.length > width
        lines << word.dup
      else
        lines.last << " " unless lines.last.empty?
        lines.last << word
      end
    end
  end

  def pdf_safe_text(text)
    text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
  end

  def escape_pdf_string(text)
    text.gsub("\\", "\\\\\\").gsub("(", "\\(").gsub(")", "\\)")
  end

  def heading_line?(line)
    line.to_s.match?(/\A\s*(?:\d+[\.)]\s*)?.+:\s*\z/)
  end

  def approximate_text_width(text, size)
    text.each_char.sum do |character|
      width_factor =
        case character
        when " " then 0.28
        when /[ilI\.,'\/]/ then 0.25
        when /[MW]/ then 0.86
        when /[A-Z]/ then 0.62
        when /[0-9]/ then 0.55
        else 0.50
        end

      width_factor * size
    end
  end

  def build_pdf
    assign_image_object_ids
    objects = []
    objects << "<< /Type /Catalog /Pages 2 0 R >>"
    page_object_ids = @pages.each_index.map { |index| 3 + (index * 2) }
    objects << "<< /Type /Pages /Kids [#{page_object_ids.map { |id| "#{id} 0 R" }.join(" ")}] /Count #{@pages.size} >>"
    image_resource_dictionary = image_resources

    @pages.each_with_index do |content, index|
      page_object_id = 3 + (index * 2)
      content_object_id = page_object_id + 1
      objects << "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{PAGE_WIDTH} #{PAGE_HEIGHT}] /Resources << /Font << /F1 #{font_regular_object_id} 0 R /F2 #{font_bold_object_id} 0 R >>#{image_resource_dictionary} >> /Contents #{content_object_id} 0 R >>"
      objects << "<< /Length #{content.bytesize} >>\nstream\n#{content}endstream"
    end

    objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
    objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>"
    @images.each do |image|
      objects << pdf_image_object(image)
      objects << pdf_image_object(image[:smask]) if image[:smask].present?
    end

    serialize_pdf(objects)
  end

  def font_regular_object_id
    3 + (@pages.size * 2)
  end

  def font_bold_object_id
    font_regular_object_id + 1
  end

  def first_image_object_id
    font_bold_object_id + 1
  end

  def image_resources
    return "" if @images.empty?

    xobjects = @images.map do |image|
      "/#{image[:name]} #{image[:object_id]} 0 R"
    end.join(" ")

    " /XObject << #{xobjects} >>"
  end

  def assign_image_object_ids
    object_id = first_image_object_id
    @images.each do |image|
      image[:object_id] = object_id
      object_id += 1
      next unless image[:smask].present?

      image[:smask][:object_id] = object_id
      object_id += 1
    end
  end

  def pdf_image_object(image)
    smask = image[:smask].present? ? " /SMask #{image[:smask][:object_id]} 0 R" : ""
    image_object = +"<< /Type /XObject /Subtype /Image /Width #{image[:width]} /Height #{image[:height]} /ColorSpace /#{image[:color_space]} /BitsPerComponent 8 /Interpolate false /Filter /#{image[:filter]}#{smask} /Length #{image[:data].bytesize} >>\nstream\n".b
    image_object << image[:data]
    image_object << "\nendstream".b
    image_object
  end

  def register_image(image)
    existing = @images.find { |stored_image| stored_image[:checksum] == image[:checksum] }
    return existing[:name] if existing

    image[:name] = "Im#{@images.size + 1}"
    @images << image
    image[:name]
  end

  def prepared_pdf_image(attachment)
    source = attachment.blob.download
    if source.start_with?("\x89PNG\r\n\x1A\n".b)
      parse_png_image(source)
    elsif source.start_with?("\xFF\xD8".b)
      parse_jpeg_image(source)
    end
  end

  def parse_jpeg_image(source)
    width, height = jpeg_dimensions(source)
    return if width.blank? || height.blank?

    {
      data: source.b,
      width: width,
      height: height,
      color_space: "DeviceRGB",
      filter: "DCTDecode",
      checksum: Digest::SHA256.hexdigest(source)
    }
  end

  def parse_png_image(source)
    chunks = png_chunks(source)
    ihdr = chunks.find { |chunk| chunk[:type] == "IHDR" }&.dig(:data)
    return if ihdr.blank?

    width, height, bit_depth, color_type, compression, filter_method, interlace = ihdr.unpack("NNCCCCC")
    return unless bit_depth == 8 && compression.zero? && filter_method.zero? && interlace.zero?

    palette = chunks.find { |chunk| chunk[:type] == "PLTE" }&.dig(:data)
    transparency = chunks.find { |chunk| chunk[:type] == "tRNS" }&.dig(:data)
    compressed = chunks.select { |chunk| chunk[:type] == "IDAT" }.map { |chunk| chunk[:data] }.join.b
    raw = Zlib::Inflate.inflate(compressed)
    components = png_scanlines_to_pdf_components(raw, width, height, color_type, palette, transparency)
    return if components.blank?

    data = Zlib::Deflate.deflate(components[:color])
    alpha_data = components[:alpha].present? ? Zlib::Deflate.deflate(components[:alpha]) : nil
    {
      data: data.b,
      width: width,
      height: height,
      color_space: components[:color_space],
      filter: "FlateDecode",
      checksum: Digest::SHA256.hexdigest([ data, alpha_data ].compact.join),
      smask: alpha_data.present? ? {
        data: alpha_data.b,
        width: width,
        height: height,
        color_space: "DeviceGray",
        filter: "FlateDecode"
      } : nil
    }
  rescue Zlib::Error
    nil
  end

  def png_chunks(source)
    chunks = []
    offset = 8
    while offset < source.bytesize
      length = source.byteslice(offset, 4).unpack1("N")
      type = source.byteslice(offset + 4, 4)
      data = source.byteslice(offset + 8, length).to_s.b
      chunks << { type: type, data: data }
      offset += 12 + length
      break if type == "IEND"
    end
    chunks
  end

  def png_scanlines_to_pdf_components(raw, width, height, color_type, palette, transparency)
    channels = png_channels(color_type)
    return if channels.blank?

    bytes_per_pixel = channels
    row_bytes = width * bytes_per_pixel
    previous = Array.new(row_bytes, 0)
    offset = 0
    color = +"".b
    alpha = +"".b

    height.times do
      filter_type = raw.getbyte(offset)
      offset += 1
      encoded = raw.byteslice(offset, row_bytes).bytes
      offset += row_bytes
      decoded = png_unfilter(encoded, previous, bytes_per_pixel, filter_type)
      row_components = png_row_to_pdf_components(decoded, color_type, palette, transparency)
      color << row_components[:color]
      alpha << row_components[:alpha].to_s.b
      previous = decoded
    end

    {
      color: color,
      alpha: alpha.bytesize.positive? ? alpha : nil,
      color_space: png_pdf_color_space(color_type)
    }
  end

  def png_channels(color_type)
    {
      0 => 1,
      2 => 3,
      3 => 1,
      4 => 2,
      6 => 4
    }[color_type]
  end

  def png_unfilter(row, previous, bytes_per_pixel, filter_type)
    decoded = Array.new(row.length, 0)

    row.each_index do |index|
      left = index >= bytes_per_pixel ? decoded[index - bytes_per_pixel] : 0
      up = previous[index] || 0
      up_left = index >= bytes_per_pixel ? previous[index - bytes_per_pixel].to_i : 0

      value = case filter_type
      when 0 then row[index]
      when 1 then row[index] + left
      when 2 then row[index] + up
      when 3 then row[index] + ((left + up) / 2).floor
      when 4 then row[index] + png_paeth(left, up, up_left)
      else row[index]
      end

      decoded[index] = value & 0xff
    end

    decoded
  end

  def png_paeth(left, up, up_left)
    estimate = left + up - up_left
    left_distance = (estimate - left).abs
    up_distance = (estimate - up).abs
    up_left_distance = (estimate - up_left).abs

    return left if left_distance <= up_distance && left_distance <= up_left_distance
    return up if up_distance <= up_left_distance

    up_left
  end

  def png_pdf_color_space(color_type)
    color_type.in?([ 0, 4 ]) ? "DeviceGray" : "DeviceRGB"
  end

  def png_row_to_pdf_components(row, color_type, palette, transparency)
    color = +"".b
    alpha = +"".b

    case color_type
    when 0
      transparent_gray = png_transparent_gray(transparency)
      row.each do |gray|
        color << gray
        alpha << (transparent_gray == gray ? 0 : 255) if transparent_gray.present?
      end
    when 2
      transparent_rgb = png_transparent_rgb(transparency)
      row.each_slice(3) do |red, green, blue|
        color << red << green << blue
        alpha << (transparent_rgb == [ red, green, blue ] ? 0 : 255) if transparent_rgb.present?
      end
    when 3
      palette_alpha = png_palette_alpha(transparency)
      row.each do |index|
        offset = index * 3
        red, green, blue = palette.to_s.byteslice(offset, 3).to_s.b.bytes
        red ||= 255
        green ||= 255
        blue ||= 255
        color << red << green << blue
        alpha << palette_alpha.fetch(index, 255) if palette_alpha.present?
      end
    when 4
      row.each_slice(2) do |gray, alpha_value|
        color << gray
        alpha << alpha_value
      end
    when 6
      row.each_slice(4) do |red, green, blue, alpha_value|
        color << red << green << blue
        alpha << alpha_value
      end
    end

    { color: color, alpha: alpha }
  end

  def png_palette_alpha(transparency)
    return {} if transparency.blank?

    transparency.bytes.each_with_index.to_h { |alpha, index| [ index, alpha ] }
  end

  def png_transparent_gray(transparency)
    return if transparency.blank? || transparency.bytesize < 2

    transparency.unpack1("n")
  end

  def png_transparent_rgb(transparency)
    return if transparency.blank? || transparency.bytesize < 6

    transparency.unpack("nnn")
  end

  def jpeg_dimensions(source)
    offset = 2
    while offset < source.bytesize
      offset += 1 while source.getbyte(offset) == 0xff
      marker = source.getbyte(offset)
      offset += 1
      next if marker == 0xd8 || marker == 0xd9

      length = source.byteslice(offset, 2).unpack1("n")
      return if length.blank? || length < 2

      if marker.in?([ 0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf ])
        height, width = source.byteslice(offset + 3, 4).unpack("nn")
        return [ width, height ]
      end

      offset += length
    end
  end

  def serialize_pdf(objects)
    pdf = +"%PDF-1.4\n".b
    offsets = [ 0 ]

    objects.each_with_index do |object, index|
      offsets << pdf.bytesize
      pdf << "#{index + 1} 0 obj\n".b
      pdf << object.to_s.b
      pdf << "\nendobj\n".b
    end

    xref_offset = pdf.bytesize
    pdf << "xref\n0 #{objects.size + 1}\n".b
    pdf << "0000000000 65535 f \n".b
    offsets.drop(1).each { |offset| pdf << format("%010d 00000 n \n", offset).b }
    pdf << "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref_offset}\n%%EOF\n".b
    pdf
  end
end
