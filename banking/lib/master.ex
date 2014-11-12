# Needs to keep track of clients, banking server chains
defmodule Banking.Master do

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
    chains = opts[:chains]
    master = self()
    master_child = spawn_link(fn -> __MODULE__.loop(master) end) 
    response = [chains: chains, master_child: master_child, uptime_dict: HashDict.new]
    {:ok, response}
   end

   def handle_call(arg, _from, state) do
    [response, new_state] =
      cond do
        arg[:check_uptime] -> check_uptime(state) 
        true -> ["done", state]
      end
    {:reply, response, new_state} 
   end

   # check uptimes for all servers
   def check_uptime(state) do
    [chains, uptime_dict] = [state[:chains], state[:uptime_dict]]
    num = tuple_size(chains)
    chains = 
    for i <- 0..(num-1) do
      chain = elem(chains, i)
      chain = List.to_tuple(chain)
      all_uptime_check(chain, i, uptime_dict)
      Tuple.to_list(chain)
    end
    new_state = Keyword.put(state, :chains, List.to_tuple(chains))
    ["done", new_state]
   end


   def all_uptime_check(chain, i, uptime_dict) do
     log("uptime check for the chain #{i}:#{inspect chain}")
     chain = check_head_uptime(chain, elem(chain,0), uptime_dict)
     chain = check_tail_uptime(chain, elem(chain, tuple_size(chain)-1), uptime_dict)
     chain = chain_uptime_check(chain, uptime_dict)
   end

   def chain_uptime_check(chain, uptime_dict) do
    func = fn (chain_tup,i,uptime_dict) -> check_if_server_up(chain_tup,i,uptime_dict) end
    iterate_and_modify(chain, 1, tuple_size(chain)-2, func, uptime_dict)
   end

   def iterate_and_modify(tuple, i, stop, func, uptime_dict) when i <= stop do
    new_tuple = func.(tuple,i,uptime_dict)
    iterate_and_modify(new_tuple, i+1, stop, func, uptime_dict)
   end

   def iterate_and_modify(tuple, i, stop, func, uptime_dict) when i > stop do
    tuple
   end

   def check_head_uptime(chain, head, uptime_dict) do
     log("head uptime check #{inspect head}")
     chain
   end

   def check_tail_uptime(chain, tail, uptime_dict) do
     log("tail uptime check #{inspect tail}")
    chain
   end

   def check_if_server_up(chain, i, uptime_dict) do
     log("intermediate server uptime check #{i}:#{inspect elem(chain,i)}")
    chain
   end


   def loop(server) do
    :timer.sleep(100) # todo: move 10 to config
    GenServer.call(server, [check_uptime: true])
    loop(server)
   end

   def log(msg) do
     Utils.log("Master: #{msg}")
   end
end

