#!/usr/bin/env ruby

require 'set'

WORDSF = "words_correct.txt"
LETTERS = 5

unless File.exists?(WORDSF)
  puts "Unable to find '#{WORDSF}'."
  puts "  Try running: wget 'https://github.com/dwyl/english-words/raw/master/words_alpha.txt'"
  exit 1
end
words = File.read('words_correct.txt').split(/\s+/)
puts "Loaded #{words.count} words"
words.select! {|w| w.length == LETTERS }
puts "  #{words.count} #{LETTERS} letter words"

unless File.exists? 'bad_words.txt'
  File.open('bad_words.txt', 'wb') {}
end
rejects = Set.new(File.read('bad_words.txt').split(/\s+/))
words.reject! {|w| rejects.include? w }

word_map_sorted = {}
words.each do |w|
  word_map_sorted[w] = 0
end
chars = {}

while true do
  # Rescore remaining words by occurences of characters in all words
  char_map = Hash.new(0)
  word_map_sorted.each do |word, score|
    word.each_char do |char|
      char_map[char] += 1
    end
  end

  word_map = {}
  word_map_sorted.each do |word, score|
    score = word.chars.uniq.inject(0) do |sum, char|
      sum += char_map[char]
    end
    word_map[word] = score
  end

  word_map_sorted = word_map.sort_by(&:last)
  test_word = word_map_sorted.last

  puts "Submit #{word_map_sorted.last}..."
  puts "  Enter _ for no match."
  puts "  Enter e for position match."
  puts "  Enter m for character match."
  puts "  Enter x if the word doesn't exist"
  puts "  Enter q to quit"
  match = gets.chomp
  # match = "_m__m"
  # match = "_e___"

  return if match == 'q'

  if match == "x"
    word_map_sorted.pop
    File.open('bad_words.txt', 'a') do |fh|
      fh.puts test_word.first
    end
    next
  end

  # Set possibilities on each char
  match.chars.each_with_index do |char, idx|
    test_char = test_word.first[idx]
    if char == 'e'
      # The char exists in exactly this spot
      chars[test_char] = Set.new([idx])
    elsif char == 'm'
      # The char exists but not in this spot
      chars[test_char] ||= Set.new(LETTERS.times.to_a)
      chars[test_char].delete(idx)
    else
      # The char doesn't exist
      chars[test_char] = Set.new()
    end
  end
  # puts "Chars: #{chars}"

  # Remove possibilites that conflict with other possibilities
  change_count = 1
  i = 0
  exact_arr = []
  while change_count > 0 do
    change_count = 0
    exact = Set.new
    chars.each do |char, possible|
      exact.add(possible.first) if possible.length == 1
      exact_arr[possible.first] = char if possible.length == 1
    end

    chars.each do |char, possible|
      next if possible.length == 1
      l = possible.length
      exact.each do |n|
        possible.delete n
      end
      change_count += 1 if l != possible.length
    end
    i += 1
    raise "Too many iterations" if i > 20
  end

  puts "Chars: #{chars}"

  word_count = word_map_sorted.count

  # Filter out words that can no longer match given new conditions
  word_map_sorted.select! do |word, score|
    debug = (word == ".....")
    word_chars = word.chars.to_a
    ok = true
    word_chars.each_with_index do |char, idx|
      puts "    #{char} #{idx} #{chars[char]}" if debug
      if !exact_arr[idx].nil? && exact_arr[idx] != char
        ok = false
        break
      end
      next if chars[char].nil?
      unless chars[char].include? idx
        ok = false
        break
      end
    end
    ok
  end
  puts "Eliminated #{word_count - word_map_sorted.count} words."
  puts "#{word_map_sorted.count} words remaining."
end