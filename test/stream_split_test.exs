defmodule StreamSplitTest do
  use ExUnit.Case
  doctest StreamSplit

  setup do
    File.mkdir("tmp")

    on_exit(fn ->
      File.rm_rf("tmp/")
    end)
  end

  test "basic stream" do
    :ok = File.write("tmp/data.txt", "AB;CCCCC;D")
    {:ok, fd} = File.open("tmp/data.txt", [:read, :binary])

    assert fd
           |> StreamSplit.split(";")
           |> Stream.map(&String.length/1)
           |> Stream.filter(fn x -> rem(x, 2) == 1 end)
           |> Enum.count() == 2
  end

  test "stream manipulation" do
    :ok = File.write("tmp/data_manip.txt", "AB;CCCCC;D")
    {:ok, fd} = File.open("tmp/data_manip.txt", [:read, :binary])

    assert fd
           |> StreamSplit.split(";")
           |> Stream.with_index()
           |> Stream.map(fn
             {data, 0} -> String.downcase(data)
             {data, _} -> data
           end)
           |> Enum.take(3) == ["ab", "CCCCC", "D"]
  end

  test "big stream" do
    :ok = File.write("tmp/data2.txt", gen_doc(";;;", 130_221))
    {:ok, fd} = File.open("tmp/data2.txt", [:read, :binary])

    assert fd
           |> StreamSplit.split(";;;")
           |> Stream.map(&String.length/1)
           |> Enum.count() == 130_221
  end

  ##### PRIVATE #####

  defp gen_doc(sep, n) do
    1..n
    |> Enum.map(fn _ -> gen_string() end)
    |> Enum.join(sep)
  end

  defp gen_string() do
    n = Enum.random(1..31)

    n
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, n)
  end
end
