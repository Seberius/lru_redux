

class LruRedux::LirsHistory < LruRedux::Cache
  def initialize(size)
    super(size)
  end

  def contains?(key)
    @data.has_key?(key)
  end

  def index?(key)
    keys = @data.keys
    key_indices = Hash[keys.map.with_index.to_a]

    key_indices[key]
  end
end
