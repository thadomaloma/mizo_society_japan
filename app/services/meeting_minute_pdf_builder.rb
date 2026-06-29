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
  end

  def call
    start_page
    centered "MIZO SOCIETY OF JAPAN", size: 17, bold: true
    move_down 10
    centered @meeting_minute.title.to_s.upcase, size: 14, bold: true
    move_down 24

    detail_line "A Hun (Date & Time):", "#{@meeting_minute.meeting_date.strftime("%d/%m/%Y")}, #{@meeting_minute.meeting_time_label}"
    detail_line "A Hmun (Venue):", @meeting_minute.venue.presence || "-"
    detail_line "Chairman:", @meeting_minute.chairman.presence || "-"
    detail_line "Secretary:", @meeting_minute.minute_recorder.presence || "-"
    detail_line "Opening Prayer:", @meeting_minute.opening_prayer if @meeting_minute.opening_prayer.present?
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
      text_block rich_text_to_plain(@meeting_minute.decisions), bold_heading_lines: true
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
    draw_text(value, MARGIN + approximate_text_width(label, 11) + 5, @cursor_y, size: 11)
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

  def numbered_users(users, empty_message)
    if users.any?
      users.each_with_index { |user, index| paragraph "#{index + 1}. #{user.display_name}" }
    else
      paragraph empty_message
    end
    move_down 8
  end

  def signature_blocks
    move_down 52
    ensure_space 90

    content_width = PAGE_WIDTH - (MARGIN * 2)
    left_x = MARGIN + (content_width * 0.25)
    right_x = MARGIN + (content_width * 0.75)
    signature_block(left_x, @meeting_minute.chairman_signature_display_name, @meeting_minute.chairman_signature_display_title)
    signature_block(right_x, @meeting_minute.secretary_signature_display_name, @meeting_minute.secretary_signature_display_title)
    @cursor_y -= 84
  end

  def signature_block(x, name, title)
    draw_text("Sd/-", x, @cursor_y, size: 11, align: :center)
    draw_text(name.to_s.upcase, x, @cursor_y - 28, size: 11, bold: true, align: :center)
    draw_text(title, x, @cursor_y - 44, size: 11, align: :center)
    draw_text("Mizo Society of Japan", x, @cursor_y - 60, size: 11, align: :center)
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

    words.each_with_object([ +""]) do |word, lines|
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
    objects = []
    objects << "<< /Type /Catalog /Pages 2 0 R >>"
    page_object_ids = @pages.each_index.map { |index| 3 + (index * 2) }
    objects << "<< /Type /Pages /Kids [#{page_object_ids.map { |id| "#{id} 0 R" }.join(" ")}] /Count #{@pages.size} >>"

    @pages.each_with_index do |content, index|
      page_object_id = 3 + (index * 2)
      content_object_id = page_object_id + 1
      objects << "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{PAGE_WIDTH} #{PAGE_HEIGHT}] /Resources << /Font << /F1 #{font_regular_object_id} 0 R /F2 #{font_bold_object_id} 0 R >> >> /Contents #{content_object_id} 0 R >>"
      objects << "<< /Length #{content.bytesize} >>\nstream\n#{content}endstream"
    end

    objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
    objects << "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>"

    serialize_pdf(objects)
  end

  def font_regular_object_id
    3 + (@pages.size * 2)
  end

  def font_bold_object_id
    font_regular_object_id + 1
  end

  def serialize_pdf(objects)
    pdf = +"%PDF-1.4\n"
    offsets = [ 0 ]

    objects.each_with_index do |object, index|
      offsets << pdf.bytesize
      pdf << "#{index + 1} 0 obj\n#{object}\nendobj\n"
    end

    xref_offset = pdf.bytesize
    pdf << "xref\n0 #{objects.size + 1}\n"
    pdf << "0000000000 65535 f \n"
    offsets.drop(1).each { |offset| pdf << format("%010d 00000 n \n", offset) }
    pdf << "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref_offset}\n%%EOF\n"
    pdf
  end
end
