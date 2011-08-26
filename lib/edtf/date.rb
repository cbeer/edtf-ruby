class Date
  
  PRECISIONS = [:year, :month, :day].freeze
	FORMATS = %w{ %04d %02d %02d }.freeze

	SYMBOLS = {
		:uncertain   => '?',
		:approximate => '~',
		:unspecified => 'u'
	}.freeze
	
  EXTENDED_ATTRIBUTES = %w{ calendar precision uncertain approximate
    unspecified }.map(&:to_sym).freeze
   	
  extend Forwardable  
  
  class << self
    def edtf(input, options = {})
      ::EDTF::Parser.new(options).parse(input)
    end
  end
  
  attr_accessor :calendar
  
  PRECISIONS.each do |p|
    define_method("#{p}_precision?") { @precision == p }
    define_method("#{p}_precision!") { @precision =  p }
  end
  
  def dup
    d = super
    d.uncertain = uncertain.dup
    d.approximate = approximate.dup
    d.unspecified = unspecified.dup
    d
  end
  
  # Alias change method from Active Support.
  alias original_change change
  
  # Returns a new Date where one or more of the elements have been changed according to the +options+ parameter.
  def change(options)
    d = original_change(options)
    EXTENDED_ATTRIBUTES.each do |attribute|
      d.send("#{attribute}=", options[attribute] || send(attribute))
    end
    d
  end
  
  # Returns this Date's precision.
  def precision
    @precision ||= :day
  end
  
	# Sets this Date/Time's precision to the passed-in value.
  def precision=(precision)
    precision = precision.to_sym
    raise ArgumentError, "invalid precision #{precision.inspect}" unless PRECISIONS.include?(precision)
    @precision = precision
    update_precision_filter[-1]
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def uncertain
    @uncertain ||= EDTF::Uncertainty.new
  end

  def approximate
    @approximate ||= EDTF::Uncertainty.new
  end

  def unspecified
    @unspecified ||= EDTF::Unspecified.new
  end
  
  def_delegators :uncertain, :uncertain?, :certain?

  def certain!(arguments = precision_filter)
    uncertain.certain!(arguments)
    self
  end
  
  def uncertain!(arguments = precision_filter)
    uncertain.uncertain!(arguments)
    self
  end

  def approximate?(arguments = precision_filter)
    approximate.uncertain?(arguments)
  end
  
  alias approximately? approximate?
  
  def approximate!(arguments = precision_filter)
    approximate.uncertain!(arguments)
    self
  end
  
  alias approximately! approximate!
  
  def precise?(arguments = precision_filter)
    !approximate?(arguments)
  end
  
  alias precisely? precise?

  def precise!(arguments = precision_filter)
    approximate.certain!(arguments)
    self
  end

  alias precisely! precise!
  
  def_delegators :unspecified, :unspecified?, :specified?, :unsepcific?, :specific?
  
  def unspecified!(arguments = precision_filter)
    unspecified.unspecified!(arguments)
    self
  end

  alias unspecific! unspecified!

  def specified!(arguments = precision_filter)
    unspecified.specified!(arguments)
    self
  end

  alias specific! specified!
  
  def season?; false; end
  
  def season
    Season.new(self)
  end
  
  def edtf
    s = FORMATS.take(values.length).join('-') % values
		s << SYMBOLS[:uncertain] if uncertain?
		s << SYMBOLS[:approximate] if approximate?
		s
  end

	alias to_edtf edtf
	
	# Returns a the Date of the next day, month, or year depending on the
	# current Date/Time's precision.
  def next
    send("next_#{precision}")
  end
  
  # def succ
  # end

  # def ==(other)
  # end

  # def <=>(other)
  # end

  # def ===(other)
  # end
  
	# Returns an array of the current year, month, and day values filtered by
	# the Date/Time's precision.
  def values
    precision_filter.map { |p| send(p) }
  end
  
  # Returns the same date with negated year        
  def negate
		change(:year => year * -1)
  end
  
  alias -@ negate
  
  
  private

  def precision_filter
    @precision_filter ||= update_precision_filter
  end
  
  def update_precision_filter
    case @precision
    when :year
      [:year]
    when :month
      [:year,:month]
    else
      [:year,:month,:day]
    end
  end
    
  protected
  
  attr_writer :uncertain, :unspecified, :approximate
  
end
