require "rubygems"
require "benchmark"
$LOAD_PATH.unshift File.expand_path '../lib'
require File.expand_path('../../lib/lru_redux', __FILE__)

lru_redux = LruRedux::Cache.new(1_000)
lru_redux_thread_safe = LruRedux::ThreadSafeCache.new(1_000)
lru_redux_lirs = LruRedux::LirsCache.new(1_000)
lru_redux_lirs_thread_safe = LruRedux::ThreadSafeLirsCache.new(1_000)

Benchmark.bmbm do |bm|

  [[lru_redux, "lru_redux gem"],
   [lru_redux_thread_safe, "lru_redux thread safe"],
   [lru_redux_lirs, "lru_redux LIRS"],
   [lru_redux_lirs_thread_safe, "lru_redux LIRS thread safe"]
  ].each do |cache, name|
    bm.report name do
      1_000_000.times do
        cache[rand(2_000)] ||= :value
      end
    end
  end
end