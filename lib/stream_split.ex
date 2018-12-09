defmodule StreamSplit do
  defstruct(
    device: nil,
    buffer: "",
    split_token: ",",
    stop: false
  )

  def split(file, split_token) do
    Stream.resource(
      fn ->
        {:ok, fd} = File.open(file, [:binary, :read])
        %StreamSplit{device: fd, split_token: split_token}
      end,
      fn %StreamSplit{} = state ->
        read_next(state)
      end,
      fn %StreamSplit{device: device} ->
        File.close(device)
      end
    )
  end

  ##### PRIVATE #####

  defp read_next(%StreamSplit{device: fd, buffer: buffer} = state) do
    case IO.read(fd, 4096) do
      :eof ->
        halt_stream(state)

      {:error, _reason} ->
        halt_stream(state)

      data ->
        try_split(state, buffer <> data)
    end
  end

  defp try_split(%StreamSplit{split_token: token, stop: stop} = state, data) do
    case String.split(data, token, parts: 2, trim: true) do
      [a, b] ->
        {[a], %{state | buffer: b}}

      _ ->
        if stop do
          {[data], %{state | buffer: ""}}
        else
          read_next(%{state | buffer: data})
        end
    end
  end

  defp halt_stream(%StreamSplit{buffer: ""} = state) do
    {:halt, state}
  end

  defp halt_stream(%StreamSplit{buffer: buffer} = state) do
    try_split(%{state | stop: true, buffer: ""}, buffer)
  end
end
