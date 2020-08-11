cleos create account eosio eosio.token EOS7SP5KNgtKACqLK5Dh6Nj6Kx5GkYgpTrHUMTw7btm8KS671kZLo EOS7SP5KNgtKACqLK5Dh6Nj6Kx5GkYgpTrHUMTw7btm8KS671kZLo
cleos set contract eosio.token ~/dev/token/token

cleos create account eosio accta EOS7SP5KNgtKACqLK5Dh6Nj6Kx5GkYgpTrHUMTw7btm8KS671kZLo EOS7SP5KNgtKACqLK5Dh6Nj6Kx5GkYgpTrHUMTw7btm8KS671kZLo
cleos create account eosio acctb EOS7SP5KNgtKACqLK5Dh6Nj6Kx5GkYgpTrHUMTw7btm8KS671kZLo EOS7SP5KNgtKACqLK5Dh6Nj6Kx5GkYgpTrHUMTw7btm8KS671kZLo
cleos push action eosio.token create '["eosio.token", "-1.00 TOKEN"]' -p eosio.token
cleos push action eosio.token issue '["eosio.token", "100.00 TOKEN", "issue"]' -p eosio.token
cleos push action eosio.token transfer '["eosio.token", "accta", "10.00 TOKEN", "xfer"]' -p eosio.token
cleos push action eosio.token transfer '["eosio.token", "acctb", "10.00 TOKEN", "xfer"]' -p eosio.token