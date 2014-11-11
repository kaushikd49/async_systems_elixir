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
    conf = Keyword.put(conf, :index, num_server-1)
    {:ok, bank_server} = Banking.Server.start_link(conf)
    bank_server
  end

  def make_chain_and_get(bank_conf) do
    servers = Banking.ServerChain.make_server_chain(bank_conf[:chain_length], nil, bank_conf)
    res = Utils.get_head_tail(servers)
    log "servers initialized are #{inspect servers}"
    log "head and tail servers are #{inspect res}"
    [res, servers]
  end

  # Create new tail, pass it to the current tail.
  # The current tail will copy over the relavant info
  # to the new tail and update its own next to point
  # to the new tail.
  def extend_chain(bank_chain, new_tail_conf) do
   chain_tuple = List.to_tuple(bank_chain)
   conf = Keyword.put(new_tail_conf, :index, tuple_size(chain_tuple))
   {:ok, new_tail} = Banking.Server.start_link(conf)
   tail = Utils.last(chain_tuple) 
   resp = Banking.Server.adjust_tail(tail, [new_tail: new_tail])
   [(bank_chain ++ [new_tail]), resp]
  end

  def log(msg) do
    Utils.log("BankingServerChain: #{msg}")
  end

end
