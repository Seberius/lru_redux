require 'lru_redux'
require 'minitest/autorun'
require 'minitest/pride'

class LirsCacheTest < MiniTest::Test
  def setup
    @c = LruRedux::LirsCache.new(3)
  end

  def teardown
    assert_equal true, @c.valid?
  end

  def test_drops_old
    @c[:a] = 1
    @c[:b] = 2
    @c[:c] = 3
    @c[:d] = 4

    assert_equal [[:d,4],[:b,2],[:a,1]], @c.to_a
    assert_nil @c[:c]
    assert_equal [[[:d,nil],[:c,nil],[:b,nil],[:a,nil]], [[:d,nil]]], @c.hist_to_a
  end

  def test_fetch
    @c[:a] = nil
    @c[:b] = 2
    assert_equal @c.fetch(:a){1}, nil
    assert_equal @c.fetch(:c){3}, 3

    assert_equal [[:b,2],[:a,nil]], @c.to_a
    assert_equal [[[:a,nil],[:b,nil]], []], @c.hist_to_a
  end

  def test_getset
    assert_equal @c.getset(:a){1}, 1
    @c.getset(:b){2}
    assert_equal @c.getset(:a){11}, 1
    @c.getset(:c){3}
    assert_equal @c.getset(:d){4}, 4

    assert_equal [[:d,4],[:b,2],[:a,1]], @c.to_a
    assert_equal [[[:d,nil],[:c,nil],[:a,nil],[:b,nil]], [[:d,nil]]], @c.hist_to_a
  end

  def test_delete
    @c[:a] = 1
    @c[:b] = 2
    @c[:c] = 3

    @c.delete(:b)
    assert_equal [[:c,3],[:a,1]], @c.to_a
    assert_nil @c[:b]
    assert_equal [[[:c,nil],[:a,nil]], [[:c,nil]]], @c.hist_to_a
  end

  def test_update
    @c[:a] = 1
    @c[:b] = 2
    @c[:c] = 3
    @c[:a] = 99
    assert_equal [[:c,3],[:b,2],[:a,99]], @c.to_a
    assert_equal [[[:a,nil],[:c,nil],[:b,nil]], [[:c,nil]]], @c.hist_to_a
  end

  def test_clear
    @c[:a] = 1
    @c[:b] = 2
    @c[:c] = 3

    @c.clear
    assert_equal [], @c.to_a
    assert_equal [[],[]], @c.hist_to_a
  end

  def test_each
    @c.max_size = 2
    @c[:a] = 1
    @c[:b] = 2
    @c[:c] = 3

    pairs = []
    @c.each do |pair|
      pairs << pair
    end

    assert_equal [[:c,3],[:a,1]], pairs

  end
end
