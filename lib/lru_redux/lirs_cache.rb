

class LruRedux::LirsCache
  def initialize(s_limit,q_limit = 1)
    raise ArgumentError.new('S Limit must be 1 or greater.') if s_limit < 1
    raise ArgumentError.new('Q Limit must be 1 or greater.') if q_limit < 1
    @s_limit = s_limit
    @q_limit = q_limit
    @data = {}
    @s_hist = LruRedux::LirsHistory.new
    @q_hist = LruRedux::LirsHistory.new
  end

  def max_size=(s_limit, q_limit = nil)
    q_limit ||= @q_limit
    raise ArgumentError.new('S Limit must be 1 or greater.') if s_limit < 1
    raise ArgumentError.new('Q Limit must be 1 or greater.') if q_limit < 1
    @s_limit = s_limit
    @q_limit = q_limit
    clear
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
    while @q_hist.has_key?(s_hist_tail[0]) || !@data.has_key?(s_hist_tail[0]) do
      @s_hist.delete(s_hist_tail[0])
      s_hist_tail = @s_hist.get_tail
    end
  end

  def hit(key)
    value = @data[key]
    if @s_hist.has_key?(key)
      if @q_hist.has_key?(key)
        @s_hist.refresh(key)
        @q_hist.delete(key)
        old_s_key = @s_hist.get_tail[0]
        @s_hist.delete(old_s_key)
        @q_hist.set_key(old_s_key,nil)
        trim_history
      else
        old_s_key = @s_hist.get_tail[0]
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
    if @s_hist.count < @s_limit
      @data[key] = result
      @s_hist.set_key(key,nil)
    else
      if @q_hist.count >= @q_limit
        old_q_key = @q_hist.get_tail[0]
        @data.delete(old_q_key)
        @q_hist.delete(old_q_key)
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