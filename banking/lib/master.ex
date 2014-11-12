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
    log("yen mage")
    response = [chains: chains, master_child: master_child]
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
    chains = state[:chains]
    num = tuple_size(chains)
    chains = 
    for i <- 0..(num-1) do
      chain = elem(chains, i)
      log("uptime check for the chain #{i}:#{inspect chain}")
      chain = List.to_tuple(chain)
      chain = check_head_uptime(chain, elem(chain,0))
      chain = check_tail_uptime(chain, elem(chain, tuple_size(chain)-1))
      chain = chain_uptime_check(chain)
      Tuple.to_list(chain)
    end
    new_state = Keyword.put(state, :chains, List.to_tuple(chains))
    ["done", new_state]
   end


   def chain_uptime_check(chain) do
    func = fn (chain_tup,i) -> check_if_server_up(chain_tup,i) end
    iterate_and_modify(chain, 1, tuple_size(chain)-2, func)
   end

   def iterate_and_modify(tuple, i, stop, func) when i <= stop do
    new_tuple = func.(tuple,i)
    iterate_and_modify(new_tuple, i+1, stop, func)
   end

   def iterate_and_modify(tuple, i, stop, func) when i > stop do
    tuple
   end

   def check_head_uptime(chain, head) do
     log("head uptime check #{inspect head}")
     chain
   end

   def check_tail_uptime(chain, tail) do
     log("tail uptime check #{inspect tail}")
    chain
   end

   def check_if_server_up(chain, i) do
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

