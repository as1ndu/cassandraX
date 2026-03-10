# change state of contract

# sncast --account=dev invoke --contract-address=0x07644f9a2f6b3c3a808b228517cbbcf9f1876c3f24ff1f685e6663674d853471 --function=update_bitcoin_price --arguments 42 --network=sepolia

# erc20.approve(this_contract, amount)
# 0x512feac6339ff7889822cb5aa2a86c848e9d392bb0e3e237c008674feed8343 usdc address 
# amount * 10^7
# [working]
# sncast   --account=dev  invoke --contract-address=0x512feac6339ff7889822cb5aa2a86c848e9d392bb0e3e237c008674feed8343 --function=approve --arguments '0x07644f9a2f6b3c3a808b228517cbbcf9f1876c3f24ff1f685e6663674d853471, 150000000' --network=sepolia

# deposit_usdc (amount: u256)
# amount * 10 ^ 6
# [working]
# sncast   --account=dev  invoke --contract-address=0x07644f9a2f6b3c3a808b228517cbbcf9f1876c3f24ff1f685e6663674d853471 --function=deposit_usdc --arguments 10000000 --network=sepolia

# withdraw_usdc (amount: u256)
# amount * 10 ^ 6
# [working]
# sncast   --account=dev  invoke --contract-address=0x07644f9a2f6b3c3a808b228517cbbcf9f1876c3f24ff1f685e6663674d853471 --function=withdraw_usdc --arguments 5000000 --network=sepolia

# write_option_contract(option_contract :OptionContract)
sncast --account dev invoke \
  --contract-address "0x07644f9a2f6b3c3a808b228517cbbcf9f1876c3f24ff1f685e6663674d853471" \
  --function "write_option_contract" \
  --arguments 'cassandrax_contracts::OptionContract { 
      expiry: 0x323032362D4D41522D3331, 
      option_type: 0x43, 
      strike_price: 500,
      premium: 5, 
      option_buyer: 0x0, 
      option_writer: 0x0, 
      pay_off: 0 
    }'\
  --network 'sepolia'