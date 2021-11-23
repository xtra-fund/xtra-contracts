# Xtra contracts

![uml-coinsloot](https://github.com/xtra-fund/xtra-contracts/blob/master/xtra-contracts.svg?raw=true)

To build contracts:

```
npx truffle build
```

To run tests:

```
npx truffle test
```

To run migrations to bsc testnet:

Add 12 mnemonic words to .secret file divided by spaces
```
npx truffle migrate --network bsctestnet
```

To generate UML map run: 

```
npm link sol2uml --only=production
sol2uml ./contracts
```

To create documetation in /docs folder run:  

```
npm install -D solc-0.8@npm:solc@^0.8.6
npx solidity-docgen --solc-module solc-0.8
```

Remixd:

```
npm install -g remixd
remixd -s %PATH%/xtra_contracts/ --remix-ide https://remix.ethereum.org
```