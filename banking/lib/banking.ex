defmodule Banking.Main do
  
  def main(path) do
    conf = get_conf(path)
    #args = [method: :get_balance, args: [head_server, "1.1.1", "asdasd"]]
    # Banking.Client.perform(args, head_server, tail_server)
    head_tails = get_server_head_tails(conf)
    clients = get_clients_and_perform(conf, head_tails)
  end

   def get_clients_and_perform(conf, head_tails) do
    confs = List.to_tuple(conf[:clients])
    [h|t] = head_tails
    [h1|t1] = h
     for i <- 0..(tuple_size(confs)-1) do
        conf = elem(confs, i)
        tup_conf = List.to_tuple(conf)
        sub_conf = elem(tup_conf, 0)

                for j <- 0..(tuple_size(tup_conf)-1) do
                  sub_conf = elem(tup_conf, j)
                  IO.inspect "conf is #{inspect sub_conf}"
                  Banking.Client.perform(sub_conf, h1, t1)
                end

                #IO.inspect "conf is #{inspect sub_conf}"
                #Banking.Client.perform([method: :get_balance, args: ["1.1.1", "asdasd"]], h1, t1)
         #end
      end
 
   end

   def get_server_head_tails(conf) do
      server_confs = (conf[:servers])
      server_head_tails = 
      for i <- 0..(tuple_size(server_confs)-1) do
        bank_conf = elem(server_confs, i)
        initialize_bank_and_get_head_tail(bank_conf)
      end
   end 
  def initialize_bank_and_get_head_tail(bank_conf) do
     res = Banking.ServerChain.make_chain_and_get(bank_conf)
     [head_tail, servers] = res
     [head_server, tail_server] = head_tail
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

