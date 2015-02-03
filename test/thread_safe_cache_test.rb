if LruRedux.is_19?
  require_relative 'cache_test'
else
  require './cache_test'
end

class ThreadSafeCacheTest < CacheTest
  def setup
    @cache = LruRedux::ThreadSafeCache.new(3)
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
