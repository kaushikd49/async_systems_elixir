defmodule Banking.ServerChainTest do
  use ExUnit.Case, async: true

  test "server chain" do
    num_servers = 4
    bank_conf = 
      [
           name: :CitiBank,
           chain_lenght: 4,
           ip_addr: {"110.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
           delay: 1,
           port: 80
         ]
    res = Banking.ServerChain.make_server_chain(num_servers, nil, bank_conf)
    t = List.to_tuple(res)
    assert num_servers == tuple_size(t)
  end
end

