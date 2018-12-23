defmodule StreamSplitPerfTest do
  use ExUnit.Case

  setup do
    File.mkdir("tmp_perf")

    on_exit(fn ->
      File.rm_rf("tmp_perf/")
    end)
  end

  test "stream 1" do
    {:ok, fd} = File.open("/home/meox/test.xml.gz", [:read, :binary])

    fd
    |> StreamSplit.split("</doc>", tagging: true)
    |> Stream.map(fn
      {:first, data} ->
        data =
          data
          |> String.replace_prefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", "")
          |> String.upcase(data)

        "#{data}</doc>"

      {:last, data} ->
        data =
          data
          |> String.replace_suffix("</add>")
          |> String.upcase()

        "#{data}</doc>"

      data ->
        "#{data}</doc>"
    end)
    |> Stream.chunk_every(1000)
    |> Stream.map(fn docs ->
      ["<add>", docs, "</add>"]
      |> Enum.join("")
    end)
  end
end
