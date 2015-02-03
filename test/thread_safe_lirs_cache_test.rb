if LruRedux.is_19?
  require_relative 'lirs_cache_test'
else
  require './lirs_cache_test'
end

class ThreadSafeLirsCacheTest < LirsCacheTest
  def setup
    @cache = LruRedux::ThreadSafeLirsCache.new(2,1)
  end

  def test_recursion
    @cache[:a] = 1
    @cache[:b] = 2

    # should not blow up
    @cache.each do |k,_|
      @cache[k]
    end
  end
end
