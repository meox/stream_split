defmodule StreamSplit do
  defstruct(
    device: nil,
    buffer: [],
    split_token: ",",
    chunk_size: 4_194_304,
    stop: false,
    tagging: false,
    drop_last: false,
    first: true
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
        state
        |> read_next()
        |> tag_first(state)
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

  defp read_next(%StreamSplit{device: fd, chunk_size: size} = state, pending \\ "") do
    case IO.read(fd, size) do
      :eof ->
        halt_stream(state)

      {:error, _reason} ->
        halt_stream(state)

      data ->
        try_split(state, pending <> data)
    end
  end

  defp try_split(%StreamSplit{split_token: token, buffer: buffer, stop: stop, drop_last: drop_last} = state, data) do
    case buffer ++ String.split(data, token, trim: true) do
      [] ->
        if stop do
          {[tag_last(data, state)], %{state | buffer: []}}
        else
          read_next(state, data)
        end

      [_] ->
        {[tag_last(data, state)], %{state | stop: true, buffer: []}}

      [a, b] ->
        if drop_last do
          {[tag_last(a, state)], %{state | stop: true, buffer: []}}
        else
          {[a, tag_last(b, state)], %{state | stop: true, buffer: []}}
        end
      xs ->
        l = Enum.count(xs)
        {ys, buffer} = Enum.split(xs, l - 2)
        {ys, %{state | buffer: buffer}}
    end
  end

  defp halt_stream(%StreamSplit{buffer: []} = state) do
    {:halt, state}
  end

  defp halt_stream(%StreamSplit{} = state) do
    try_split(%{state | stop: true}, "")
  end

  defp tag_first({:halt, _state} = input, %StreamSplit{}), do: input
  defp tag_first({_data, _state} = input, %StreamSplit{tagging: false}), do: input
  defp tag_first({_data, _state} = input, %StreamSplit{tagging: true, first: false}), do: input
  defp tag_first({[d | ds], state}, %StreamSplit{tagging: true, first: true}) do
    {[{:first, d} | ds], %{state | first: false}}
  end
  defp tag_first(input, %StreamSplit{} = _state), do: input

  defp tag_last(data, %StreamSplit{tagging: false}), do: data
  defp tag_last(data, %StreamSplit{tagging: true}), do: {:last, data}
end
