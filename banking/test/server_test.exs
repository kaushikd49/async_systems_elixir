defmodule Banking.ServerTest do

  use ExUnit.Case, async: false
  setup do
    chains = get_chains()
    [head_server|t] = elem(chains,0)
    {:ok, bank_server: head_server}
  end

   def get_chains do
    {:ok, master} = Banking.Master.start_link([config_file: "smalltest"])
    chains = GenServer.call(master, [get_chains: true])
   end

  def get_sample_conf() do
    all_conf = Utils.get_conf("smalltest")
    confs = all_conf[:general][:servers]
    IO.inspect confs
    conf = elem(confs, 0)
    IO.puts "conf is #{inspect conf}"
    conf
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
  
    def deposit_and_assert(bank_server, req_id, account_name, amount, outcome, expected_balance) do
      resp = Banking.Server.deposit(bank_server, req_id, account_name, amount)
      assert [req_id: req_id, outcome: outcome, balance: expected_balance, account_name: account_name] == resp
    end
  
    def withdraw_and_assert(bank_server, req_id, account_name, amount, outcome, expected_balance) do
      resp = Banking.Server.withdraw(bank_server, req_id, account_name, amount)
      assert [req_id: req_id, outcome: outcome, balance: expected_balance, account_name: account_name] == resp
     end
  
   def get_bal_and_assert(bank_server, req_id, account_name, amount, outcome, expected_balance) do
      resp = Banking.Server.get_balance(bank_server, req_id, account_name)
      assert [req_id: req_id, outcome: outcome, balance: expected_balance, account_name: account_name] == resp
   end

  test "chain extension size" do
    [chain, conf] = sample_chain_and_conf()
    [chain, new_chain, new_tail_state] = do_chain_extension(chain, conf)
    assert Utils.sizeoflist(new_chain) == Utils.sizeoflist(chain) + 1 
  end

  test "chain extension history check" do
    [chain, conf] = sample_chain_and_conf()
    [head, tail] = Utils.get_head_tail(chain)
    deposit_and_assert(head, "4.1.1", "123", 1000, :Processed, 1000)

    [chain, new_chain, new_tail_state] = do_chain_extension(chain, conf)
    [resp] = Dict.values(new_tail_state[:processed_trans])
    get_bal_and_assert(head, "random_req", resp[:account_name], nil, resp[:outcome], resp[:balance])
  end

  def do_chain_extension(chain, conf) do
    conf = add_to_conf(conf, :ip_addr, "new.ip")
    conf = add_to_conf(conf, :death,[:unbounded, 93] )
    [new_chain, new_tail_state] = Banking.ServerChain.extend_chain(chain, conf)    
    [chain, new_chain, new_tail_state]
  end

  def add_to_conf(conf, key, additional_val) do
    tup = List.to_tuple(Tuple.to_list(conf[key]) ++ [additional_val])
    conf = Keyword.put(conf, key, tup)
  end

  def sample_chain_and_conf() do
    conf = get_sample_conf()
    [[h, t], chain] = Banking.ServerChain.make_chain_and_get(conf, nil)
    [chain, conf]
  end
end
