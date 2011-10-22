module Img2Html
  class Encoder
    def initialize(path)
      @image = Candela.open(path)
      @data = @image.data
      @table = []
      @names = {}
      @sequence = "a"
      @rows = @data.rows
      @cols = @data.columns
    end

    def encode
      read_image_data
      calculate_horizontal_rle
      calculate_vertical_rle
      create_html
    end

    def read_image_data
      @rows.each do |y|
        row = []
        @cols.each do |x|
          color = @data[x, y].to_hex[0...6]

          if color == "ffffff"
            name = nil
          elsif @names.include? color
            name = @names[color]
          else
            name = @names[color] = @sequence
            @sequence = @sequence.succ
          end

          row << [name, 1, 1]
        end
        @table << row
      end
    end

    def calculate_horizontal_rle
      @rows.each do |y|
        last_cell = nil
        @cols.each do |x|
          cell = @table[y][x]
          if y > 0 && x > 0 && cell && last_cell && last_cell[0] == cell[0] && last_cell[2] == cell[2]
            last_cell[1] += 1
            @table[y][x] = nil
          else
            last_cell = cell
          end
        end
      end
    end

    def calculate_vertical_rle
      @cols.each do |x|
        last_cell = nil
        @rows.each do |y|
          cell = @table[y][x]
          if y > 0 && x > 0 && cell && last_cell && last_cell[0] == cell[0] && last_cell[1] == cell[1]
            last_cell[2] += 1
            @table[y][x] = nil
          else
            last_cell = cell
          end
        end
      end
    end

    def create_html
      template.result(binding).gsub(/>\s+/m, ">").gsub(/\s+<([^a%])/m, "<\\1").gsub(/\}\s+([\w.])/, "}\\1")
    end

    def create_html_table
      image_table = %Q(<table>)
      @table.each do |row|
        image_table << "<tr>"
        row.each do |cell|
          next unless cell
          name, collen, rowlen = *cell
          cssclass = name ? %Q( class=#{name}):""
          colspan = collen > 1 ? %Q( colspan=#{collen}):""
          rowspan = rowlen > 1 ? %Q( rowspan=#{rowlen}):""
          image_table << "<td#{cssclass}#{colspan}#{rowspan}></td>"
        end
        image_table << "</tr>\n"
      end
      image_table << "</table>"
      image_table
    end

    def create_css_styles
      @names.collect do |color, name|
        ".#{name}{background:##{color}}"
      end.join
    end

    def template
      ERB.new <<-ERB
  <!DOCTYPE html>
  <html>
    <head>
      <title></title>
      <style type=text/css>
        table{margin:0 auto;border-collapse:collapse;border-spacing:0}
        td{padding:0;width:1px;height:1px;font-size:0;line-height:0}
        <%= create_css_styles %>
      </style>
    </head>
    <body>
      <div class=v>
        <div class=w>
          <%= create_html_table %>
        </div>
      </div>
    </body>
  </html>
      ERB
    end
  end
end
