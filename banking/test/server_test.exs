defmodule Banking.ServerTest do

  use ExUnit.Case, async: true
  setup do
    {:ok, bank_server} = Banking.Server.start_link(["bar"])
    {:ok, bank_server: bank_server}
  end


  test "Deposit requests to server", %{bank_server: bank_server} do
    deposit_and_assert(bank_server, "1.1.1", "123", 1000, :Processed, 1000)
      deposit_and_assert(bank_server, "1.2.1", "123", 1000, :Processed, 2000) 
      deposit_and_assert(bank_server, "1.1.1", "123", 1000, :Processed, 1000)
      deposit_and_assert(bank_server, "1.2.1", "123", 1000, :Processed, 2000) 
      deposit_and_assert(bank_server, "1.3.1", "124", 1000, :Processed, 1000)
    end

    test "Withdraw requests to server", %{bank_server: bank_server} do
      deposit_and_assert(bank_server, "1.3.0", "124", 1000, :Processed, 1000)
      withdraw_and_assert(bank_server, "1.3.0", "124", 1000, :InconsistentWithHistory, 1000)
      withdraw_and_assert(bank_server, "1.3.1", "124", 1000, :Processed, 0)
      withdraw_and_assert(bank_server, "1.3.2", "125", 1000, :InsufficientFunds, 0)
    end

  def deposit_and_assert(bank_server, req_id, account_name, amount, outcome, balance) do
    resp = Banking.Server.deposit(bank_server, req_id, account_name, amount)
    assert [req_id: req_id, outcome: outcome, balance: balance, account_name: account_name] == resp
  end

  def withdraw_and_assert(bank_server, req_id, account_name, amount, outcome, balance) do
    resp = Banking.Server.withdraw(bank_server, req_id, account_name, amount)
    assert [req_id: req_id, outcome: outcome, balance: balance, account_name: account_name] == resp
   end
end
