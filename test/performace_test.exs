defmodule StreamSplitPerfTest do
  use ExUnit.Case

  setup do
    File.mkdir("tmp_perf")

    on_exit(fn ->
      #File.rm_rf("tmp_perf/")
    end)
  end

  test "stream 1" do
    {:ok, fd} = File.open("/home/meox/test.xml.gz", [:read, :binary, :compressed])

    fd
    |> StreamSplit.split("</doc>", tagging: true, drop_last: true)
    |> Stream.filter(fn doc -> doc != "<doc>" end)
    |> Stream.map(fn
      {:first, data} ->
        data =
          data
          |> String.replace_prefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?><add><doc>", "")
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
    |> Stream.chunk_every(1000)
    |> Stream.with_index()
    |> Stream.map(fn {docs, idx} ->
      doc = ["<add>", docs, "</add>"]
      |> Enum.join("")
      File.write("tmp_perf/t_#{idx}.xml", doc)
    end)
    |> Stream.run()
  end
end
