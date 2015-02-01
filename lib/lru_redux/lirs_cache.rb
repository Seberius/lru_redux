

class LruRedux::LirsCache
  def initialize(max_size)
    @max_size = max_size
    @data = {}
    @s_hist = LruRedux::Cache.new(max_size)
    @q_hist = LruRedux::Cache.new(max_size)
  end
end

def max_size=(size)
  raise ArgumentError.new(:max_size) if @max_size < 1
  @max_size = size
  @s_hist.max_size = size
  @q_hist.max_size = size
  if @max_size < @data.size
    @data.keys[0..@max_size-@data.size].each do |k|
      @data.delete(k)
    end
  end
end

def trim_history
  until @data.has_key?(@s_hist.get_tail[0]) and not @q_hist.has_key?(@s_hist.get_tail[0]) do
    @data.delete(@data.first[0])
  end
end

def hit(key)
  value = @data[key]
  if @s_hist.contains?(key)
    unless @q_hist.contains?(key)
      @s_hist[key]
      trim_history
    else
      @s_hist[key]
      old_s_key = @s_hist.get_tail[0]
      @s_hist.delete(old_s_key)
      @q_hist.delete(key)
      @q_hist[old_s_key]
      trim_history
    end
  else
    @s_hist[key] = value
    @q_hist[key]
  end
  value
end

def miss(key, result)
  if @s_hist.length < @max_size
    @s_hist[key] = nil
    @data[key] = result
  else
    old_q_key = @q_hist.get_tail[0]
    @data.delete(old_q_key)
    @q_hist.delete(old_q_key)
    @s_hist[key] = nil
    unless @s_hist.contains?(key)
      @data[key] = result
      @q_hist[key] = nil
    else
      old_s_key = @s_hist.get_tail[0]
      @s_hist.delete(old_s_key)
      @q_hist[old_s_key] = nil
      trim_history
    end
  end
  result
end

def getset(key)
  found = @data.has_key?(key)
  if found
    hit(key)
  else
    result = yield
    miss(key, result)
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

  def delete(k)
    @data.delete(k)
  end

  def clear
    @data.clear
  end

  def count
    @data.count
  end


  # for cache validation only, ensures all is sound
  def valid?
    true
  end
end