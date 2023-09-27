demo3
=====

- [x] test the uniswap integration
- [x] design tx relay logic
- [x] fix circomlib issues
- [x] fix proving speeds
- [x] write the e2e test for the swap/withdraw flow
    jest
    deposit
        generate proof
    withdraw
- [ ] 
    swap
        calculate asset price and slippage parameters
        submit tx using a separate relayer account
            verify relayer is recompensated
        perform swap on uni
        verify assets redeposited

        verify what happens if swap fails
- [ ] implement a simple relayer
    send your bundle to an endpoint
    relayer listens for new txs:
        for each tx, submits it onchain to the contract
        reclaims the fee from the tx going through or failing
- [ ] implement a simple merkle tree indexer
    listen to the contracts
    reconstruct the merkle tree
    serve as an RPC endpoint


- [ ] frontend - skeleton
    menu, connect wallet, switch chain, import contracts from .js file
- [ ] frontend - accounts
    sign a message using your browser
- [ ] frontend - deposit
    approve
    send tx
- [ ] frontend - swap
    calculate slippage
    request merkle proof for leaf
    send to relayer
- [ ] frontend - withdraw





next milestone:
- [ ] implement the UI
    deposit tokens
        connect wallet
        generate a simple password
    dashboard - see your balances
    swap tokens on uniswap
    withdraw

    complex bits-
    - relayer api - pickup the 


    batch auction:
        each user submits their order (make, take)
        we run through orders, and match them
        0.1 eth : 200 dai
        prove this match in zk
            
