defmodule Banking.MasterTest do
  use ExUnit.Case, async: true

  setup do
    all_conf = get_conf()[:general]
    chains_conf = all_conf[:servers]
    chains =
    for chain_conf <- Tuple.to_list(chains_conf) do
      [[h,t], chain] = Banking.ServerChain.make_chain_and_get(chain_conf)
      chain
    end
    chains = List.to_tuple(chains)
    {:ok, chains: chains}
  end


  test "sample", %{chains: chains} do
   arg = [chains: chains]
   {:ok, master} = Banking.Master.start_link(arg)
   #Banking.Master.loop(master)
   IO.puts "test sleep"
   :timer.sleep(2000)
   IO.inspect master
  end

  def get_conf do
    use Mix.Config
    path = Path.expand("test.exs", "./config")
    IO.puts "loading configuration #{path}"
    Mix.Config.import_config(path)
    conf = Mix.Config.read!(path)
  end
end
