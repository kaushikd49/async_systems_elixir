defmodule Banking.CustomerAccounts do
  def init do
    # To keep state - account information in a HashDict
    {:ok, agent} = Agent.start_link fn -> HashDict.new end
    agent
  end

  # fetch account information for the given account_name
  def get_balance(agent, account_name) do
    hash =  Agent.get(agent, fn hdict -> hdict end)
    HashDict.get(hash, account_name)
  end

  # handle update operations on accounts
  def update_account(agent, arg) do
    res = 
       case arg[:type] do
         :deposit -> 
            do_deposit(agent, arg)
         :withdraw ->
            do_withdraw(agent, arg) 
         :get_bal -> 
            :Processed
       end
  end

  def do_deposit(agent, arg) do
    Agent.update(agent, fn hdict -> 
    [account_name, amount] = [arg[:account_name], arg[:amount]]
    bal = hdict[account_name]
    bal = if bal do bal + amount else amount end
    Utils.log("Balance for account #{account_name} after deposit is #{bal}")
    HashDict.put(hdict, arg[:account_name], bal) 
    end)
    :Processed
  end

  def do_withdraw(agent, arg) do
    
  end
end
