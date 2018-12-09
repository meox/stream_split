defmodule StreamSplitTest do
  use ExUnit.Case
  doctest StreamSplit

  test "basic stream" do
    :ok = File.write("tmp/data.txt", "AB;CCCCC;D")

    assert StreamSplit.split("tmp/data.txt", ";")
           |> Stream.map(&String.length/1)
           |> Stream.filter(fn x -> rem(x, 2) == 1 end)
           |> Enum.count() == 2
  end

  test "big stream" do
    :ok = File.write("tmp/data2.txt", gen_doc(";;;", 10_000))
    assert StreamSplit.split("tmp/data2.txt", ";;;")
           |> Stream.map(&String.length/1)
           |> Enum.count() == 10_000
  end

  defp gen_doc(sep, n) do
    1..n
    |> Enum.map(fn _ -> gen_string() end)
    |> Enum.join(sep)
  end

  defp gen_string() do
    n = Enum.random(1..31)
    :crypto.strong_rand_bytes(n) |> Base.url_encode64 |> binary_part(0, n)
  end
end
