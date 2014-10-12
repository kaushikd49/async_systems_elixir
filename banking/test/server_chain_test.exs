defmodule Banking.ServerChainTest do
  use ExUnit.Case, async: true

  test "server chain" do
    num_servers = 3
    res = Banking.ServerChain.make_server_chain(num_servers, nil)
    t = List.to_tuple(res)
    assert num_servers == tuple_size(t)
  end
end

