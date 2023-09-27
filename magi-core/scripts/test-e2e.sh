set -ex

# ./scripts/build-circuits.sh
[ -f manifest.json ] && rm manifest.json
./scripts/deploy.sh
niacin generate-npm-pkg > deployments/fork-mainnet.js
npx jest test/Tempest.test.ts --runInBand