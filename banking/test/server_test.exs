defmodule Banking.ServerTest do

  use ExUnit.Case, async: true
  setup do
    bank_conf =
      [
         name: :BankOfAmerica,
         chain_length: 4,
         ip_addr: {"109.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         delay: 10,
         port: 80
       ]

     [head_server, tail_server] = Banking.ServerChain.make_chain_and_get_head_and_tail(bank_conf)
    {:ok, bank_server: head_server}
  end

    test "Deposit requests to server", %{bank_server: bank_server} do
      deposit_and_assert(bank_server, "1.1.1", "123", 1000, :Processed, 1000)
      deposit_and_assert(bank_server, "1.2.1", "123", 1000, :Processed, 2000) 
      deposit_and_assert(bank_server, "1.1.1", "123", 1000, :Processed, 1000)
      deposit_and_assert(bank_server, "1.2.1", "123", 1000, :Processed, 2000) 
      deposit_and_assert(bank_server, "1.3.1", "124", 1000, :Processed, 1000)
    end
  
    test "Get balance", %{bank_server: bank_server} do
      get_bal_and_assert(bank_server, "1.3.9", "130", 1000, :Processed, 0)
      deposit_and_assert(bank_server, "1.3.0", "124", 1000, :Processed, 1000)
      get_bal_and_assert(bank_server, "1.3.9", "124", 1000, :Processed, 1000)
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
  
   def get_bal_and_assert(bank_server, req_id, account_name, amount, outcome, balance) do
      resp = Banking.Server.get_balance(bank_server, req_id, account_name)
      assert [req_id: req_id, outcome: outcome, balance: balance, account_name: account_name] == resp
   end

   #   test "async call" , %{bank_server: bank_server} do
   #    resp = Banking.Server.create(bank_server, self)
   #    IO.inspect self
   #   end
   #
 end
