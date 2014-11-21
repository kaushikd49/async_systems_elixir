defmodule Banking.MasterTest do
  use ExUnit.Case, async: false

  test "failure detection" do
   {:ok, resp} = Banking.Master.start_link([config_file: "smalltest"])
   :timer.sleep(2000)
  end

  # Run this separately to see the effect of dead servers caught
  # new tail sending results also captured
  test "failure detection with dying servers" do
    {:ok, master} = Banking.Master.start_link([config_file: "smalltest"])
    chains = GenServer.call(master, [get_chains: true])
    [bank_server|t] = elem(chains,0)
    deposit_and_assert(bank_server, "1.3.0", "124", 1000, :Processed, 1000)
    deposit_and_assert(bank_server, "1.3.1", "124", 1000, :Processed, 2000)
    deposit_and_assert(bank_server, "1.3.2", "124", 1000, :Processed, 3000)
    :timer.sleep(100)
    deposit_and_assert(bank_server, "1.3.3", "124", 1000, :Processed, 4000)
    deposit_and_assert(bank_server, "1.3.4", "124", 1000, :Processed, 5000)
    :timer.sleep(2000)
    IO.inspect "chains are #{inspect chains}"
   end


    def deposit_and_assert(bank_server, req_id, account_name, amount, outcome, expected_balance) do
      resp = Banking.Server.deposit(bank_server, req_id, account_name, amount)
      assert [req_id: req_id, outcome: outcome, balance: expected_balance, account_name: account_name] == resp
    end
end
