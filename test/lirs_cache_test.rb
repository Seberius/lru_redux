require 'lru_redux'
require 'minitest/autorun'
require 'minitest/pride'

class LirsCacheTest < MiniTest::Test
  def setup
    @cache = LruRedux::LirsCache.new(2,1)
  end

  def teardown
    assert_equal true, @cache.valid?
  end

  def test_drops_old
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3
    @cache[:d] = 4

    assert_equal [[:d,4],[:b,2],[:a,1]], @cache.to_a
    assert_nil @cache[:c]
    assert_equal [[[:d,nil],[:c,nil],[:b,nil],[:a,nil]], [[:d,nil]]], @cache.hist_to_a
  end

  def test_fetch
    @cache[:a] = nil
    @cache[:b] = 2

    assert_equal @cache.fetch(:a){1}, nil
    assert_equal @cache.fetch(:c){3}, 3
    assert_equal [[:b,2],[:a,nil]], @cache.to_a
    assert_equal [[[:a,nil],[:b,nil]], []], @cache.hist_to_a
  end

  def test_getset
    assert_equal @cache.getset(:a){1}, 1

    @cache.getset(:b){2}

    assert_equal @cache.getset(:a){11}, 1

    @cache.getset(:c){3}

    assert_equal @cache.getset(:d){4}, 4
    assert_equal [[:d,4],[:b,2],[:a,1]], @cache.to_a
    assert_equal [[[:d,nil],[:c,nil],[:a,nil],[:b,nil]], [[:d,nil]]], @cache.hist_to_a
  end

  def test_hir_replacement

    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3

    # :c should be present in S and Q, a resident HIR key.
    assert_equal [[[:c, nil],[:b,nil],[:a,nil]], [[:c,nil]]], @cache.hist_to_a

    @cache[:d] = 4

    # :d should have replaced :c as resident HIR block
    assert_equal [[:d,4],[:b,2],[:a,1]], @cache.to_a
    assert_equal [[[:d,nil],[:c, nil],[:b,nil],[:a,nil]], [[:d,nil]]], @cache.hist_to_a
    assert_nil @cache[:c]
  end

  def test_hit_promotes_to_lir
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3

    # :c should be present in S and Q, a resident HIR key.
    assert_equal [[[:c, nil],[:b,nil],[:a,nil]], [[:c,nil]]], @cache.hist_to_a

    @cache[:c]

    # :c is "hit" in the cache, promoting it to LIR (removal from Q) and demotes the oldest LIR key :a to HIR
    assert_equal [[[:c, nil],[:b,nil]],[[:a,nil]]], @cache.hist_to_a

    # The oldest HIR key :a is removed and :d is inserted as a HIR key
    @cache[:d] = 4

    assert_equal [[:d,4],[:c,3],[:b,2]], @cache.to_a
    assert_equal [[[:d,nil],[:c,nil],[:b,nil]], [[:d,nil]]], @cache.hist_to_a
    assert_nil @cache[:a]
  end

  def test_delete
    @cache.max_size = 3, 2
    @cache.getset(:a) {1}
    @cache.getset(:b) {2}
    @cache.getset(:c) {3}
    @cache.getset(:d) {4}
    @cache.getset(:e) {5}
    @cache.getset(:a) {1}
    @cache.getset(:f) {6}
    @cache.getset(:e) {5}
    @cache.getset(:g) {7}

    assert_equal [[:g, 7], [:e, 5], [:c, 3], [:b, 2], [:a, 1]], @cache.to_a
    assert_equal [[[:g, nil], [:e, nil], [:f, nil], [:a, nil], [:d, nil], [:c, nil]], [[:g, nil], [:b, nil]]],
                 @cache.hist_to_a

    @cache.delete(:e)

    assert_equal [[:g, 7], [:c, 3], [:b, 2], [:a, 1]], @cache.to_a
    assert_equal [[[:g, nil], [:e, nil], [:f, nil], [:a, nil], [:d, nil], [:c, nil]], [[:b, nil]]], @cache.hist_to_a

    @cache.delete(:c)

    assert_equal [[:g, 7], [:b, 2], [:a, 1]], @cache.to_a
    assert_equal [[[:g, nil], [:e, nil], [:f, nil], [:a, nil], [:d, nil], [:c, nil], [:b, nil]], []], @cache.hist_to_a

    @cache.delete(:b)

    assert_equal [[:g, 7], [:a, 1]], @cache.to_a
    assert_equal [[[:g, nil], [:e, nil], [:f, nil], [:a, nil]], []], @cache.hist_to_a
  end

  def test_update
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3
    @cache[:a] = 99

    assert_equal [[:c,3],[:b,2],[:a,99]], @cache.to_a
    assert_equal [[[:a,nil],[:c,nil],[:b,nil]], [[:c,nil]]], @cache.hist_to_a
  end

  def test_clear
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3
    @cache.clear

    assert_equal [], @cache.to_a
    assert_equal [[],[]], @cache.hist_to_a
  end

  def test_grow
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3
    @cache.max_size = 3, 1
    @cache[:d] = 4

    assert_equal [[:d,4],[:c,3],[:b,2],[:a,1]], @cache.to_a
    assert_equal [[[:d,nil],[:c,nil],[:b,nil],[:a,nil]], [[:d,nil]]], @cache.hist_to_a
  end

  def test_shrink
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3

    assert_equal [[:c,3],[:b,2],[:a,1]], @cache.to_a
    assert_equal [[[:c,nil],[:b,nil],[:a,nil]], [[:c,nil]]], @cache.hist_to_a

    @cache.max_size = 1, 1

    assert_equal [[:b,2],[:a,1]], @cache.to_a
    assert_equal [[[:c,nil],[:b,nil]], [[:a,nil]]], @cache.hist_to_a
  end

  def test_each
    @cache.max_size = 1
    @cache[:a] = 1
    @cache[:b] = 2
    @cache[:c] = 3

    pairs = []
    @cache.each do |pair|
      pairs << pair
    end

    assert_equal [[:c,3],[:a,1]], pairs
  end
end
