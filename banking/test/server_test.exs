defmodule Banking.ServerTest do

  def make_call_to_server(bank_server) do
    resp = Banking.Server.make_transaction(bank_server,[type: :deposit, id: 123, amount: 1000 ])
    IO.puts "recevied resp %%%"
    IO.inspect resp
    resp
  end

  use ExUnit.Case, async: true
  setup do
    {:ok, bank_server} = Banking.Server.start_link(["bar"])
    {:ok, bank_server: bank_server}
  end


  test "receive sync response from server", %{bank_server: bank_server} do
   assert make_call_to_server(bank_server) != nil
   assert make_call_to_server(bank_server) != nil
  end

end
