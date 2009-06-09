$KCODE = 'u'

require 'rubygems'
require 'pdf/writer'
require 'pdf/simpletable'
require 'iconv'

pdf = PDF::Writer.new
pdf.select_font 'Helvetica'

pdf.text Iconv.iconv('UTF-16BE', 'UTF-8', 'áéíóú')

PDF::SimpleTable.new do |t|
  t.columns[:test] = PDF::SimpleTable::Column.new(:test) do |c|
    c.heading = Iconv.iconv('UTF-16BE', 'UTF-8', 'áéíóú €')
  end
  t.column_order = [:test]
  t.data = [{:test => Iconv.iconv('UTF-16BE', 'UTF-8', 'áéíóú')}]
  t.render_on(pdf)
end

pdf.save_as('simple_table_with_unicode.pdf')