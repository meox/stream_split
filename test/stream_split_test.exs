defmodule StreamSplitTest do
  use ExUnit.Case
  doctest StreamSplit

  before :all do
    {:ok, device} = File.open("tmp/data.txt")
  end

  test "" do

  end
end
