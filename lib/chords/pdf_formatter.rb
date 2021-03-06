
require 'prawn'
require 'prawn/layout'

module Chords
  
  class PDFFormatter
    
    def initialize(fretboard)
      @fretboard = fretboard
    end
    
    def print(title, fingerings, opts={})
      @pdf = Prawn::Document.new(:top_margin => 50)
      @pdf.draw_text "#{title}", :at => [@pdf.margin_box.left, @pdf.margin_box.top + 30]
      @max_dist = opts[:max_fret_distance] || Fingering::DEFAULT_MAX_FRET_DISTANCE
      
      if fingerings.empty?
        @pdf.text 'No fingerings found.'
      else
        @pdf.define_grid(:columns => 4, :rows => 6, :gutter => 40)
        
        fingerings.each_with_index do |f, i|
          print_fingering(f, i)
        end
      end
      
      if opts[:inline]
        @pdf.render
      else
        @pdf.render_file('chords.pdf')
        puts "Wrote chords.pdf"
      end
    end
    
    private
    
    def string_dist(box)
      box.width / (@fretboard.open_notes.size - 1)
    end
    
    def fret_dist(box)
       box.height / (@max_dist + 1)
    end
    
    def get_box(i)
      @pdf.start_new_page if @pdf.page_count <= i / 24
      i_on_page = i % 24
      @pdf.grid(i_on_page / 4, i_on_page % 4)  
    end
    
    def fretboard_text(str, x, y)
      x_adj = str.length > 1 ? -6 : -3
      @pdf.draw_text(str, :at => [x + x_adj, y])
    end
    
    def print_fretboard(i)
      box = get_box(i)
      
      @pdf.mask(:line_width) do
        @pdf.line_width 3
        @pdf.stroke_line box.top_left, box.top_right
      end
        
      @pdf.stroke_line box.bottom_left, box.bottom_right
        
      @fretboard.open_notes.each_with_index do |note, note_i|
        x = box.left + note_i*string_dist(box)
        @pdf.stroke_line [x, box.top], [x, box.bottom]
        fretboard_text(note.title, box.left + note_i*string_dist(box), box.bottom - 11)
      end
        
      @max_dist.times do |n|
        y = box.top - ((n+1) * fret_dist(box))
        @pdf.stroke_line [box.left, y], [box.right, y]
      end
    end
    
    def print_fingering(fingering, i)
      print_fretboard(i)
      
      box = get_box(i)
      
      rad = ([fret_dist(box), string_dist(box)].min / 2) - 4
      
      fingering.each_with_index do |pos, pos_i|
        fretboard_text((pos || 'x').to_s, box.left + pos_i*string_dist(box), box.top + 4)
        
        next if [nil, 0].include?(pos)
        
        @pdf.fill_and_stroke do
          @pdf.circle_at [box.left + (pos_i * (string_dist(box))), 
                          box.top + (fret_dist(box) / 2) -
                          (fingering.relative(@max_dist)[pos_i] * fret_dist(box))], 
                          :radius => rad
        end        
      end
    end
  end
  
end