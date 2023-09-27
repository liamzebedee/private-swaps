pragma circom 2.1.5;

include "../lib/deposit_lib.circom";

component main {
    public [ assetId, assetAmount ]
} = Deposit();
