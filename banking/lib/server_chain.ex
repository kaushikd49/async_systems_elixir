defmodule Banking.ServerChain do
  
  def make_server_chain(num_servers, next, bank_conf) when num_servers < 2 do
    [get_server(next, bank_conf, num_servers)]
  end

  def make_server_chain(num_servers, next, bank_conf) do
    current_server = get_server(next, bank_conf, num_servers)
    make_server_chain(num_servers - 1, current_server, bank_conf) ++ [current_server]
  end

  def get_server(next, bank_conf, num_server) do
    conf = Keyword.put(bank_conf, :next, next)
    conf = Keyword.put(bank_conf, :index, num_server-1)

    {:ok, bank_server} = Banking.Server.start_link(conf)
    bank_server
  end

  def make_chain_and_get_head_and_tail(bank_conf) do
    servers = Banking.ServerChain.make_server_chain(bank_conf[:chain_length], nil, bank_conf)
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
