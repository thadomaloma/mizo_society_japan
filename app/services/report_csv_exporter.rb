require "csv"

class ReportCsvExporter
  FORMULA_PREFIX = /\A[=+\-@]/

  def self.call(headers:, rows:, summary_rows: [], bom: false)
    new(headers: headers, rows: rows, summary_rows: summary_rows, bom: bom).call
  end

  def initialize(headers:, rows:, summary_rows: [], bom: false)
    @headers = headers
    @rows = rows
    @summary_rows = summary_rows
    @bom = bom
  end

  def call
    CSV.generate(bom ? String.new("\uFEFF") : String.new) do |csv|
      summary_rows.each { |row| csv << safe_row(row) }
      csv << [] if summary_rows.any?
      csv << safe_row(headers)
      rows.each { |row| csv << safe_row(row) }
    end
  end

  private

  attr_reader :headers, :rows, :summary_rows, :bom

  def safe_row(row)
    row.map do |value|
      value.is_a?(String) && value.match?(FORMULA_PREFIX) ? "'#{value}" : value
    end
  end
end
