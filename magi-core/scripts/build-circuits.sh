#!/usr/bin/env bash
set -ex

# Compiles a Circom circuit into a Solidity verifier.
build_contract() {
    name=$1
    contract_name=$2
    
    circom circuits/verifiers/$name.circom \
        -o build/ \
        --wasm \
        --r1cs --sym -c

    # Generate the PLONK circuit verification key based on Phase 1 entropy.
    npx snarkjs plonk setup build/$name.r1cs vendor/powersOfTau28_hez_final_18.ptau build/$name.zkey

    # Export verification key.
    npx snarkjs zkey export verificationkey build/withdraw.zkey build/$name.verify-key.json

    # Generate a Solidity verifier.
    npx snarkjs zkey export solidityverifier build/$name.zkey src/verifiers/$contract_name.sol
    # remove hardhat import for foundry
    sed -i '' '/import "hardhat\/console.sol";/d' src/verifiers/$contract_name.sol
    sed -i '' "s/PlonkVerifier/$contract_name/" src/verifiers/$contract_name.sol
}



[ -d build ] || mkdir build


# Deposit.
# build_contract "verifiers/deposit" "DepositVerifier"

# Withdraw.
npx ejs -n -l _ circuits/lib/withdraw_lib.ejs.circom > circuits/lib/withdraw_lib.circom
build_contract "withdraw" "WithdrawVerifier"

# Swap
# build_contract "swap" "SwapVerifier"





### Proofing and verifying.

# Generate a SNARK proof (PLONK).
# npx snarkjs plonk prove test_final.zkey demo1/output.wtns demo1/proof.json demo1/public.json

# circom circuits/test.circom \
#     -o build/ \
#     --wasm \
#     --r1cs --sym

# node build/test_js/generate_witness.js build/test_js/test.wasm demo1/input.json demo1/output.wtns