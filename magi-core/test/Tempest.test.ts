import { describe, expect, beforeAll, test } from '@jest/globals';
import { Deposit, TempestLib, createTempestLib } from './tempest';
import { MerkleTreeAccumulator, ProofUtils, withdrawProof } from './proofs';
import { BigNumber, ethers } from 'ethers';

const deployments = require('../deployments/fork-mainnet')

const provider = new ethers.providers.JsonRpcProvider()
const signer = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider) // 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266

import { ERC20__factory, Tempest__factory, WithdrawVerifier__factory } from '../types/ethers-contracts'

const Tempest = Tempest__factory.connect(
    deployments.Tempest.address,
    signer
)

let tempestLib: TempestLib
let deposits: Deposit[] = []
let account
// DAI.
const dai = ERC20__factory.connect(
    "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    signer
)

const { formatEther, parseEther } = ethers.utils

beforeAll(async () => {
    tempestLib = await createTempestLib()
    account = await signer.getAddress()

    const deposit = tempestLib.createDeposit({
        assetId: dai.address,
        assetAmount: parseEther('400'),
    })

    deposits.push(deposit)
})

describe('end-to-end flow', () => {
    const PROOF_TIMEOUT = 60_000 * 3 // 30s to generate proofs

    test('preconditions', async () => {
        const [deposit] = deposits
        console.log(`account: ${account}`)

        // Buy 1 ETH worth of DAI from Uniswap V3.
        const { abi: V3SwapRouterABI } = require('@uniswap/v3-periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json')
        const uniV3Router = new ethers.Contract(
            "0xE592427A0AEce92De3Edee1F18E0157C05861564",
            V3SwapRouterABI,
            signer
        )
        const deadline = Math.floor(Date.now() / 1000) + 60 * 10; // 10 minutes deadline
        const ethAmountToSpend = parseEther('1')
        
        const WETH_ADDRESS = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
        const params = {
            tokenIn: WETH_ADDRESS,
            tokenOut: dai.address,
            fee: 3000,
            recipient: account,
            deadline: deadline,
            amountIn: ethAmountToSpend,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0,
        }

        await uniV3Router.exactInputSingle(params, {
            value: ethAmountToSpend
        })
        
        // Check balance.
        const balance = await dai.balanceOf(account)
        console.log(`balance: ${formatEther(balance)} DAI`)
        expect(!balance.isZero()).toBe(true)

        // Set+Check allowance.
        await dai.approve(Tempest.address, deposit.assetAmount)
        const allowance = await dai.allowance(account, Tempest.address)
        expect(!allowance.isZero()).toBe(true)
    })

    test('deposit', async () => {
        const [deposit] = deposits
        const tx = await Tempest.deposit({
            token: dai.address,
            amount: deposit.assetAmount,
            spendKeyCommitment: deposit.spendKeyCommitment
        })

        const receipt = await tx.wait(1)
        // @ts-ignore
        console.log(receipt.events)
        console.log(receipt.events[1].args)


        // Check balance.
        const balance = await dai.balanceOf(Tempest.address)
        console.log(`balance: ${formatEther(balance)} DAI`)
        expect(!balance.isZero()).toBe(true)

        expect(true)
    }, PROOF_TIMEOUT)

    test('withdraw', async () => {
        const [deposit] = deposits

        // Setup Merkle tree acc.
        const merkleTreeAcc = await MerkleTreeAccumulator.loadFromChain(provider, Tempest)

        // Prove deposit leaf.
        // Find the index of when it was emitted.
        console.log(`spendKeyCommitment`, deposit.spendKeyCommitment)
        const commitment = await Tempest.computeCommitment(
            dai.address,
            deposit.assetAmount,
            deposit.spendKeyCommitment
        )

        // console.log(
        //     "commitment",
        //     commitment
        // )
        // console.log(`index`, merkleTreeAcc.tree.indexOf(commitment))
        const leafIndex = merkleTreeAcc.tree.indexOf(commitment)
        const leafProof = merkleTreeAcc.leafProof(leafIndex)
        // console.log(`tree root (local):`, merkleTreeAcc.tree.root())
        // console.log(`tree root (chain):`, await Tempest.getLastRoot())

        // Prove withdraw.
        const root = await Tempest.getLastRoot()
        const gasPrice = await provider.getGasPrice()
        const gasUsed = BigNumber.from(1_700_000)
        const relayerFee = gasPrice.mul(gasUsed)
        console.log(`relayer fee: ${formatEther(relayerFee)} ETH`)
        const withdrawDetails = {
            recipient: "0x0c853c205ee57614838106b46f5e19e7d41967b1",
            relayer: "0x0c853c205ee57614838106b46f5e19e7d41967b1",
            fee: relayerFee,
            refund: "0"
        }
        const { proof, publicSignals } = await withdrawProof({ 
            // @ts-ignore TODO
            deposit,
            leafProof, 
            root,
            ...withdrawDetails
        })

        console.log(`proof generated`)

        // Call Tempest.withdraw.
        let [nullifierHash,] = publicSignals
        // const root = "0x" + BigInt(leafProof.pathRoot).toString(16)
        console.log(proof)

        // Verify proof using Solidity verifier.
        const WithdrawVerifier = WithdrawVerifier__factory.connect(
            deployments.WithdrawVerifier.address,
            signer
        )

        const { _pA, _pB, _pC } = ProofUtils.groth16ToSolidityArgs(proof)
        
        // @ts-ignore
        const res = await WithdrawVerifier.verifyProof(_pA, _pB, _pC, publicSignals)
        expect(res).toBe(true)
    
        // @ts-ignore
        const args = {
            ...ProofUtils.groth16ToSolidityArgs(proof),
            _pubSignals: publicSignals.map(x => BigNumber.from(x)),

            nullifierHash: BigNumber.from(nullifierHash),
            assetId: dai.address,
            assetAmount: deposit.assetAmount,
            root,
            
            recipient: withdrawDetails.recipient,
            relayer: withdrawDetails.relayer,
            relayerFeeETH: withdrawDetails.fee,
            refund: withdrawDetails.refund
        }
        console.log(args)

        // @ts-ignore
        const tx = await Tempest.withdraw(args)
        const receipt = await tx.wait(1)

        console.log(tx)
        console.log(receipt)
        
    }, PROOF_TIMEOUT)

    test('swap', async () => {
        // Deposit DAI.
        // ============

        // Swap 50% of our DAI for ETH.
        // ============================

        // Generate swap proof. /////////

        // Precompute the swap output from Uniswap with configurable slippage.
        // Pass the swap and slippage into the proof.
        // Generate a proof of this swap completing. 
        // This design won't be straightforward. Let's explain the conceptual aspects first.
        // Conceptually, the user only has one leaf per asset type in the tree.
        // For example, an ETH and a DAI balance.
        // The proof:
        // - proves we own a DAI leaf.
        // - reveals the portion of the DAI balance necessary for a swap.
        // - <swap is performed extra-circuit on chain>
        // - both the DAI and the ETH leaf are destroyed.
        // - two new leaves are created:
        //   1. DAI - with the balance minus what we used for the swap.
        //   2. ETH - with the balance of our existing ETH leaf + the swapped output.
        // - these leaves are returned by the proof, for insertion into the tree.
        // 
        // Why?
        // 
        // This design means the user only ever manages N leaves for M asset types.
        // The alternative is having a leaf for each asset UXTO - ie.
        // - 20 DAI leaf
        // - 100 DAI leaf
        // - 0.5 ETH leaf
        // And then in order to use these leaves, we must prove all of them.
        // Where d is the depth of the merkle tree, this is O(d*NM) to withdraw all our assets.
        // vs. the 1st design which is O(d*M).
        // A user will likely only have on average like 5 assets. So this is much better.
        // 
        // Drawbacks.
        // 
        // The drawback of this approach, where instead of swapping to get some ETH, and then
        // calling .deposit - is that we can only handle deterministic amounts of output from swaps.
        // If the swap incurs slippage, unfortunately we cannot adjust the proof on-chain to include
        // the new amount, because the leaf commitment cannot be recomputed without revealing its value.
        // As such, the slippage goes to the protocol.
    })
});

