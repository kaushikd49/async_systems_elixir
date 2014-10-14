defmodule Banking.Main do
  
  def main(path) do
    conf = get_conf(path)
    #IO.inspect conf
    server_confs = List.to_tuple(conf[:servers])
    IO.inspect tuple_size(server_confs)
    res = for i <- 0..(tuple_size(server_confs)-1) do
      bank_conf = elem(server_confs, i)
      initialize_bank_and_get_head_tail(bank_conf)
    end
    #[head_server, tail_server] = Banking.ServerChain.make_chain_and_get_head_and_tail(3)
  end
 
  def  initialize_bank_and_get_head_tail(bank_conf) do

  end

  def get_conf(path) do
    use Mix.Config
    IO.puts "loading configuration #{path}"
    Mix.Config.import_config path
    conf = Mix.Config.read! path
    conf[:general]
  end
end

unless IO.inspect Mix.env == :test do
  Banking.Main.main System.argv 
end

