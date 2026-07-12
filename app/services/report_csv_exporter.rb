require "csv"

class ReportCsvExporter
  def self.call(headers:, rows:, summary_rows: [])
    new(headers: headers, rows: rows, summary_rows: summary_rows).call
  end

  def initialize(headers:, rows:, summary_rows: [])
    @headers = headers
    @rows = rows
    @summary_rows = summary_rows
  end

  def call
    CSV.generate do |csv|
      summary_rows.each { |row| csv << row }
      csv << [] if summary_rows.any?
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  private

  attr_reader :headers, :rows, :summary_rows
end
