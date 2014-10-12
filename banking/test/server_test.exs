defmodule Banking.ServerTest do

  use ExUnit.Case, async: true
  setup do
    {:ok, bank_server} = Banking.Server.start_link(["bar"])
    {:ok, bank_server: bank_server}
  end


      test "Deposit requests to server", %{bank_server: bank_server} do
        make_call_and_assert(bank_server, [req_id: "1.1.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 1000)
        make_call_and_assert(bank_server, [req_id: "1.2.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 2000) 
        make_call_and_assert(bank_server, [req_id: "1.1.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 1000)
        make_call_and_assert(bank_server, [req_id: "1.2.1", type: :deposit, account_name: "123", amount: 1000 ], :Processed, 2000) 
        make_call_and_assert(bank_server, [req_id: "1.3.1", type: :deposit, account_name: "124", amount: 1000 ], :Processed, 1000)
      end

  test "Withdraw requests to server", %{bank_server: bank_server} do
    make_call_and_assert(bank_server, [req_id: "1.3.0", type: :deposit, account_name: "124", amount: 1000 ], :Processed, 1000)
    make_call_and_assert(bank_server, [req_id: "1.3.0", type: :withdraw, account_name: "124", amount: 1000 ], :InconsistentWithHistory, 1000)
    make_call_and_assert(bank_server, [req_id: "1.3.1", type: :withdraw, account_name: "124", amount: 1000 ], :Processed, 0)
    make_call_and_assert(bank_server, [req_id: "1.3.2", type: :withdraw, account_name: "125", amount: 1000 ], :InsufficientFunds, 0)
  end

  def make_call_and_assert(bank_server, arg, outcome, balance) do
    resp = Banking.Server.make_transaction(bank_server, arg)
    assert [req_id: arg[:req_id], outcome: outcome, balance: balance, account_name: arg[:account_name]] == resp
  end


end
