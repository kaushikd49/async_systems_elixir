defmodule Banking.ServerChain do
  
  def make_server_chain(num_servers, next) when num_servers < 2 do
    [get_server(next)]
  end

  def make_server_chain(num_servers, next) do
    current_server = get_server(next)
    make_server_chain(num_servers - 1, current_server) ++ [current_server]
  end

  def get_server(next) do
    {:ok, bank_server} = Banking.Server.start_link([next: next])
    bank_server
  end

  def make_chain_and_get_head_and_tail(num) do
    servers = Banking.ServerChain.make_server_chain(num, nil)
    server_tuple = List.to_tuple(servers)
    log "servers initialized are #{inspect server_tuple}"
    res = [elem(server_tuple, 0), elem(server_tuple, tuple_size(server_tuple) -1)]
    log "head and tail servers are #{inspect res}"
    res
  end

  def log(msg) do
    Utils.log("BankingServerChain: #{msg}")
  end

end
