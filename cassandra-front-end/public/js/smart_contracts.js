const node_instance = 'https://api.zan.top/public/starknet-sepolia/rpc/v0_10'

// initialize provider for Devnet
const myProvider = new RpcProvider({ nodeUrl: node_instance });

// account credentials
const accountAddress = '0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691';
const privateKey     = '0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9';

const myAccount = new Account({
  provider: myProvider,
  address: accountAddress,
  signer: privateKey,
});