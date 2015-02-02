

class LruRedux::LirsCache
  def initialize(max_size)
    raise ArgumentError.new(:max_size) if max_size < 2
    @max_size = max_size
    @q_size = [max_size/100,1].max
    @data = {}
    @s_hist = LruRedux::LirsHistory.new
    @q_hist = LruRedux::LirsHistory.new
  end

  def max_size=(size)
    raise ArgumentError.new(:max_size) if size < 2
    @max_size = size
    @q_size = [size/100,1].max
    if @data.size > @max_size
      clear
    end
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
    while s_hist_tail and (!@data.has_key?(s_hist_tail[0]) or @q_hist.has_key?(s_hist_tail[0])) do
      @s_hist.delete(s_hist_tail[0])
      s_hist_tail = @s_hist.get_tail
    end
  end

  def hit(key)
    value = @data[key]
    if @s_hist.has_key?(key)
      old_s_key = @s_hist.get_tail[0]
      if @q_hist.has_key?(key)
        @s_hist.refresh(key)
        @q_hist.delete(key)
        @s_hist.delete(old_s_key)
        @q_hist.set_key(old_s_key,nil)
        trim_history
      else
        @s_hist.refresh(key)
        if old_s_key == key
          trim_history
        end
      end
    else
      @s_hist.set_key(key,nil)
      @q_hist.refresh(key)
    end
    value
  end

  def miss(key, result)
    if @data.size < @max_size
      @data[key] = result
      @s_hist.set_key(key,nil)
      if @data.size > (@max_size - @q_size)
        @q_hist.set_key(key,nil)
      end
    else
      old_q_set = @q_hist.get_tail
      if old_q_set
        @data.delete(old_q_set[0])
        @q_hist.delete(old_q_set[0])
      end
      @data[key] = result
      if @s_hist.has_key?(key)
        @s_hist.refresh(key)
        old_s_key = @s_hist.get_tail[0]
        @s_hist.delete(old_s_key)
        @q_hist.set_key(old_s_key,nil)
        trim_history
      else
        @s_hist.set_key(key,nil)
        @q_hist.set_key(key,nil)
      end
    end
    result
  end
end