defmodule Banking.ServerTest do

  use ExUnit.Case, async: true
  setup do
    {:ok, bank_server} = Banking.Server.start_link(["bar"])
    {:ok, bank_server: bank_server}
  end


  test "Deposit requests to server", %{bank_server: bank_server} do
    assert make_call_to_server(bank_server, [req_id: "1.1.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 1000)
    assert make_call_to_server(bank_server, [req_id: "1.2.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 2000) 
    assert make_call_to_server(bank_server, [req_id: "1.1.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 1000)
    assert make_call_to_server(bank_server, [req_id: "1.2.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 2000) 
    assert make_call_to_server(bank_server, [req_id: "1.3.1", type: :deposit, account_name: "124", amount: 1000 ], :Processed, 1000)
  end

  #  test "Withdraw requests to server", %{bank_server: bank_server} do
  #    assert make_call_to_server(bank_server, [type: :deposit, account_name: 123, amount: 1000 ]) == 1000
  #    #assert make_call_to_server(bank_server, [type: :withdraw, account_name: 123, amount: 100]) == 900    
  #  end

  def make_call_to_server(bank_server, arg, outcome, balance) do
    resp = Banking.Server.make_transaction(bank_server, arg)
    assert resp == [req_id: arg[:req_id], outcome: outcome, balance: balance, account_name: arg[:account_name]]
  end


end
