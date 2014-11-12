defmodule Banking.MasterTest do
  use ExUnit.Case, async: true


  test "failure detection" do
   {:ok, master} = Banking.Master.start_link([])
   :timer.sleep(2000)
   IO.inspect master
  end

end
