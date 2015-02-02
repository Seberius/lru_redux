

class LruRedux::LirsCache
  def initialize(max_size)
    raise ArgumentError.new(:max_size) if @max_size < 2
    @max_size = max_size.to_i / 2
    @data = {}
    @s_hist = LruRedux::LirsHistory.new
    @q_hist = LruRedux::LirsHistory.new
  end

  def max_size=(size)
    raise ArgumentError.new(:max_size) if @max_size < 2
    @max_size = size.to_i / 2
  end

  def getset(key)
    found = @data.has_key?(key)
    if found
      hit(key)
    else
      result = yield
      miss(key, result)
    end
  end

  def fetch(key)
    found = @data.has_key?(key)
    if found
      hit(key)
    else
      yield if block_given?
    end
  end

  def [](key)
    found = @data.has_key?(key)
    if found
      hit(key)
    else
      nil
    end
  end

  def []=(key,val)
    found = @data.has_key?(key)
    if found
      @data[key] = val
      hit(key)
    else
      miss(key,val)
    end
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

  def hist_to_a
    s_array = @s_hist.to_a
    q_array = @q_hist.to_a
    [s_array, q_array]
  end

  def delete(key)
    @data.delete(key)
    @s_hist.delete(key)
    @q_hist.delete(key)
  end

  def clear
    @data.clear
    @s_hist.clear
    @q_hist.clear
  end

  def count
    @data.count
  end

  def has_key?(key)
    @data.has_key?(key)
  end

  # for cache validation only, ensures all is sound
  def valid?
    @s_hist.valid? and @q_hist.valid?
  end

  protected

  def trim_history
    s_hist_tail = @s_hist.get_tail
    until s_hist_tail.nil? or (@data.has_key?(s_hist_tail[0]) and not @q_hist.has_key?(s_hist_tail[0])) do
      @s_hist.delete(s_hist_tail[0])
      s_hist_tail = @s_hist.get_tail
    end
  end

  def hit(key)
    value = @data[key]
    if @s_hist.has_key?(key)
      if @q_hist.has_key?(key)
        @s_hist.refresh(key)
        old_s_key = @s_hist.get_tail[0]
        @s_hist.delete(old_s_key)
        @q_hist.delete(key)
        @q_hist.set_key(old_s_key,nil)
        trim_history
      else
        @s_hist.refresh(key)
        trim_history
      end
    else
      @s_hist.set_key(key,nil)
      @q_hist.refresh(key)
    end
    value
  end

  def miss(key, result)
    if @s_hist.count < @max_size
      @data[key] = result
      @s_hist.set_key(key,nil)
    else
      old_q_set = @q_hist.get_tail
      if old_q_set
        @data.delete(old_q_set[0])
        @q_hist.delete(old_q_set[0])
      end
      if @s_hist.has_key?(key)
        @data[key] = result
        @s_hist.refresh(key)
        old_s_key = @s_hist.get_tail[0]
        @s_hist.delete(old_s_key)
        @q_hist.set_key(old_s_key,nil)
        trim_history
      else
        @data[key] = result
        @q_hist.set_key(key,nil)
      end
      @s_hist.set_key(key,nil)
    end
    result
  end
end