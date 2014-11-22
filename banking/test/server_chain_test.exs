defmodule Banking.ServerChainTest do
  use ExUnit.Case, async: false

  test "server chain" do
    bank_conf = elem(Utils.get_conf("smalltest")[:general][:servers], 0)
    num_servers = tuple_size(bank_conf[:ip_addr])
    res = Banking.ServerChain.make_server_chain(num_servers, nil, bank_conf, nil)
    t = List.to_tuple(res)
    assert num_servers == tuple_size(t)
  end
end

