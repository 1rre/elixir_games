defmodule TestGameTest do
  use ExUnit.Case
  doctest TestGame

  test "greets the world" do
    assert TestGame.hello() == :world
  end
end
