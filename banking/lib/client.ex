defmodule Banking.Client do
  
  def perform(args, head, tail) do
      resp = apply(Banking.Server, args[:method], [head|args[:args]])
      Utils.log("client got result #{inspect resp} from #{inspect tail}")
  end

end

