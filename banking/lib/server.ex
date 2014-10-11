defmodule Banking.Server do
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def make_transaction(server, arg) do
      GenServer.call(server, arg)
    end

    ## Server Callbacks
    def init(opts) do
      updates = []
      pending_req = []
      next_server = opts[:next]
      accounts = Banking.CustomerAccounts.init()
      response = [next: next_server, accounts: accounts, pending_req: pending_req, updates: updates]
        {:ok, response}
    end

    def handle_call(arg, _from, state) do
      IO.puts "lets inspect......"
      IO.inspect state
      IO.inspect arg
      resp = Banking.CustomerAccounts.update_account(state[:accounts], arg)
      IO.inspect "recevd resp"
      IO.inspect resp
      {:reply, resp, state}
    end
end
