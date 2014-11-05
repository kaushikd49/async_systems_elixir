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
     servers: [
       [
         name: :FederalBank,
         chain_length: 4,
         ip_addr: {"108.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         delay: 1,
         port: 80
       ],
       [
         name: :BankOfAmerica,
         chain_length: 4,
         ip_addr: {"109.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         delay: 1,
         port: 80
       ],
       [
         name: :CitiBank,
         chain_length: 4,
         ip_addr: {"110.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         delay: 1,
         port: 80
       ],
       [
         name: :HSBCBank,
         chain_length: 4,
         ip_addr: {"111.120.12.1", "108.120.12.2", "108.120.12.3","108.120.12.4"},
         delay: 1,
         port: 80
       ],
   ]
