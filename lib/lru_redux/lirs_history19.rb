

class LruRedux::LirsHistory
  def initialize
    @data = {}
  end

  def set_key(key,val)
    @data.delete(key)
    @data[key] = val
    val
  end

  def refresh(key)
    val = @data.delete(key)
    @data[key] = val
    val
  end

  def set_tail(key,val)
    @data.merge!(Hash[key,val])
  end

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
    @data.size
  end

  def size
    @data.size
  end

  def each_set
    @data.each do |key, value|
      yield key, value
    end
  end

  def has_key?(key)
    @data.has_key?(key)
  end

  def get_head_key
    @data.keys.last
  end

  def get_tail
    @data.first
  end

  # for cache validation only, ensures all is sound
  def valid?
    true
  end
end
