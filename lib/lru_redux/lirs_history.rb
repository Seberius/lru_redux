

class LruRedux::LirsHistory < LruRedux::Cache
  def initialize
    @data = {}
    @head = nil
    @tail = nil
  end

  def set_key(key,val)
    node = @data[key]
    if node
      move_to_head(node)
      node[2] = val
    else
      @data[key] = add_to_head(key,val)
    end
    val
  end

  def refresh(key)
    node = @data[key]
    move_to_head(node)
    node[2]
  end

  def set_tail(key,val)
    if @data.has_key?(key)
      node = @data[key]
      node[2] = val
    elsif @tail
      node = @tail
      @tail = [nil,key,val,node]
      node[0] = @tail
    else
      @head = @tail = [nil,key,val,nil]
    end
  end

  def size
    @data.size
  end

  def each_set
    @data.each do |key, value|
      yield key, value
    end
  end

  def get_head_key
    if @head
      @head[1]
    else
      nil
    end
  end

  def get_tail
    if @tail
      @tail[1,2]
    else
      nil
    end
  end
end
