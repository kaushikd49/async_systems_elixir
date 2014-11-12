use Mix.Config

     config :logger, :console,
       level: :info,
       foo: :bar,
       format: "$date $time [$level] $metadata$message\n",
       metadata: [:user_id]
       
       
       ###  Custom configurations go below ###
     config :general,
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
         ip_addr: {"108.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         death: {[:send, 10], [:recv, 89], [:unbounded, 93], [:send, 17]},
         delay: 1,
         port: 80
       ],
       [
         name: :BankOfAmerica,
         chain_length: 4,
         ip_addr: {"109.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         death: {[:recv, 78], [:unbounded, 83], [:send, 84], [:recv, 94]},
         delay: 1,
         port: 80
       ],
       [
         name: :CitiBank,
         chain_length: 4,
         ip_addr: {"110.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         death: {[:recv, 24], [:unbounded, 84], [:send, 98], [:recv, 5]},
         delay: 1,
         port: 80
       ],
       [
         name: :HSBCBank,
         chain_length: 4,
         ip_addr: {"111.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         death: {[:recv, 61], [:unbounded, 49], [:send, 47], [:recv, 56]},
         delay: 1,
         port: 80
       ],
   }
