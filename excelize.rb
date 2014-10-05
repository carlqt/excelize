class Excelize
  require 'csv'
  require 'amatch'
  require 'tempfile'
  require 'fileutils'

  include Amatch

  def initialize(filename)
    @file = CSV.read(filename, headers: true, encoding: 'ISO-8859-1')
    @filename = filename
    @keyword_list = []
    @file.each do |file|
      @keyword_list << file.to_s.chomp
    end
    # puts FuzzyMatch.new(filename).find match
  end

  def show_all
    @file.each do |csv|
      puts csv.to_s.chomp
    end
  end

  def show_lines(num = 1)
    if num.is_a? Range
      num.each { |index| puts @file[index].to_s.chomp }
    else
      (0...num).each { |index| puts @file[index].to_s.chomp }
    end
  end

  def show(num)
    @file.values_at(num-1).join.chomp
  end

  def total
    @file.size
  end

  def matches(str)
    # fuzzy_match = FuzzyMatch.new(@file).find_all str
    @all_matches = []


    @file.each_with_index do |file, index|
      jaro_winkler = JaroWinkler.new str
      
      if jaro_winkler.match(file.to_s).between?(0.75, 1)
        file_match = file.to_s.chomp.scan(to_regex(str))
        if !file_match.empty? && match_score(file_match.size, str.split.size).between?(50, 100)
          @all_matches << "#{index + 1}: #{file.to_s.chomp}"
        end
      end
    end

    @all_matches
  end

  def delete(*args)
    begin
      temp = Tempfile.new("temp")
      delete_messages = []

      args.flatten.reverse_each do |index|
        delete_messages << @file.values_at(index - 1).join.chomp
        @file.delete index - 1
      end

      temp.puts @file.headers.join
      @file.each do |file|
        temp.puts file
      end

    rescue Exception => e
      puts "An error has occured: #{e}"
    ensure
      temp.close
      FileUtils.mv(temp.path, @filename)
    end
    delete_messages.each { |msg| puts "Deleted: #{msg}" }
    initialize(@filename)

  end

  def delete_matches

    if !@all_matches.empty?
      matched_indices = @all_matches.map { |match| match.scan(/^\d+/).first.to_i }
      delete matched_indices
      @all_matches.clear
    else
      "No match yet"
    end

  end

  private

  def to_regex(pattern_string)
    /(#{pattern_string.gsub(' ', '|')})/
  end

  def match_score(numerator, denominator)
    (numerator / denominator) * 100
  end



end