defmodule Banking.Server do
    @doc """
        Starts the server rocess.
        """
    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end


    @doc """
        Make a transaction - deposit, withdraw or check balance
    """
    def make_transaction(server, {:type, arg}) do

    end
end
