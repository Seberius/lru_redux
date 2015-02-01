

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

  def get_tail
    @tail[1,2]
  end
end
