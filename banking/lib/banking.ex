defmodule Banking.Main do
  
  def main(path) do
    conf = get_conf(path)
    IO.inspect conf
  end
  
  def get_conf(path) do
    use Mix.Config
    IO.puts "loading configuration #{path}"
    Mix.Config.import_config path
    conf = Mix.Config.read! path
    conf[:general]
  end
end

Banking.Main.main System.argv 

