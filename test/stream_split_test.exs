defmodule StreamSplitTest do
  use ExUnit.Case
  doctest StreamSplit

  test "basic stream" do
    :ok = File.write("tmp/data.txt", "AB;CCCCC;D")
    StreamSplit.split("tmp/data.txt", ";")
    |> Stream.map(&String.length/1)
    |> Stream.run()
    |> Enum.to_list()
  end
end
