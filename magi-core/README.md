
Tempest stack:

 - Solidity + Circom.
 - Deployed multichain using Niacin.
 - Forge. Local fork testing + Solidity tests.
 - E2E tests with Jest.
 - TypeScript contract types with Typechain.

## Install.

```sh
# Install Circom CLI.
git clone https://github.com/iden3/circom.git
cd circom/
cargo build --release
npm install -g snarkjs
cargo install circomspect

# Install packages.
bun i
```

## Test using local mainnet fork.

```sh
# EVM fork of Ethereum Mainnet.
anvil --fork-url https://mainnet.infura.io/v3/66d7501cf069433380edf0d9f7346c72

# Deploy contracts.
./scripts/deploy.sh
```

## Deploy.

We use `niacin` for deployments.

```sh
./scripts/build-circuits.sh
./scripts/deploy.sh
./scripts/forknet.sh
```