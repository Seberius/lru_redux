require_relative 'lirs_cache_test'

class ThreadSafeCacheTest < LirsCacheTest
  def setup
    @c = LruRedux::ThreadSafeLirsCache.new(4)
  end

  def test_recursion
    @c[:a] = 1
    @c[:b] = 2

    # should not blow up
    @c.each do |k,v|
      @c[k]
    end
  end
end
