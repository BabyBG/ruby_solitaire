# TO DO:

# Cannot move to empty columns 
# Deck repeats once at end of cycle

require 'colorize'
require 'pry'

class Card
  attr_reader :value, :suit, :name
  attr_accessor :moveable

  def initialize(value, suit)
    @value = value
    @suit = suit
    @moveable = false
    @name = num_to_face(value).concat(suit)
  end
  
  @total_in_foundation = 0

  class << self
    attr_accessor :total_in_foundation
  end
end

#main game sequence
def play_solitaire

  #assign cards to deck, columns, set card visibility, create foundation stacks
  suits = ["d", "c", "h", "s"]
  $all_cards = (1..13).to_a.flat_map {|v| suits.map {|s| Card.new(v, s)}}
  $deck = $all_cards.shuffle
  $foundations = Hash[suits.map {|suit| [suit, 0]}]
  $columns = (1..7).to_a.map {|num| $deck.slice!(0, num)}
  last_column_cards().each {|card| card.moveable = true}

  #remaining deck into groups of three
  y = into_threes($deck)
  $threes = (1..y).to_a.map {|num| $deck.slice((num-1)*3, 3)}
  $spent_threes = []
  $current_three = 0

  x = 0
  #until victory condition met
  until Card.total_in_foundation == 52 do # OR foundations.values.all? {|f| f == 13}

    #show playing area each turn
    system 'clear'
    show_foundations()
    show_1_to_7_columns()
    show_deck()

    #get player's action
    get_complete_action()
    
    x += 1
  end
  puts "Congratulations, you won in #{x} moves!"
  #run program again?
end

######################
## Printing methods ##
######################

#print top card of foundation stacks
def show_foundations()
  puts
  print "\t\t\t"
  $foundations.each_pair do |k, v|
    print "[" + get_colour(num_to_face(v) + k, k) + "]" + "\t"  
  end
  3.times {|x| puts}
end

#create rows using columns arrays & print them to console
def show_1_to_7_columns()
  rows = Array.new($columns.map {|l| l.length}.max) {|num| $columns.map {|col| col[num]}}
  rows.each do |row|
    print "\t"
    row.each do |c|
      if c == nil
        print "   \t"
      elsif c.moveable == true
        print "|" + get_colour(num_to_face(c.value) + c.suit, c.suit) + "|\t"
      else #c.moveable == false
        print "[  ] \t"
      end
    end
    print "\n"
  end
  puts
end

#show remaining deck
def show_deck()
  $deck.each {|c| c.moveable = false}
  print "\tdeck (#{$threes.flatten.count} cards): []]] "
  #shows duplicate at end of deck instead of next 3 cards
  $threes[$current_three].each do |c| 
    if $threes[$current_three].index(c) + 1 == $threes[$current_three].length
      c.moveable = true
      print "|" + get_colour(num_to_face(c.value) + c.suit, c.suit) + "| "
    else 
      print get_colour(num_to_face(c.value) + c.suit, c.suit) + " "
    end
  end
  puts
  puts
end

#puts all valid commands to the console
def show_commands(string_input)
  if string_input == "command" || string_input == "commands"
    puts "- 'Kh', '4s', etc. when prompted to select a card to move"
    puts "- 'deck'/'d' to draw new sideboard cards"
    puts
    puts "With a card selected:"
    puts "- Column number, eg '2', '5', OR name of exposed card eg 'Qd' to place card on desired column"
    puts "- 'foundation'/'f' to move card to foundation." 
    puts "- 'cancel'/'c' to deselect cards"
    puts
    return true
  else 
    return false
  end
end

#loops back to get a different move if current move is invalid/not recognised
def move_invalid_bugged(card_input, move_to)
  #clear and reprint board here?
  puts "Attempting to move #{card_input} to #{move_to} is either invalid or bugged."
  puts "Pick a different location to move the card, or type 'cancel' to deselect the card and choose another."
  get_move_to(card_input)
end

#assign colours to suits for console display
def get_colour(text, suit)
  if suit == "h" || suit == "d"
    text.red
  else
    text.light_blue
  end
end

#returns aces/face/T for card values 1, 10, 11, 12, 13 
def num_to_face(value)
  case value
  when 0
    value_only = " "
  when 1
    value_only = "A"
  when 10
    value_only = "T"
  when 11
    value_only = "J"
  when 12
    value_only = "Q"
  when 13
    value_only = "K"
  else
    value_only = value.to_s
  end
end

#returns a numeric value for face cards/converts string numbers to integers
def face_to_num(value)
  case value
  when "A"
    value_only = 1
  when "T"
    value_only = 10
  when "J"
    value_only = 11
  when "Q"
    value_only = 12
  when "K"
    value_only = 13
  else
    value_only = value.to_i
  end
end

#############################
## Deck management methods ##
#############################

def into_threes(fresh_deck)
  if fresh_deck.count % 3 == 0
    fresh_deck.count / 3
  else
    fresh_deck.count / 3 + 1
  end
end

#causing last $threes entry to show twice
def next_threes()
  if $spent_threes.length+1 == $threes.length
    $spent_threes.push($threes[$spent_threes.length-1])
    x = into_threes($spent_threes.flatten!)
    $threes = (1..x).to_a.map {|num| $spent_threes.slice!(0, 3)}
    $current_three = 0
  else
    $spent_threes.push($threes[$spent_threes.length-1])
    $current_three += 1
  end
end

def last_column_cards() 
  $columns.map do |col| 
    col[-1] == nil ? false : col[-1]
  end
end

######################################
## METHODS FOR GETTING PLAYER INPYT ##
######################################

def get_complete_action()
  moveable_cards = $all_cards.filter {|c| c.moveable == true}
  card_input = get_card_input(moveable_cards)
  move_to = get_move_to(card_input)
end

def get_card_input(moveable_cards)

  puts "Type 'command' at any point for a list of commands."
  puts
  puts "Which card would you like to move?"
 
  card_input = gets.chomp.downcase
  find_card = moveable_cards.find {|c| c.name.downcase == card_input}

  if find_card.class == Card 
    return find_card
  elsif show_commands(card_input) == true
    get_card_input(moveable_cards)
  elsif card_input == "deck" || card_input == "d"
    return card_input
  else
    puts "Invalid card or command. Please use format 'As', '4h', etc. and ensure the card is free to move."
    get_card_input(moveable_cards)
  end
end

def get_move_to(card_input)
  if card_input.class == Card # change to if == deck?
    card_name = get_colour(num_to_face(card_input.value) + card_input.suit, card_input.suit)
    puts
    puts "Enter column, card name or 'foundation' to move #{card_name}."
    move_to = gets.chomp.capitalize
    last_cards_name = last_column_cards().map {|c| c == false ? false : c.name}
    if ("1".."7").to_a.include?(move_to)
      move_to_column(card_input, move_to.to_i)
    elsif last_cards_name.include?(move_to)
      move_to_column(card_input, last_cards_name.index(move_to)+1)
    elsif move_to == "Foundation" || move_to == "Foundations" || move_to == "F"
      move_to_foundation(card_input, move_to)
    elsif move_to == "C" || move_to == "Cancel"
      #clear and reprint board?
      get_complete_action()
    elsif show_commands(card_input) == true
      get_move_to(card_input)   
    else 
      move_invalid_bugged(card_input, move_to)
    end
  elsif card_input == "d" || card_input == "deck"
    next_threes() 
  else
    move_invalid_bugged(card_input, nil)
  end
end

##############################
## METHODS FOR MOVING CARDS ##
##############################

def move_to_column(card_input, move_to)

  #can card move to column? check suit + value
  if can_move_to_column?(card_input, move_to) == true
    stack = from_deck_or_column(card_input)
    $columns[move_to-1].push(stack).flatten!
  else
    move_invalid_bugged(card_input, move_to)
  end
end

def move_to_foundation(card_input, move_to)
  if card_input.value == $foundations[card_input.suit] + 1
    from_deck_or_column(card_input)
    Card.total_in_foundation += 1
    card_input.moveable = false
    $foundations[card_input.suit] += 1
  else
    move_invalid_bugged(card_input, move_to)
  end
end

#returns true if moving from column, false if moving from deck
def from_deck_or_column(card_input)
  if $columns.any? {|col| col.include?(card_input)}
    stack = move_from_column(card_input)
    return stack
  else
    move_from_deck(card_input)
  end
end

def can_move_to_column?(card_input, move_to)
  card_input.suit == "c" || card_input.suit == "s" ? need_suit = ["h", "d"] : need_suit = ["c", "s"] 
  need_value = face_to_num(card_input.value)+1
  binding.pry
  if $columns[move_to-1][0] == false || $columns[move_to-1].length == 0
    return true
  elsif $columns[move_to-1][-1].value == need_value && need_suit.include?($columns[move_to-1][-1].suit) 
    return true
  else
    return false
  end
end

def move_from_deck(card_input)
  $threes[$current_three].delete(card_input)
  $deck.delete(card_input)
  if $threes[$current_three].length == 0
    $spent_threes.length+1 == $threes.length ? $current_three = 0 : $current_three += 1
  end
  return card_input
end

def move_from_column(card_input)
  origin = $columns.find {|col| col.include?(card_input)}
  stack = origin.slice!(origin.index(card_input), origin.length - origin.index(card_input)+1)
  origin[-1].moveable = true if origin.length > 0
  return stack
end

##############################

play_solitaire()