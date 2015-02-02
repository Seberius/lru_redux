require 'thread'
require 'monitor'

class LruRedux::ThreadSafeLirsCache < LruRedux::LirsCache
  include MonitorMixin
  def initialize(s_limit, q_limit = 1)
    super(s_limit, q_limit)
  end

  def self.synchronize(*methods)
    methods.each do |method|
      define_method method do |*args, &blk|
        synchronize do
          super(*args,&blk)
        end
      end
    end
  end

  synchronize :[], :[]=, :each, :to_a, :delete, :count, :valid?, :max_size=, :fetch, :getset, :has_key?

end