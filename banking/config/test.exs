use Mix.Config

     config :logger, :console,
       level: :info,
       foo: :bar,
       format: "$date $time [$level] $metadata$message\n",
       metadata: [:user_id]
       
       
       ###  Custom configurations go below ###
     config :general, 
     foo: :bar  
