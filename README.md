# cassandraX

A Decentralized Options Exchange on Starknet

- A Bitcoin Options Exchange on Starknet.
- Buy & Write (create) Bitcoin Options.
- Options are cash settled and cash secured.
- USDC used for cash settlement.

## USDC resources

- USDC Sepolia contract address - [0x0512...ed8343](https://sepolia.voyager.online/contract/0x0512feac6339ff7889822cb5aa2a86c848e9d392bb0e3e237c008674feed8343)
- Get Sepolia USDC here - [Circle USDC Faucet](https://faucet.circle.com/)

## Smart contracts

Cairo contracts are in the `cassandra_contract` folder.

Or just Deploy contract from Class Hash

```bash
sncast --account dev deploy --class-hash 0x019e865dcf3d2b1b736133e0913b42830acad474fa07bf1555322d603250653e  --network sepolia
```

See deployed contract on Sepolia - [0x056d193fc54a247e26752a208dd7e6cb9c66507ac1f5f72f8a97b9501e3d291f](https://sepolia.voyager.online/contract/0x056d193fc54a247e26752a208dd7e6cb9c66507ac1f5f72f8a97b9501e3d291f)

## Front End

The front end code lives in, `cassandra-front-end`;

To run the front end

```bash
cd cassandra-front-end
```

```bash
npm i 
```

```bash
npm run dev
```

It should be running localy on  `http://localhost:5173/`

### Demos

Link to youtube video - [https://www.youtube.com/watch?v=W8wP56wz4T0](https://www.youtube.com/watch?v=W8wP56wz4T0)

<!-- Live demo on sepolia testnet () - [link]() -->

![screen-shot](/media/screenshot.png)