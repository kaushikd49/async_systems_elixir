defmodule Utils do
  require Logger


  def get_head_tail(list) do
    tuple = List.to_tuple(list)
    [elem(tuple, 0), elem(tuple, tuple_size(tuple) -1)]
  end

  def log(data) do
    Logger.info "#{data}"
  end

  def last(tuple) do
    elem tuple, tuple_size(tuple)-1
  end

  def sizeoflist(list) do
    tuple_size(List.to_tuple(list))
  end

end

