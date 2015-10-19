require 'colorize'

module Interface
  MESSAGES = { invalid_command: 'Huh? Please type one of the commands.' }
  OBJ = Object.new

  private

  def stats_color(value)
    if value <= 2
      :red
    elsif value <= 5
      :yellow
    else
      :green
    end
  end

  def stats
    if @asleep
      status = "#{'SLEEP'.colorize(:light_blue)} | " \
    else
      status = "#{'ACTIVE'.colorize(:light_green)} | " \
    end
    "#{status}#{'FOOD'.colorize(stats_color(@food))} | " \
      "#{'HEALTH'.colorize(stats_color(@health))} | " \
      "#{'FUN'.colorize(stats_color(@fun))} | " \
      "#{'ENERGY'.colorize(stats_color(@energy))}"
  end

  def clear_screen
    print `(clear)`
  end

  def special_events
    message = []
    message.push('doody') if doody?
    message.push('dirty') if dirty?
    message.push('hungry') if hungry?
    message.push('tired') if tired?
    message.push('sad') if sad?
    message.push('ill') if ill?
    message
  end

  def text
    puts "#{@name} - the #{@pet[:type]}".colorize(:light_cyan)
    puts stats
    puts special_events.join(' | ').colorize(:light_red) unless
        special_events.empty?
    puts @event_message
    print 'enter command: '
  end

  def clean_threads
    thread_list = Thread.list
    Thread.kill(thread_list[2]) if thread_list.size == 3
  end

  def valid_command?(command)
    self.respond_to?(command) && !OBJ.respond_to?(command)
  end

  def prompt
    clean_threads
    Thread.new do
      input = gets.chomp
      exit if input == 'exit'
      if valid_command?(input)
        send input
      else
        trigger_event(MESSAGES[:invalid_command])
      end
    end
  end

  def interface
    clear_screen
    text
    prompt
  end
end

module GameTime
  include Interface

  MINUTES_PER_TIME = 3

  private

  def time_passed?
    (Time.new - @tracktime) / 60.0 > MINUTES_PER_TIME
  end

  def time_passed!
    @fun = change_value(@fun, :down)
    @food = change_value(@food, :down)
    @health = change_value(@health, :down) if @dirty || @doody || sad? ||
                                              hungry? || tired?
    if @asleep
      @energy = change_value(@energy, :up)
    else
      @energy = change_value(@energy, :down)
    end
    wake_up if @energy == 10
    doody!
    leave if @health == 0
  end

  def time
    @tracktime ||= Time.new
    born
    loop do
      if time_passed?
        time_passed!
        interface
        @tracktime = Time.new
      end
      next
    end
  end

  def born
    @event_message = "#{@name} is born!".colorize(:light_green)
    interface
  end

  def trigger_event(message)
    @event_message = message
    interface
  end

  def leave
    clear_screen
    puts "#{@name} ran away from you".colorize(:light_red)
    exit
  end
end

class Pet
  include GameTime

  PETS = [{ type: 'Firebug' },
          { type: 'Space Chicken' },
          { type: 'Chocolate Puppy' },
          { type: 'Sugarbelly' },
          { type: 'Vile Hamster' }
         ]

  def initialize(name)
    @name = name
    @pet = PETS.sample
    @fun = 10
    @food = 0
    @health = 10
    @energy = 10
    time
  end

  def feed
    wake_up
    if @food < 10
      @food = change_value(@food, :up)
      msg = "You feed #{@name}.".colorize(:light_green)
      doody!
    else
      msg = "#{@name} dont want to eat.".colorize(:light_yellow)
    end
    trigger_event(msg)
  end

  def clean
    if doody? || dirty?
      msg = "#{@name} is clean now!".colorize(:light_green)
    else
      msg = "#{@name} is cleaner now!".colorize(:light_yellow)
    end
    @doody, @dirty = false
    trigger_event(msg)
  end

  def help
    commands = methods - OBJ.methods
    msg = "Available commands:\n#{commands.sort.join(', ')}."
          .colorize(:light_green)
    trigger_event(msg)
  end

  def walk
    wake_up
    if @energy > 0
      msg = "You walk with #{@name}.".colorize(:light_green)
      @fun = change_value(@fun, :up)
      @energy = change_value(@energy, :down)
      dirty!
    else
      msg = "#{@name} dont want to walk.".colorize(:light_yellow)
    end
    trigger_event(msg)
  end

  def tobed
    if @energy < 10
      @asleep = true
      msg = "#{@name} is sleeping.".colorize(:light_green)
    else
      msg = "#{@name} dont want to sleep.".colorize(:light_yellow)
    end
    trigger_event(msg)
  end

  def toss
    wake_up
    if @energy > 0
      msg = "You toss #{@name} up into the air.".colorize(:light_green)
      @fun = change_value(@fun, :up)
      @energy = change_value(@energy, :down)
      dirty!
    else
      msg = 'No time to toss.'.colorize(:light_yellow)
    end
    trigger_event(msg)
  end

  def ball
    wake_up
    if @energy > 0
      msg = "You threw the ball and #{@name} brought him back"
            .colorize(:light_green)
      @fun = change_value(@fun, :up)
      @energy = change_value(@energy, :down)
      dirty!
    else
      msg = 'No time to play ball.'.colorize(:light_yellow)
    end
    trigger_event(msg)
  end

  private

  def change_value(value, how)
    if how == :up
      @health += rand(3)
      value += rand(1..3)
    elsif how == :down
      value -= rand(3)
    end
    @health = 10 if @health > 10
    return 10 if value > 10
    return 0 if value < 0
    value
  end

  def hungry?
    @food <= 2
  end

  def tired?
    @energy == 0
  end

  def sad?
    @fun == 0
  end

  def ill?
    @health <= 2
  end

  def doody?
    @doody ||= false
  end

  def doody!
    return if doody? && @food < 1
    @doody = true if rand(10).odd?
    dirty!
  end

  def dirty?
    @dirty ||= false
  end

  def dirty!
    @dirty = true if rand(10).odd?
  end

  def wake_up
    return unless @asleep
    @asleep = false
    msg = "#{@name} wakes up!".colorize(:light_green)
    trigger_event(msg)
  end
end

puts 'What would you like to name your pet?'
name = gets.chomp
Pet.new name
