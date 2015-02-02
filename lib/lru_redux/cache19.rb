# Ruby 1.9 makes our life easier, Hash is already ordered
#
# This is an ultra efficient 1.9 freindly implementation
class LruRedux::Cache
  def initialize(max_size)
    @s_limit = max_size
    @data = {}
  end

  def max_size=(size)
    raise ArgumentError.new(:s_limit) if @s_limit < 1
    @s_limit = size
    if @s_limit < @data.size
      @data.keys[0..@s_limit-@data.size].each do |k|
        @data.delete(k)
      end
    end
  end

  def getset(key)
    found = true
    value = @data.delete(key){ found = false }
    if found
      @data[key] = value
    else
      result = @data[key] = yield
      # this may seem odd see: http://bugs.ruby-lang.org/issues/8312
      @data.delete(@data.first[0]) if @data.length > @s_limit
      result
    end
  end

  def fetch(key)
    found = true
    value = @data.delete(key){ found = false }
    if found
      @data[key] = value
    else
      yield if block_given?
    end
  end

  def [](key)
    found = true
    value = @data.delete(key){ found = false }
    if found
      @data[key] = value
    else
      nil
    end
  end

  def []=(key,val)
    @data.delete(key)
    @data[key] = val
    # this may seem odd see: http://bugs.ruby-lang.org/issues/8312
    @data.delete(@data.first[0]) if @data.length > @s_limit
    val
  end

  def each
    array = @data.to_a
    array.reverse!.each do |pair|
      yield pair
    end
  end

  # used further up the chain, non thread safe each
  alias_method :each_unsafe, :each

  def to_a
    array = @data.to_a
    array.reverse!
  end

  def delete(key)
    @data.delete(key)
  end

  def clear
    @data.clear
  end

  def count
    @data.count
  end

  def has_key?(key)
    @data.has_key?(key)
  end

  # for cache validation only, ensures all is sound
  def valid?
    true
  end
end
