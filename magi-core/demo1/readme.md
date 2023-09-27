demo1
=====

What does this demo do?

 * Install latest Circom tooling.
 * Run through the trusted setup for the proofing protocol. Choose PLONK proofs, whcih have universal ceremony.
 * Write and build a simple circuit. 
 * Generate verification key.
 * Generate and verify PLONK proofs manually (JS, offline).
 * Generate and verify PLONK proofs E2E - generating in browser, verifying in contracts.


## Install.

```sh
# Install Circom CLI.
git clone https://github.com/iden3/circom.git
cd circom/
cargo build --release
npm install -g snarkjs
cargo install circomspect

# Install rest.
bun i
```

### Trusted setup.

This is copied largely from the [snarkjs](https://github.com/iden3/snarkjs) docs.

Groth16 requires a trusted ceremony for each circuit. PLONK and FFLONK do not require it, it's enough with the powers of tau ceremony which is universal.

```sh
# 
# Trusted Setup - Phase 1
# 

# Copy a Powers of Tau ceremony checkpoint from the Hermez Network public ceremony.
wget -O "vendor/powersOfTau28_hez_final_15.ptau" https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_15.ptau

# Verify the parameters.
npx snarkjs powersoftau verify vendor/powersOfTau28_hez_final_15.ptau

# 
# Trusted Setup - Phase 2
# 

# Generate the PLONK circuit verification key based on Phase 1 entropy.
npx snarkjs plonk setup build/test.r1cs vendor/powersOfTau28_hez_final_15.ptau test_final.zkey

# Export verification key.
npx snarkjs zkey export verificationkey test_final.zkey verification_key.json
```

### Proofing and verifying.

```sh
# Generate a SNARK proof (PLONK).
node generate_witness.js multiplier2.wasm input.json witness.wtns
npx snarkjs plonk prove test_final.zkey demo1/output.wtns demo1/proof.json demo1/public.json
```

```sh
# Generate a Solidity verifier.
npx snarkjs zkey export solidityverifier test_final.zkey contracts/verifier.sol
# remove hardhat import for foundry
sed -i '' '/import "hardhat\/console.sol";/d' contracts/verifier.sol

# Generate the calldata for `function verifyProof(uint256[24] calldata _proof, uint256[2] calldata _pubSignals)`.
npx snarkjs zkey export soliditycalldata demo1/public.json demo1/proof.json > proof_verify_calldata.json
# $(cat proof_verify_calldata.json | jq --slurp '.[0]')

# Deploy the contract.
anvil
forge create contracts/Verify.sol:Verify --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Verify a proof.
npx ts-node demo1/generate-verify.ts
# ... do this in Remix
```