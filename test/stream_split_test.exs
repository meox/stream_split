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
           |> Enum.to_list() == ["ab", "CCCCC", "D"]
  end

  test "stream manipulation: tagging" do
    :ok = File.write("tmp/data_manip2.txt", "AB;CCCCC;D")
    {:ok, fd} = File.open("tmp/data_manip2.txt", [:read, :binary])

    assert fd
           |> StreamSplit.split(";", tagging: true)
           |> Stream.map(fn
             {:first, data} -> String.downcase(data)
             {:last, data} -> String.downcase(data)
             data -> data
           end)
           |> Enum.to_list() == ["ab", "CCCCC", "d"]
  end

  test "stream manipulation: tagging (with trailing)" do
    :ok = File.write("tmp/data_manip3.txt", "AB;CCCCC;D;***")
    {:ok, fd} = File.open("tmp/data_manip3.txt", [:read, :binary])

    assert fd
           |> StreamSplit.split(";", tagging: true, drop_last: true)
           |> Stream.map(fn
             {:first, data} -> String.downcase(data)
             {:last, data} -> String.downcase(data)
             data -> data
           end)
           |> Enum.to_list() == ["ab", "CCCCC", "d"]
  end

  test "big stream" do
    :ok = File.write("tmp/data2.txt", gen_doc(";;;", 130_221))
    {:ok, fd} = File.open("tmp/data2.txt", [:read, :binary])

    assert fd
           |> StreamSplit.split(";;;")
           |> Stream.map(&String.length/1)
           |> Enum.count() == 130_221
  end

  test "consistency" do
    :ok =
      File.write(
        "tmp/data3.txt",
        [
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
          "<add>",
          "<doc>aaa</doc>",
          "<doc>bbb</doc>",
          "<doc>ccc</doc>",
          "</add>"
        ]
        |> Enum.join("")
      )

    {:ok, fd} = File.open("tmp/data3.txt", [:read, :binary])

    assert fd
           |> StreamSplit.split("</doc>", tagging: true, drop_last: true)
           |> Stream.map(fn
             {:first, data} ->
               data =
                 data
                 |> String.replace_prefix(
                   "<?xml version=\"1.0\" encoding=\"UTF-8\"?><add><doc>",
                   ""
                 )
                 |> String.upcase()

               "<doc>#{data}</doc>"

             {:last, data} ->
               data =
                 data
                 |> String.replace_prefix("<doc>", "")
                 |> String.replace_suffix("</add>", "")
                 |> String.upcase()

               "<doc>#{data}</doc>"

             data ->
               "#{data}</doc>"
           end)
           |> Enum.to_list() == ["<doc>AAA</doc>", "<doc>bbb</doc>", "<doc>CCC</doc>"]
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
