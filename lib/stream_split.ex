defmodule StreamSplit do
  defstruct(
    device: nil,
    buffer: "",
    split_token: ",",
    stop: false
  )

  @doc """
  Generate a stream splitting data retrieved from file.

  Return a Stream.

  Arguments:
  - `file`: A string that rapresent the file path to open
  - `split_token`: A string used to split data
  """
  @spec split(String.t(), String.t()) :: Enumerable.t() | {:error, term}
  def split(file, split_token) when is_binary(file) do
    case File.open(file, [:read]) do
      {:ok, device} ->
        split(device, split_token)

      e ->
        e
    end
  end

  @spec split(pid, String.t()) :: Enumerable.t()
  def split(device, split_token) do
    Stream.resource(
      fn ->
        %StreamSplit{device: device, split_token: split_token}
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
