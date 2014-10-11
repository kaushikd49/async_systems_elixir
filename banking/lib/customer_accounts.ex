defmodule Banking.CustomerAccounts do
  def init do
    # To keep state - account information in a HashDict
    {:ok, agent} = Agent.start_link fn -> HashDict.new end
    agent
  end

  # fetch account information for the given account_id
  def get_account(agent, account_id) do
    hash =  Agent.get(agent, fn hdict -> hdict end)
    HashDict.get(hash, account_id)
  end

  # handle update operations on accounts
  def update_account(agent, arg) do
    res = 
       case arg[:type] do
         :deposit -> 
           do_deposit(agent, arg)  
         :withdraw -> "do withdraw"
           do_withdraw(agent, arg) 
         :get_bal -> "do get bal"
       end
  end

  def do_deposit(agent, arg) do
    Agent.update(agent, fn hdict -> 
    [id, amount] = [arg[:id], arg[:amount]]
    bal = hdict[id]
    bal = if bal do bal + amount else amount end
    Utils.log("Balance for account #{id} after deposit is #{bal}")
    HashDict.put(hdict, arg[:id], bal) 
    end)
    get_account(agent, arg[:id])
  end

  def do_withdraw(agent, arg) do
    
  end
end
