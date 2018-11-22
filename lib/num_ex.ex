defmodule NumEx do
  @moduledoc """
  Documentation for Numex.
  """

  defstruct l: []
  @type t :: %NumEx{l: list}

  defimpl Inspect do
    import Inspect.Algebra
    def inspect(%NumEx{l: arr}, ops) do
      concat(["array(", to_doc(arr, ops), ")"])
    end
  end

  def array(list) do
    %NumEx{l: list}
  end

  import Kernel, except: [+: 2, -: 2, /: 2, *: 2]
  # override operations do import to make it available
  @spec left + NumEx.t :: NumEx.t when left: NumEx.t
  def left + right when is_map(left) do
    array(add(left.l, right.l))
  end
  @doc guard: true
  @spec integer + integer :: integer
  @spec float + float :: float
  @spec integer + float :: float
  @spec float + integer :: float
  def left + right do
    :erlang.+(left, right)
  end

  @spec left - NumEx.t :: NumEx.t when left: NumEx.t
  def left - right when is_map(left) do
    array(sub(left.l, right.l))
  end
  @doc guard: true
  @spec integer - integer :: integer
  @spec float - float :: float
  @spec integer - float :: float
  @spec float - integer :: float
  def left - right do
    :erlang.-(left, right)
  end

  @spec left * NumEx.t :: NumEx.t when left: NumEx.t
  def left * right when is_map(left) do
    array(mult(left.l, right.l))
  end
  @doc guard: true
  @spec integer * integer :: integer
  @spec float * float :: float
  @spec integer * float :: float
  @spec float * integer :: float
  def left * right do
    :erlang.*(left, right)
  end

  @spec left / NumEx.t :: float when left: NumEx.t
  def left / right when is_map(left) do
    array(div_list(left.l, right))
  end
  @doc guard: true
  @spec number / number :: float
  def left / right do
    :erlang./(left, right)
  end

  defimpl Enumerable, for: NumEx do
    def count(%NumEx{l: arr}) do
      { :ok, length(arr)}
    end
    def member?(%NumEx{l: arr}, val) when is_list(hd arr) do
      res =
       arr
        |> Flow.from_enumerable
        |> Flow.map(fn x -> Enum.any?(x, fn x -> x == val end) end)
        |> Enum.any?
      { :ok, res }
    end
    def member?(%NumEx{l: arr}, val) do
      { :ok, Enum.any?(arr, fn x -> x == val end) }
    end
    def reduce(%NumEx{l: arr}, acc, func) when is_list(hd arr) do
      func_wrap = fn x, {:cont, a} -> func.(x, a) end
      res =
        arr
        |> Enum.map(
          fn vec -> 
            vec = Enum.reverse(vec)
            {_, res} = :lists.foldl(func_wrap, acc, vec)
            res 
          end)
        {:cont, NumEx.array(res)}
      end
    def reduce(%NumEx{l: arr}, acc, func) when is_list(arr) do
      func_wrap = fn x, {:cont, a} -> func.(x, a) end
      {:cont, res} = :lists.foldl(func_wrap, acc, arr)
      {:cont, NumEx.array(res)}
    end
    import Enumerable, except: [map: 3]
    def map(%NumEx{l: enumerable}, fun) do
      IO.inspect(enumerable)
      enumerable
      |> Enum.reduce([], fn x, acc -> [fun.(x) | acc] end)
      |> Enum.reverse()
    end
  end

  @doc """
  Addition of two lists

  ## Examples

      iex> NumEx.add([1.0, 2.0], [3.0, 4.0])
      [4.0, 6.0]

  """
  def add(list, b) when is_list(hd list) do
    list 
    |> Enum.map(&(add(&1, b)))
  end
  def add(list, b) do
    Enum.zip(list, b)
    |> Enum.map(fn ({x, y}) -> x + y end)
  end

  def mult(listA, listB) when is_list(hd listA) and is_list(hd listB) do
    # {res, _} =
    Enum.zip(listA, listB)
    |> Flow.from_enumerable(max_demand: 1)
    |> Flow.map(fn {a, b} -> mult(a, b) end)
    |> Enum.to_list
    # |> Enum.map(fn ({a, b}) -> mult(a, b) end)
  end
  def mult(list, b) when is_list(hd list) do
    list |> Enum.map(&(mult(&1, b)))
  end
  def mult(list, b) when is_list b do
    Enum.zip(list, b) |> Enum.map(fn ({x, y}) -> Float.floor(x * y, 8) end)
  end
  def mult(list, b) do
    list |> Enum.map(&(Float.floor(&1 * b, 8)))
  end
  def transpose(list) when is_list(hd list) do
    arr = List.duplicate([], length(hd list))
    list |> Enum.reduce(arr, fn (xx, arr) -> _transpose(xx, arr) end)
    |> Enum.map(fn (x) -> Enum.reverse(x) end)
  end
  def transpose(list) do
    _transpose(list, List.duplicate([], length(list)))
  end
  defp _transpose(list, arr) do
    list
    |> Enum.reduce(arr, fn (x, arr) -> (tl arr)++[[x]++(hd arr)] end)
  end

  def div_list(list, denom) when is_list(hd list) do
    list 
    |> Enum.map(&(div_list(&1, denom)))
  end
  def div_list(list, denom) do
    list 
    |> Enum.map(fn(x) -> Float.floor(x / denom, 8) end)
  end

  def sub(listA, listB) when is_list(hd listA) and is_list(hd listB) do
    Enum.zip(listA, listB)
    |> Enum.map(fn ({as, bs}) -> sub(as, bs) end)
  end
  def sub(list, b) when is_list(hd list) do
    list |> Enum.map(fn (aa) -> sub(aa, b) end)
  end
  def sub(a, b) when is_list b do
    Enum.zip(a, b) 
    |> Enum.map(fn {x, y} -> Float.floor(x - y, 8) end)
  end
  def sub(a, b) do
    a |> Enum.map(&(&1 - b))
  end

  def dot(aa, bb) when is_list(hd aa) do
    bbt = transpose(bb)
    {res, _} =
      aa
      |> Enum.with_index
      |> Flow.from_enumerable(max_demand: 1)
      |> Flow.map(fn {list, idx} -> {_dot_row(list, bbt), idx} end)
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.unzip
    res
  end
  def dot(a, b) do
    _dot_calc(a, b)
  end
  defp _dot_row(a, b) do
    b |> Enum.map(&(_dot_calc(a, &1)))
  end
  defp _dot_calc(a, b) do
    Enum.zip(a, b)
    |> Enum.reduce(0, fn ({a, b}, acc) -> Float.floor(acc + a * b, 8) end)
  end

  def sum(mat) do
    mat
    |> Flow.from_enumerable(max_demand: 1)
    |> Flow.map(&sum(&1, 1))
    |> Enum.sum
  end
  def sum(mat, 0) do
    sum(transpose(mat), 1)
  end
  def sum(mat, 1) when is_list(hd mat) do
    mat 
    |> Enum.map(&(Enum.sum(&1)))
  end
  def sum(vec, 1) do
    vec |> Enum.sum
  end
  def repeat(list, n) when is_list(hd list) do
    List.duplicate((hd list), n)
  end
  def repeat(list, n) do
    List.duplicate(list, n)
  end

  def zeros_like(list) when is_list(hd list) do
    list |> Enum.reduce([], fn (x, acc) 
      -> [List.duplicate(0.0, length(x))] ++ acc end)
  end
  def zeros_like(list) when is_list(hd list) do
    Enum.reverse(list)
    |> Enum.reduce([], fn row, arr -> [zeros_like(row)] ++ arr end)
  end
  def zeros_like(list) do
    List.duplicate([0.0], length(list))
  end

  def zeros(n, :int) do
    List.duplicate(0, n)
  end
  def zeros(n, :float) do
    List.duplicate(0.0, n)
  end
  def zeros(n, dim, :int) do
    List.duplicate(List.duplicate(0, n), dim)
  end
  def zeros(n, dim, :float) do
    List.duplicate(List.duplicate(0.0, n), dim)
  end

  def one_hot(n, t) do
    0..n-1
    |> Enum.map(&(if &1 != t, do: 0, else: 1))
  end

  def argmax(list) when is_list(hd list) do
    Enum.map(list, &(argmax(&1)))
  end
  def argmax(list) do
    elem(list |> Enum.with_index 
              |> Enum.max_by(&(elem(&1, 0))), 1)
  end

  def softmax(x) when is_list (hd x) do
    x |> Enum.map(&(softmax(&1)))
  end
  def softmax(x) do
    x = sub(x, Enum.max(x)) |> Enum.map(&(:math.exp(&1))) # do sub to avoid overflow
    div_list(x, Enum.sum(x))
  end

  def avg(list) do
    Enum.sum(list) / length(list)
  end

  def sqrt(x) when is_list(hd x) do
    x |> Enum.map(&sqrt(&1))
  end
  def sqrt(x) when is_list(x) do
    x |> Enum.map(&:math.sqrt(&1))
  end
  def sqrt(x) do
    :math.sqrt(x)
  end

  def pow(x, n) when is_list(hd x) do
    x |> Enum.map(&pow(&1, n))
  end
  def pow(x, n) when is_list(x) do
    x |> Enum.map(&:math.pow(&1, n))
  end
  def pow(x, n) do
    :math.pow(x, n)
  end
end