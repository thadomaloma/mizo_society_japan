require "test_helper"
require "csv"

class ReportCsvExporterTest < ActiveSupport::TestCase
  test "protects spreadsheet users from formula injection" do
    output = ReportCsvExporter.call(
      headers: [ "Description" ],
      rows: [ [ "=HYPERLINK(\"https://example.test\")" ], [ "+SUM(1,1)" ] ]
    )

    rows = CSV.parse(output)
    assert_equal "'=HYPERLINK(\"https://example.test\")", rows[1][0]
    assert_equal "'+SUM(1,1)", rows[2][0]
  end

  test "can prefix UTF-8 output with an Excel-compatible byte order mark" do
    output = ReportCsvExporter.call(headers: [ "Name" ], rows: [ [ "Mizo Society of Japan" ] ], bom: true)

    assert output.start_with?("\uFEFF")
    assert_equal [ [ "Name" ], [ "Mizo Society of Japan" ] ], CSV.parse(output.delete_prefix("\uFEFF"))
  end
end
