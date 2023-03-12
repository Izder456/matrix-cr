require "option_parser"

module I::Terminal
  lib C
    struct Winsize
      ws_row : UInt16 # rows, in characters
      ws_col : UInt16 # columns, in characters
    end

    fun ioctl(fd : Int32, request : UInt32, winsize : C::Winsize*) : Int32
  end

  def self.get_size() : Array(Int32)
    C.ioctl(0, 21523, out size)
    [size.ws_row.to_i, size.ws_col.to_i] 
  end
end     


class MatrixVisuals
  
  @screen_width : Int32 
  @screen_height : Int32
  @scroll_columns : Array(Int32)

  def initialize(bold : Bool, exclusively_bold : Bool, color : Int32)
    @bold = bold
    @exclusively_bold = exclusively_bold
    @color = color
    @bold_chars = ["\e[#{color}m█\e[0m", "\e[#{color}m▓\e[0m", "\e[#{color}m▒\e[0m", "\e[#{color}m░\e[0m"]
    @regular_chars = ["\e[#{color}mX\e[0m", "\e[#{color}mx\e[0m", "\e[#{color}m*\e[0m"]
    @screen_width, @screen_height = I::Terminal.get_size()
    @scroll_delay = 0.01
    @scroll_columns = Array.new(@screen_width) { rand(@screen_height) }
  end

  def display
    loop do
      @screen_height.times do |y|
        line = ""
        @screen_width.times do |x|
          char = get_char(x, y)
          line += char
        end
        puts line
      end
      update_scroll_columns
      sleep @scroll_delay
      clear_screen
    end
  end

  def get_char(x, y)
    chars = @bold ? (@exclusively_bold ? @bold_chars.sample(1) : @bold_chars.sample(3)) : @regular_chars
    char = chars[@scroll_columns[x] == y ? 0 : rand(chars.size)]
    char =~ /[ -~]/ ? char : " "
  end

  def update_scroll_columns
    @scroll_columns.each_with_index do |row, i|
      @scroll_columns[i] = row + 1
      @scroll_columns[i] = 0 if @scroll_columns[i] >= @screen_height
    end
  end

  def clear_screen
    print "\e[2J\e[H"
  end
end

bold = false
exclusively_bold = false

OptionParser.parse do |opts|
  opts.on("-b", "--bold", "Use bold characters in output") do
    bold = true
  end

  opts.on("-B", "--exclusively-bold", "Use exclusively bold characters in output (overrides -b)") do
    exclusively_bold = true
  end

  opts.on("-n", "--no-bold", "Do not use bold characters in output") do
    bold = false
    exclusively_bold = false
  end

  opts.on("-h", "--help", "Print usage information and exit") do
    puts opts
    exit
  end

  opts.on("-V", "--version", "Print version information and exit") do
      puts "MatrixVisuals v0.0.1"
    exit
  end
end

matrix = MatrixVisuals.new(bold: bold, exclusively_bold: exclusively_bold, color: 32)
matrix.display
