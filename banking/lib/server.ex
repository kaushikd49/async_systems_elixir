defmodule Banking.Server do
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def make_transaction(server, arg) do
      GenServer.call(server, arg)
    end
  
    def deposit(server, req_id, account_name, amount) do
      GenServer.call(server, [req_id: req_id, type: :deposit, account_name: account_name, amount: amount])
    end

    def withdraw(server, req_id, account_name, amount) do
      GenServer.call(server, [req_id: req_id, type: :withdraw, account_name: account_name, amount: amount])
    end

    def get_balance(server, req_id, account_name) do
      GenServer.call(server, [req_id: req_id, type: :get_balance, account_name: account_name])
    end

    def init(opts) do
      accounts = Banking.CustomerAccounts.init()
      sleep_time = opts[:delay]
      response = [next: opts[:next], accounts: accounts, processed_trans: HashDict.new, name: opts[:name], 
        ip_addr: elem(opts[:ip_addr], opts[:index]), port: opts[:port], delay: opts[:delay], chain_length: opts[:chain_length]]
      log("created server with definition #{inspect response} sleeping for #{sleep_time}ms before initing")
      :timer.sleep(sleep_time)
      {:ok, response}
    end


    def handle_call(arg, _from, state) do
      log("received call with arguments: #{inspect arg}")
      log("current state: #{inspect state}")
      
      [response, new_state] = 
       cond do
         arg[:chain_extension] != nil -> extend_chain(arg, state)
         true -> perform_transaction(arg, state)
       end
      {:reply, response, new_state} 
    end

    def extend_chain(arg, state) do
      IO."muhahaha extending chain ***"
    end

    def perform_transaction(arg, state) do
      server_side_req_id = get_server_side_req_id(arg[:req_id], arg[:account_name], arg[:type])
      processed_trans = state[:processed_trans][server_side_req_id] 
      [response, new_state] = 
        cond do
          processed_trans != nil -> 
            [processed_trans, nil]  
          is_inconsistent?(state[:processed_trans], server_side_req_id) ->
            return_response(server_side_req_id, :InconsistentWithHistory, state, arg)
          arg[:type] == :get_balance ->  
            return_response(server_side_req_id, :Processed, state, arg)
          true -> 
            outcome = Banking.CustomerAccounts.update_account(state[:accounts], arg)
            return_response(server_side_req_id, outcome, state, arg)
        end
        if state[:next] && arg[:type] != :get_balance do
          log("passing update to next server #{inspect state[:next]}")
          GenServer.call(state[:next], arg)
        else
         log("tail sending response: #{inspect response}")
        end
       [response, (new_state || state)]
   end

    # Function that handles response construction and saves it too.
    def return_response(server_side_req_id, outcome, state, arg) do
      IO.puts "outcome is #{outcome}"
      account = arg[:account_name]
      balance = Banking.CustomerAccounts.get_balance(state[:accounts], account) 
      resp = [req_id: arg[:req_id], outcome: outcome, balance: balance, account_name: account]  
      sub_hash = HashDict.put(state[:processed_trans], server_side_req_id, resp)
      state = add_nested_hashdict(state, :processed_trans, server_side_req_id, resp)
      [resp, state]
    end


    def is_inconsistent?(processed_trans, server_side_req_id) do
      id_parts = String.split(server_side_req_id, "_")
      [req_id|tail1] = id_parts
      [account_name|tail2] = tail1
      res = (is_present_trans(processed_trans, req_id, account_name, :deposit) || 
            is_present_trans(processed_trans, req_id, account_name, :withdraw))
      res
    end

    def is_present_trans(processed_trans, req_id, account_name, type) do
      temp = get_server_side_req_id(req_id, account_name, type)
      processed_trans[temp] != nil
    end


    # To identify duplicate requests
    def get_server_side_req_id(req_id, account_name, type) do
      req_id <> "_" <> account_name <> "_" <> Atom.to_string(type)
    end  

    def add_nested_hashdict(hash, key, nested_key, nested_val) do
      Keyword.put(hash, key, HashDict.put(hash[key], nested_key, nested_val))
    end

    def log(msg) do
      Utils.log("Server: #{inspect self} #{msg}")
    end
end
