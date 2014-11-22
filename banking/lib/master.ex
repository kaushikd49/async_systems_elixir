# Needs to keep track of clients, banking server chains
defmodule Banking.Master do
  use Timex

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def extend_chain(state, arg) do
    [chains, conf, index] = [state[:chains], arg[:server_conf], arg[:chain_index]]
    chain = elem(chains, index)
    Banking.ServerChain.extend_chain(chain, conf)
  end
  
   # Should contain server chains, clients and 
   # child process for initiating server uptime check

   def init(opts) do
    master = self()
    IO.inspect opts
    all_conf = Utils.get_conf(opts[:config_file])[:general]
    chains = get_chains(master, all_conf)
    master_conf = all_conf[:master]
    uptime_freq = master_conf[:uptime_fq]
    master_child = spawn_link(fn -> __MODULE__.loop(master, uptime_freq) end) 
    response = [chains: chains, master_child: master_child, uptime_dict: HashDict.new, uptime_fq: uptime_freq, uptime_threshold: master_conf[:uptime_threshold]]
    log("created master #{inspect response}")
    {:ok, response}
   end

   def handle_call(arg, _from, state) do
    [response, new_state] =
      cond do
        arg[:get_chains] -> [state[:chains], state]
        arg[:check_uptime] -> check_uptime(state) 
        arg[:heartbeat] -> recv_heartbeat(arg, state, _from)
        true -> ["done", state]
      end
    {:reply, response, new_state} 
   end

   def recv_heartbeat(arg, state, from) do
    from = elem(from, 0)
    log("receiving hrtbeat #{arg[:heartbeat]} from #{inspect from}")
    [dict, hrtbeat] = [state[:uptime_dict], arg[:heartbeat]]
    dict = HashDict.put(dict, from, hrtbeat)
    new_state = Keyword.put(state, :uptime_dict, dict)
    log("updated heartbeat from server:#{inspect from} to #{inspect hrtbeat}")
    ["heartbeat_recvd", new_state]
   end

   # check uptimes for all servers
   def check_uptime(state) do
    [chains, uptime_dict, threshold] = [state[:chains], state[:uptime_dict], state[:uptime_threshold]]
    num = tuple_size(chains)
    chains = 
    for i <- 0..(num-1) do
      chain = elem(chains, i)
      chain = List.to_tuple(chain)
      all_uptime_check(chain, i, uptime_dict, threshold)
      Tuple.to_list(chain)
    end
    new_state = Keyword.put(state, :chains, List.to_tuple(chains))
    ["done", new_state]
   end


   def all_uptime_check(chain, i, uptime_dict, threshold) do
     log("uptime check for the chain #{i}:#{inspect chain}")
     chain = check_head_uptime(chain, elem(chain,0), uptime_dict, threshold)
     chain = check_tail_uptime(chain, elem(chain, tuple_size(chain)-1), uptime_dict, threshold)
     chain = chain_uptime_check(chain, uptime_dict, threshold)
   end

   def chain_uptime_check(chain, uptime_dict, threshold) do
    func = fn (chain_tup,i,uptime_dict) -> check_if_server_up(chain_tup, i, uptime_dict, threshold) end
    iterate_and_modify(chain, 1, tuple_size(chain)-2, func, uptime_dict, threshold)
   end

   def iterate_and_modify(tuple, i, stop, func, uptime_dict, threshold) when i <= stop do
    new_tuple = func.(tuple,i,uptime_dict)
    iterate_and_modify(new_tuple, i+1, stop, func, uptime_dict, threshold)
   end

   def iterate_and_modify(tuple, i, stop, func, uptime_dict, threshold) when i > stop do; tuple ;end

   def is_dead?(server, uptime_dict, server_type, threshold) do
    [uptime, now] = [uptime_dict[server], Utils.now()]
    is_dead = !uptime or (now - uptime) > threshold # todo move this to config
    diff = uptime && now-uptime
    log("#{server_type} uptime check #{inspect server} is_dead:#{is_dead} now:#{now} threshold:#{threshold} update_at:#{uptime} diff:#{diff}")
    is_dead
   end

   def check_head_uptime(chain, head, uptime_dict, threshold) do
     is_dead = is_dead?(head, uptime_dict, "head", threshold)
     new_chain = chain
     # delete the current head
     if is_dead do
       [h|remaining] = Tuple.to_list(chain) 
       log("deleted dead head #{inspect h}")
       new_chain = List.to_tuple(remaining) 
     end
     new_chain
   end

   def check_tail_uptime(chain, tail, uptime_dict, threshold) do
    is_dead = is_dead?(tail, uptime_dict, "tail", threshold)
     if is_dead do
       tail = elem(chain, tuple_size(chain)-1)
       log("deleted dead tail #{inspect tail}")
       new_tail = elem(chain, tuple_size(chain)-2)
       new_chain = List.to_tuple(
        for i <- 0..tuple_size(chain)-2 do
          elem(chain,i)
        end)
        log("making tail #{inspect new_tail}")
        GenServer.call(new_tail, [set_tail: true]) 
     end
     chain
   end

   def check_if_server_up(chain, i, uptime_dict, threshold) do
     server = elem(chain,i)
     is_dead = is_dead?(server, uptime_dict, "intermediate", threshold)
    chain
   end


   def loop(server, freq) do
    log("master sleeping for #{freq}") 
    :timer.sleep(freq) # todo: move 10 to config
    GenServer.call(server, [check_uptime: true], 2000)
    loop(server, freq)
   end


  def get_chains(master, all_conf) do
    chains_conf = all_conf[:servers]
    chains =
      for chain_conf <- Tuple.to_list(chains_conf) do
        [[h,t], chain] = Banking.ServerChain.make_chain_and_get(chain_conf, master)
        chain
      end
    chains = List.to_tuple(chains)
  end

   def log(msg) do
     Utils.log("Master: #{msg}")
   end
end

