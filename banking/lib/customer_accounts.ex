defmodule Banking.CustomerAccounts do
  def init do
    # To keep state - account information in a HashDict
    {:ok, agent} = Agent.start_link fn -> HashDict.new end
    agent
  end

  def get_account(agent, account_id) do
    # fetch account information for the given account_id
    hash =  Agent.get(agent, fn hdict -> hdict end)
    HashDict.get(hash, account_id)
  end

  def update_account(agent, arg) do
    # handle update operations on accounts
    IO.puts "received update request with args"
    res = 
       case arg[:type] do
         :deposit -> 
           do_deposit(agent, arg)  
           get_account(agent, arg[:id])
         :withdraw -> "do withdraw"
         :get_bal -> "do get bal"
       end
  end

  def do_deposit(agent, arg) do
    Agent.update(agent, fn hdict -> 
    [id, amount] = [arg[:id], arg[:amount]]
    bal = hdict[id]
    bal = if bal do bal + amount else amount end
    IO.inspect "new bal is #{bal}"
    HashDict.put(hdict, arg[:id], bal) 
    end)
  end





end
