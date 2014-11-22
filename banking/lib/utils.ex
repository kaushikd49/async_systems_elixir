defmodule Utils do
  require Logger
  use Timex

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

  def now() do
    Time.now(:secs) * 1000
  end

  def get_conf(file) do
    use Mix.Config
    path = Path.expand("#{file}.exs", "./config")
    IO.puts "loading configuration #{path}"
    Mix.Config.import_config(path)
    conf = Mix.Config.read!(path)
  end
end

