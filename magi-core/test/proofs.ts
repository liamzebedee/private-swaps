import { BigNumber } from "ethers";

const ethers = require('ethers')
const snarkjs = require("snarkjs");
const crypto = require('crypto')
const circomlib = require('circomlib-old')
const bigInt = snarkjs.bigInt
// import { MerkleTree, ProofPath } from 'fixed-merkle-tree'
const MerkleTree = require('fixed-merkle-tree')

async function proveCircuit(name: string, args: any) {
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    // const { proof, publicSignals } = await snarkjs.plonk.fullProve(
        args,
        __dirname + `/../build-groth/${name}_js/${name}.wasm`,
        __dirname + `/../build-groth/${name}.final.zkey`
        // __dirname + `/../build/${name}_js/${name}.wasm`,
        // __dirname + `/../build/${name}.zkey`
    );

    console.log("Proof: ");
    // console.log(JSON.stringify(proof, null, 1));

    const verificationKey = require(`../build-groth/${name}.verify-key.json`)
    // const verificationKey = require(`../build/${name}.verify-key.json`)
    const res = await snarkjs.groth16.verify(verificationKey, publicSignals, proof);
    // const res = await snarkjs.plonk.verify(verificationKey, publicSignals, proof);

    if (!res) {
        throw new Error(`Proof for "${name}" circuit run failed to verify`)
    }

    return {
        proof,
        publicSignals
    }
}

// TODO took this from another package, but it appears it's a version mismatch
// this isn't acturally corresponding with the og pkg.
export declare type ProofPath = {
    pathElements: string[];
    pathIndices: number[];
    pathRoot: string;
};

interface WithdrawProofArgs {
    deposit: DepositLeaf
    root: string
    leafProof: ProofPath

    recipient: string
    relayer: string
    fee: string
    refund: string
}

interface DepositLeaf {
    assetId: string
    assetAmount: string
    nullifier: string
    secret: string
}

function leBuff2int(buffer) {
    let result = BigInt(0);
    for (let i = buffer.length - 1; i >= 0; i--) {
        result <<= 8n;
        result += BigInt(buffer[i]);
    }
    return result;
}


export async function withdrawProof(args: WithdrawProofArgs) {
    const {
        leafProof,
        deposit
    } = args

    const args2 = {
        assetId: BigNumber.from(deposit.assetId).toString(),
        assetAmount: BigNumber.from(deposit.assetAmount).toString() ,
        
        nullifier: leBuff2int(deposit.nullifier).toString(),
        secret: leBuff2int(deposit.secret).toString(),

        recipient: BigNumber.from(args.recipient).toString(),
        relayer: BigNumber.from(args.relayer).toString(),
        fee: BigNumber.from(args.fee).toString(),
        refund: BigNumber.from(args.refund).toString(),
        // recipient: args.recipient,
        // relayer: args.relayer,
        // fee: args.fee,
        // refund: args.refund,
        
        // Leaf proof.
        root: BigNumber.from(args.root).toString(),
        pathElements: leafProof.pathElements,//.map(x => (BigInt(x)).toString()),
        pathIndices: leafProof.pathIndices.map(x => x.toString()) //.map(x => (BigInt(x)).toString()),
    }
    console.log(args2)

    return await proveCircuit(`withdraw`, args2)
};


export class MerkleTreeAccumulator {
    constructor(public tree) {
    }

    /*
     * Creates a MerkleTreeAccumulator from on-chain events.
     * @param {provider} The ethers provider
     * @param {Tempest} The Tempest contract
     */
    static async loadFromChain(provider, Tempest) {
        // Load events from Tempest contract.
        const CommitmentEvent = Tempest.interface.events['Commitment(uint256,bytes32)']
        const logs = await provider.getLogs({
            fromBlock: 0,
            toBlock: "latest",
            address: Tempest.address,
            topics: CommitmentEvent.topics
        });

        let eventFilter = Tempest.filters.Commitment()
        let events = await Tempest.queryFilter(eventFilter)
        
        // Create the tree.
        // $TEMPEST_TREE_LEVELS_GLOBAL
        const levels = 21
        let tree = new MerkleTree(levels)
        
        // Insert the leaves.
        const commitments = events.map(event => event.args.commitment)
        commitments.map(el => {
            console.log('commitment', el)
            tree.insert(el)
        })

        return new MerkleTreeAccumulator(tree)
    }

    leafProof(leafIndex: number) {
        const root = this.tree.root()
        return {
            ...this.tree.path(leafIndex),
            pathRoot: root
        }
    }
}

type Groth16Proof = {
    pi_a: string[];
    pi_b: [string, string][];
    pi_c: string[];
    protocol: string;
    curve: string;
};


export class ProofUtils {
    static groth16ToSolidityArgs(proof: Groth16Proof) {
        // verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[8] calldata _pubSignals)
        /*
        {
            pi_a: [
                '20133448161053412055937482052493697265532922174382059898892316534935221051850',
                '19167995126396722360939353150567532115073762301900785631008203127181550933413',
                '1'
            ],
            pi_b: [
                [
                '181567776766611651889981334517863169623413649576343495866530014475206226411',
                '874041755479501451874571696793165102955029171875551282148962891923782483357'
                ],
                [
                '20405086201808437478262833073843346430094447409077567214744508497484128804707',
                '15861753231014767702677895152105714644292155212660200912333555815311084570177'
                ],
                [ '1', '0' ]
            ],
            pi_c: [
                '15904578448569183327875035208317283976394759743560435963058860230670161085069',
                '19347163182028770057245197207898792254458204294756187612634397528147380987796',
                '1'
            ],
            protocol: 'groth16',
            curve: 'bn128'
        }

        $ cat build-groth/public.json
        [
            "20252849929019867475864394291207471239631981084412904414959540517904418319706",
            "1443183589592586370390142772176969406211436648901",
            "5",
            "10790867042336372263681774206345909942204927814828582600907150684597784989573",
            "0",
            "0",
            "0",
            "0"
        ]
        */

        const [_pA, _pB, _pC] = [
            [proof.pi_a[0], proof.pi_a[1]],
            [
                [proof.pi_b[0][1], proof.pi_b[0][0]],
                [proof.pi_b[1][1], proof.pi_b[1][0]],
            ],
            [proof.pi_c[0], proof.pi_c[1]]
        ]

        return {_pA, _pB, _pC}
    }
    
    // Convert a PLONK proof JSON object into the `proofArgs` array format accepted by the Solidity verifier.
    static plonkToSolidityArgs(plonkProof: any) {
        let arg_proof: string[] = []

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
