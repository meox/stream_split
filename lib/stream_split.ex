defmodule StreamSplit do
  defstruct(
    device: nil,
    buffer: "",
    split_token: ",",
    chunk_size: 4_194_304,
    stop: false
  )

  @doc """
  Generate a stream splitting data retrieved from file.

  Return a Stream.

  Arguments:
  - `file`: A that rapresent the file
  - `split_token`: A string used to split data
  """
  @spec split(pid, String.t(), Keyword.t()) :: Enumerable.t()
  def split(device, split_token, opts \\ []) do
    Stream.resource(
      fn ->
        %StreamSplit{device: device, split_token: split_token}
        |> add_opts(opts)
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

  defp add_opts(%StreamSplit{} = s, []), do: s
  defp add_opts(%StreamSplit{} = s, [{k, v} | ks]) do
    s
    |> Map.put(k, v)
    |> add_opts(ks)
  end

  defp read_next(%StreamSplit{device: fd, buffer: buffer, chunk_size: size} = state) do
    case IO.read(fd, size) do
      :eof ->
        halt_stream(state)

      {:error, _reason} ->
        halt_stream(state)

      data ->
        try_split(state, buffer <> data)
    end
  end

  defp try_split(%StreamSplit{split_token: token, stop: stop} = state, data) do
    case String.split(data, token, trim: true) do
      [] ->
        if stop do
          {[data], %{state | buffer: ""}}
        else
          read_next(%{state | buffer: data})
        end
      xs ->
          {xs, state}
    end
  end

  defp halt_stream(%StreamSplit{buffer: ""} = state) do
    {:halt, state}
  end

  defp halt_stream(%StreamSplit{buffer: buffer} = state) do
    try_split(%{state | stop: true, buffer: ""}, buffer)
  end
end
