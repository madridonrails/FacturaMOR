require 'rubygems'
require 'pdf/writer'

pdf = PDF::Writer.new
pdf.select_font "Helvetica"
pdf.text "Chunky Bacon!!", :font_size => 72, :justification => :center

# you can get a pointer to the object in addition to inserting it, or just throw it
img = pdf.image 'pooh.jpg', :resize => 0.75

# and reuse it later if you wish
pdf.image img, :justification => :center, :resize => 0.50
pdf.image img, :justification => :right, :resize => 0.40

pdf.text "Chunky Bacon!!", :font_size => 72, :justification => :center
pdf.save_as 'chunkybacon.pdf'