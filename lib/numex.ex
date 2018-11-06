defmodule NumEx do
  @moduledoc """
  Documentation for Numex.
  """

  @doc """
  Addition of two lists

  ## Examples

      iex> NumEx.add([1.0, 2.0], [3.0, 4.0])
      [4.0, 6.0]

  """
  def add(a, b) do
    _add(a, b, [])
  end
  defp _add([], [], ans) do
    ans
  end
  defp _add([h1 | t1], [h2 | t2], ans) do
    _add(t1, t2, ans ++ [Float.floor(h1 + h2, 8)])
  end
  def add_mul(aa, b) do
    _add_mul(aa, b, [])
  end
  defp _add_mul([], _, res) do
    res
  end
  defp _add_mul([ha | ta], b, res) do
    _add_mul(ta, b, res ++ [add(ha, b)])
  end
  def transpose(list) do
    _transpose(list, [])
  end
  defp _transpose([], res) do
    res
  end
  defp _transpose(list, res) do
    {vec, next} = _transpose_head(list, {[], []})
    _transpose(next, res ++ [vec])
    # _transpose([], next)
  end
  defp _transpose_head([], result) do
    result
  end
  defp _transpose_head([[h | t] | tail], {res, next}) when t != [] do
    _transpose_head(tail, {res ++ [h], next ++ [t]})
  end
  defp _transpose_head([[h | _] | tail], {res, next}) do
    _transpose_head(tail, {res ++ [h], next})
  end

  def dot(aa, bb) do
    bbt = transpose(bb)
    _dot(aa, bbt, [])
  end
  defp _dot([], _, res) do
    res
  end
  defp _dot([ha | ta], bbt, res) do
    IO.inspect(ha)
    res = res ++ [_dot_row(ha, bbt, [])]
    _dot(ta, bbt, res)
  end
  defp _dot_row(_, [], vec) do
    vec
  end
  defp _dot_row(a, [hb | tb], vec) do
    vec = vec ++ [_dot_calc(a, hb, 0)]
    _dot_row(a, tb, vec)
  end
  defp _dot_calc([], _, res) do
    res
  end
  defp _dot_calc([ha | ta], [hb | tb], res) do
    _dot_calc(ta, tb, Float.floor(res + ha * hb, 8))
  end
end