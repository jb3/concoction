defmodule ConcoctionTest do
  use ExUnit.Case
  doctest Concoction

  test "greets the world" do
    assert Concoction.hello() == :world
  end
end
