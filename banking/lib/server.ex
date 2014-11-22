defmodule Banking.Server do
  use Timex
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
      IO.puts "received opts for initing #{inspect opts}"
      ip = elem(opts[:ip_addr], opts[:index])
      [death_type, death_val] = 
        cond do 
          opts[:death] -> elem(opts[:death], opts[:index])
          true -> [:unbounded, 100]
        end
      if(death_val == "random") do
        death_val = :random.uniform * 20
        log("random deathval set to #{death_val}")
      end
      server = self()
      server_child = spawn_link(fn -> __MODULE__.loop(server, opts[:hbeat_fq]) end) 
      [sleep_time, accounts] = [opts[:delay], Banking.CustomerAccounts.init()]

      response = [ip: ip, next: opts[:next], accounts: accounts, processed_trans: HashDict.new, name: opts[:name], port: opts[:port], delay: opts[:delay], chain_length: opts[:chain_length], master: opts[:master], death_type: death_type, death_val: death_val, sent: 0, recvd: 0, hbeat_fq: opts[:hbeat_fq]]
      log("created server with definition #{inspect response} sleeping for #{sleep_time}ms before initing")
      :timer.sleep(sleep_time)
      {:ok, response}
    end


    def handle_call(arg, _from, state) do
      log("received call with arguments: #{inspect arg}")
      log("current state: #{inspect state}")
      [response, new_state] = 
       cond do
         arg[:set_tail] -> ["done", Keyword.put(state, :set_tail, arg[:set_tail])
]
         is_dead?(state) -> ["dead", state]
         arg[:send_hrtbeat] != nil -> send_hrtbeat(state)
         arg[:handle_adjust_tail] != nil -> handle_adjust_tail(arg, state)
         arg[:new_tail_update] != nil -> handle_new_tail_update(arg, state)
         true -> perform_transaction(arg, state)
       end
      {:reply, response, new_state} 
    end
 
   def receipt_termination(state) do
    increment_op(state, :recv, :recvd)
   end

   def sent_termination(state) do
    increment_op(state, :send, :sent)
   end 

   def is_dead?(state) do
    dead_state?(state, :recv, :recvd) or dead_state?(state, :send, :sent)
   end

   def increment_op(state, type, counter_type) do
    state = Keyword.put(state, counter_type, state[counter_type]+1) 
    log("incrementing counter to #{inspect state[counter_type]}")
    if(is_dead?(state)) do
      log("process is now killed as count is #{state[counter_type]}")
    end
    state
   end

   def dead_state?(state, type, counter_type) do
    res = (state[:death_type] == type and state[counter_type] >= state[:death_val]) 
    res
   end


   def send_hrtbeat(state) do
     resp =
       cond do
         state[:master] != nil ->
           heartbeat = Utils.now()
           log("sending heartbeat:#{heartbeat} to master") 
           resp = GenServer.call(state[:master], [heartbeat: heartbeat])
           #log("resp from master after sending heartbeat was #{inspect resp}")
           "sent_heartbeat"
        true -> :dead_no_hbeat
       end
     [resp, state]
   end

    def adjust_tail(server, arg) do
      GenServer.call(server, Keyword.put(arg, :handle_adjust_tail, true))   
    end

    def handle_new_tail_update(arg, state) do
      state = Keyword.put(state, :processed_trans, arg[:processed_trans])
      state = Keyword.put(state, :accounts, arg[:accounts])
      log("after new tail's update #{inspect state}")
      [state, state]
    end

    def handle_adjust_tail(arg, state) do
      new_tail_args = [accounts: state[:accounts], processed_trans: state[:processed_trans]]
      [new_tail, new_tail_args] = [arg[:new_tail], Keyword.put(new_tail_args,:new_tail_update, true)]
      IO.inspect "calling new tail #{inspect new_tail} with args #{inspect new_tail_args}"
      # let the new tail update the hist obj and other info   
      new_tail_state = GenServer.call(new_tail, new_tail_args) 
      # Update tail to point to new tail
      new_state = Keyword.put(state, :next, arg[:new_tail])
      log("Peforming tail adjustment. Next server changing from #{inspect state[:next]} to #{inspect new_state[:next]}. New tail state: #{inspect new_tail_state}")
      [new_tail_state, new_state]
    end

    def perform_transaction(arg, state) do
      state = receipt_termination(state)
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
        if !state[:set_tail] and state[:next] && arg[:type] != :get_balance do
          log("passing update to next server #{inspect state[:next]}")
          GenServer.call(state[:next], arg)
        else
         log("tail sending response: #{inspect response}")
        end
       new2_state = sent_termination((new_state || state))
       [response, new2_state]
   end

    # Function that handles response construction and saves it too.
    def return_response(server_side_req_id, outcome, state, arg) do
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

   def loop(server, freq) do
    :timer.sleep(freq) # todo: move to config
    resp = GenServer.call(server, [send_hrtbeat: true])
    IO.puts "resp #{inspect resp}"
    cond do
      resp != "dead" -> loop(server, freq)
      true -> log("not invoking sendbeat from #{inspect server}")
    end
   end


    def log(msg) do
      Utils.log("Server: #{inspect self} #{msg}")
    end
end
