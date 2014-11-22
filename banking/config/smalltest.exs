use Mix.Config

     config :logger, :console,
       level: :info,
       foo: :bar,
       format: "$date $time [$level] $metadata$message\n",
       metadata: [:user_id]
       
       
       ###  Custom configurations go below ###
     config :general,
     master: [uptime_fq: 200, uptime_threshold: 5],
     clients: [
         [
           [method: :get_balance, args: ["1.1.1", "acct_name"]],
           [method: :deposit, args: ["1.1.1", "acct_name", 1500]],
           [method: :withdraw, args: ["1.1.1", "acct_name", 1500]],
           [method: :get_balance, args: ["1.1.1", "acct_name"]]
         ]

      ], 
     servers: {
       [
         name: :FederalBank,
         chain_length: 4,
         hbeat_fq: 100,
         ip_addr: {"108.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         death: {[:send, 15], [:recv, 23], [:unbounded, 93], [:send, 30]},
         delay: 1,
         port: 80
       ]
   }