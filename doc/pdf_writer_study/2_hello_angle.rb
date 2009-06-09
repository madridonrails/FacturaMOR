require 'rubygems'
require 'pdf/writer'

pdf = PDF::Writer.new
pdf.select_font "Helvetica"
x = pdf.absolute_left_margin
y = pdf.absolute_bottom_margin

# 72 is the text size, 45 is the angle, counter-clockwise
pdf.add_text x, y, 'Hello, Ruby', 72, 45
pdf.save_as 'hello_angle.pdf'