  $KCODE = 'u'

  require 'rubygems'
  require 'pdf/writer'
  require 'iconv'

  str = Iconv.iconv('UTF-16BE', 'UTF-8', 'á ß €')
  pdf = PDF::Writer.new
  pdf.text str
  pdf.text "\xfe\xff#{str}"
  pdf.save_as('unicode_test.pdf')

