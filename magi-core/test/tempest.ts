/** BigNumber to hex string of specified length */
export function toHex(number, length = 32) {
    const str = number instanceof Buffer ? number.toString('hex') : BigInt(number).toString(16)
    return '0x' + str.padStart(length * 2, '0')
}

export class Deposit {
    // hex
    spendKeyCommitment: string
    
    constructor(
        private lib: TempestLib,
        public nullifier: Buffer,
        public secret: Buffer,
        public assetId: string,
        public assetAmount: string,
    ) {
        const spendKey = Buffer.concat([nullifier, secret])
        const spendKeyCommitment = lib.pedersenHash(spendKey)
        // const commitmentHex = toHex(commitment)
        // const nullifierHash = lib.pedersenHash(nullifier)
        // const nullifierHex = toHex(nullifierHash)
        this.spendKeyCommitment = toHex(spendKeyCommitment)
    }

    commitment() {
        
    }
}

export class TempestLib {
    constructor(
        public pedersenHash: any
    ) { }

    createDeposit({
        assetId,
        assetAmount
    }) {
        const nullifier = require('crypto').randomBytes(31)
        const secret = require('crypto').randomBytes(31)
        // const nullifier = Buffer.from("14")
        // const secret = Buffer.from("122")
        
        let deposit = new Deposit(
            this,
            nullifier,
            secret,
            assetId,
            assetAmount
        )
        return deposit
    }
}

export async function createTempestLib(): Promise<TempestLib> {
    const ethers = require('ethers')
    const snarkjs = require("snarkjs");
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

    return new TempestLib(pedersenHash)
}

