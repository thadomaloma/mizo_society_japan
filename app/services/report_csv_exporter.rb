require "csv"

class ReportCsvExporter
  def self.call(headers:, rows:)
    new(headers: headers, rows: rows).call
  end

  def initialize(headers:, rows:)
    @headers = headers
    @rows = rows
  end

  def call
    CSV.generate(headers: true) do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end

  private

  attr_reader :headers, :rows
end
