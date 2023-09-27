const ethers = require('ethers')
const snarkjs = require("snarkjs");

// npx snarkjs plonk prove test_final.zkey demo1/output.wtns demo1/proof.json demo1/public.json
const makeProof = async () => {
    const name = `deposit`
    const { proof, publicSignals } = await snarkjs.plonk.fullProve(
        {
            "assetId": BigInt(contracts.MockDAI.address).toString(),
            "assetAmount": "99900000000000000000", // 99.9
            "nullifier": "123123",
            "secret": "12312"
        },
        __dirname + `/../build/${name}_js/${name}.wasm`,
        __dirname + `/../build/${name}.zkey`
    );

    console.log("Proof: ");
    console.log(JSON.stringify(proof, null, 1));

    const verificationKey = require(`../build/${name}.verify-key.json`)
    const res = await snarkjs.plonk.verify(verificationKey, publicSignals, proof);

    if (res === true) {
        console.log("Verification OK");
    } else {
        console.log("Invalid proof");
    }

    return {
        proof,
        publicSignals
    }
};

const makeWithdrawProof = async (root: string, pathElements: any, pathIndices: any, deposit: any) => {
    const name = `withdraw`

    console.log({
        "assetId": BigInt(deposit.assetId).toString(),
        "assetAmount": deposit.assetAmount,
        "nullifier": deposit.nullifier,
        "secret": deposit.secret,
        "root": root,
        "recipient": "0",
        "relayer": "0",
        "fee": "0",
        "refund": "0",

        // private.
        // nullifier: deposit.nullifier,
        // secret: deposit.secret,
        pathElements: pathElements.map(x => (BigInt(x)).toString()),
        pathIndices: pathIndices.map(x => (BigInt(x)).toString()),
    })

    const { proof, publicSignals } = await snarkjs.plonk.fullProve(
        {
            "assetId": BigInt(deposit.assetId).toString(),
            "assetAmount": deposit.assetAmount,
            "nullifier": deposit.nullifier,
            "secret": deposit.secret,
            "root": root,
            "recipient": "0",
            "relayer": "0",
            "fee": "0",
            "refund": "0",

            // private.
            // nullifier: deposit.nullifier,
            // secret: deposit.secret,
            pathElements: pathElements.map(x => (BigInt(x)).toString()),
            pathIndices: pathIndices.map(x => (BigInt(x)).toString()),
        },
        __dirname + `/../build/${name}_js/${name}.wasm`,
        __dirname + `/../build/${name}.zkey`
    );

    console.log("Proof: ");
    console.log(JSON.stringify(proof, null, 1));

    const verificationKey = require(`../build/${name}.verify-key.json`)
    const res = await snarkjs.plonk.verify(verificationKey, publicSignals, proof);

    if (res === true) {
        console.log("Verification OK");
    } else {
        console.log("Invalid proof");
    }

    return {
        proof,
        publicSignals
    }
};

class ProofUtils {
    static getSolidityArgs(plonkProof: any) {
        let arg_proof: string[] = []
        // let arg_publicSignals = []

        /*
{
  A: [
    '18499355051366918322211027442740921319453327493760597976835934021976016812410',
    '9253421447152750057636133566377729223553213548600200230448006835200280862857',
    '1'
  ],
  B: [
    '10256371499981249108023263988686419143061449221980287023805121595328059815614',
    '19575223291740126068366580803131841323115903961808581076212096838943343080180',
    '1'
  ],
  C: [
    '18310580058993943239283807207580650835669505969891954370136748963629027330608',
    '17152193621706190218810992558987242506409006546760633569179569305868152812470',
    '1'
  ],
        */
        const keys = 'A B C Z T1 T2 T3 Wxi Wxiw'.split(' ')
        keys.map(k => {
            const [a, b] = plonkProof[k];
            // @ts-ignore
            arg_proof.push(a)
            // @ts-ignore
            arg_proof.push(b)
        })

        /*
eval_a: '1110408809307425487982210005317565325662645566856055306218528435490590436901',
eval_b: '451859298191900248511439531852593522508238517523664565904518756471418865383',
eval_c: '13645358852375355605050932165318782199690888813295634581339105696813847177693',
eval_s1: '19903429881500678312829149816765309372418149934078496800425109328708221142272',
eval_s2: '9737038127614171055815198449079756341966171327528500379902956603340346330658',
eval_zw: '16776880014939036829045314645341232763696149112202124689851413037495112130185',
        */

        const keys2 = 'eval_a eval_b eval_c eval_s1 eval_s2 eval_zw'.split(' ')
        keys2.map(k => {
            // @ts-ignore
            arg_proof.push(plonkProof[k])
        })

        return arg_proof
    }
}


const contracts = require('./contracts')

async function main() {
    const provider = new ethers.providers.JsonRpcProvider()
    const signer = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider)

    const Tempest = new ethers.Contract(
        contracts.Tempest.address,
        contracts.Tempest.abi,
        signer
    )

    // const { proof, publicSignals } = await makeProof()
    // console.log(publicSignals)
    // const proofArg = ProofUtils.getSolidityArgs(proof)
    // let [commitment, assetId, assetAmount] = publicSignals

    const snarkjs = require('snarkjs')
    const crypto = require('crypto')
    const circomlib = require('circomlib-old')
    const bigInt = snarkjs.bigInt

    /** Generate random number of specified byte length */
    const rbigint = (nbytes) => bigInt.leBuff2int(crypto.randomBytes(nbytes))

    /** Compute pedersen hash */
    const buildPedersenHash = require("circomlibjs").buildPedersenHash;
    const buildBabyJub = require("circomlibjs").buildBabyjub;
    const babyJub = await buildBabyJub();
    const pedersen = await buildPedersenHash();
    const pedersenHash = data => circomlib.babyJub.unpackPoint(pedersen.hash(data))[0]

    /** BigNumber to hex string of specified length */
    function toHex(number, length = 32) {
        const str = number instanceof Buffer ? number.toString('hex') : BigInt(number).toString(16)
        return '0x' + str.padStart(length * 2, '0')
    }

    function createDeposit({ nullifier, secret }) {
        const deposit: any = { nullifier, secret }
        deposit.preimage = Buffer.concat([deposit.nullifier, deposit.secret])
        deposit.commitment = pedersenHash(deposit.preimage)
        deposit.commitmentHex = toHex(deposit.commitment)
        deposit.nullifierHash = pedersenHash(deposit.nullifier)
        deposit.nullifierHex = toHex(deposit.nullifierHash)
        return deposit
    }

    
    // const res = await Tempest.verifyProof(
    //     proofArg,
    //     publicSignals
    // )

    // console.log(`\nVerify deposit...`)
    let deposit = createDeposit({
        "nullifier": require('crypto').randomBytes(31),
        "secret": require('crypto').randomBytes(31)
    })
    deposit = {
        ...deposit,
        assetId: BigInt(contracts.MockDAI.address).toString(),
        assetAmount: "2", // 99.9
        nullifier: "123123",
        secret: "12312"
    }
    
    // console.log("pedersen",deposit.commitmentHex)
    // const tx = await Tempest.deposit({
    //     token: contracts.MockDAI.address,
    //     assetAmount: deposit.assetAmount,
    //     spendKeyCommitment: deposit.commitmentHex
    // })
    // const receipt = await tx.wait(1)
    // console.log(receipt.events[0].args)

    

    // // 
    // // reconstruct merkle tree.
    // // check that it's valid.
    // // 

    // const depositLeaf = await Tempest.computeCommitment(
    //     contracts.MockDAI.address,
    //     deposit.assetAmount,
    //     deposit.commitmentHex
    // )
    // console.log(
    //     "depositLeaf",
    //     depositLeaf
    // )


    const MerkleTree = require("fixed-merkle-tree")
    const levels = 31
    let tree = new MerkleTree(levels)

    const CommitmentEvent = Tempest.interface.events['Commitment(uint256,bytes32)']
    const logs = await provider.getLogs({
        fromBlock: 0,
        toBlock: "latest",
        address: Tempest.address,
        topics: CommitmentEvent.topics
    });

    let eventFilter = Tempest.filters.Commitment()
    let events = await Tempest.queryFilter(eventFilter)

    const commitments = events.map(event => event.args.commitment)
    commitments.map(el => {
        console.log('commitment', el)
        tree.insert(el)
    })
    // tree.insert('0x' + BigInt(depositLeaf).toString(16))
    // console.log(pathElements, pathIndices)
    console.log("root", tree.root().toString('hex'))

    console.log(
        "lastroot",
        await Tempest.getLastRoot()
    )

    


    /**
     * Generate merkle tree for a deposit.
     * Download deposit events from the tornado, reconstructs merkle tree, finds our deposit leaf
     * in it and generates merkle proof
     * @param deposit Deposit object
     */
    // async function generateMerkleProof(deposit) {
    //     // Get all deposit events from smart contract and assemble merkle tree from them
    //     console.log('Getting current state from tornado contract')
    //     const events = await tornado.getPastEvents('Deposit', { fromBlock: 0, toBlock: 'latest' })
    //     const leaves = events
    //         .sort((a, b) => a.returnValues.leafIndex - b.returnValues.leafIndex) // Sort events in chronological order
    //         .map(e => e.returnValues.commitment)
    //     const tree = new merkleTree(MERKLE_TREE_HEIGHT, leaves)

    //     // Find current commitment in the tree
    //     const depositEvent = events.find(e => e.returnValues.commitment === toHex(deposit.commitment))
    //     const leafIndex = depositEvent ? depositEvent.returnValues.leafIndex : -1

    //     // Validate that our data is correct
    //     const root = tree.root()
    //     const isValidRoot = await tornado.methods.isKnownRoot(toHex(root)).call()
    //     const isSpent = await tornado.methods.isSpent(toHex(deposit.nullifierHash)).call()
    //     assert(isValidRoot === true, 'Merkle tree is corrupted')
    //     assert(isSpent === false, 'The note is already spent')
    //     assert(leafIndex >= 0, 'The deposit is not found in the tree')

    //     // Compute merkle proof of our commitment
    //     const { pathElements, pathIndices } = tree.path(leafIndex)
    //     return { pathElements, pathIndices, root: tree.root() }
    // }



    async function withdraw() {
        // get the hash from the contract.
        const root = await Tempest.getLastRoot()

        // get el at index 0
        const { pathElements, pathIndices } = tree.path(0)
        const { proof, publicSignals } = await makeWithdrawProof(root, pathElements, pathIndices, deposit)
        console.log(publicSignals)
        const proofArg = ProofUtils.getSolidityArgs(proof)

        let [nullifierHash, ] = publicSignals
        
        const tx = await Tempest.withdraw(
            proofArg,
            nullifierHash,
            deposit.assetId,
            deposit.assetAmount,
            root,
            "0x0c853c205ee57614838106b46f5e19e7d41967b1",
            "0x0c853c205ee57614838106b46f5e19e7d41967b1",
            "0",
            "0"
        )

        await tx.wait(1)
        console.log(tx)
    }

    console.log(`\nVerify withdrawal...`)
    await withdraw()
}

main()