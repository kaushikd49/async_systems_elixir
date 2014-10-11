defmodule Banking.ServerTest do

  use ExUnit.Case, async: true
  setup do
    {:ok, bank_server} = Banking.Server.start_link(["bar"])
    {:ok, bank_server: bank_server}
  end


  test "Deposit requests to server", %{bank_server: bank_server} do
    assert make_call_to_server(bank_server, [type: :deposit, id: 123, amount: 1000 ]) == 1000
    assert make_call_to_server(bank_server, [type: :deposit, id: 123, amount: 1000 ]) == 2000
    assert make_call_to_server(bank_server, [type: :deposit, id: 124, amount: 1000 ]) == 1000
  end

  test "Withdraw requests to server", %{bank_server: bank_server} do
    assert make_call_to_server(bank_server, [type: :deposit, id: 123, amount: 1000 ]) == 1000
    #assert make_call_to_server(bank_server, [type: :withdraw, id: 123, amount: 100]) == 900    
  end

  def make_call_to_server(bank_server, arg) do
    Banking.Server.make_transaction(bank_server, arg)
  end


end
