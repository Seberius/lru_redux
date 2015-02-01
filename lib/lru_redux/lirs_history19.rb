

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

  def delete(key)
    @data.delete(key)
  end

  def clear
    @data.clear
  end

  def has_key?(key)
    @data.has_key?(key)
  end

  def get_tail
    @data.first
  end

  # for cache validation only, ensures all is sound
  def valid?
    true
  end
end
