pragma circom 2.1.5;

include "../lib/withdraw_lib.circom";

component main {
    public [ 
        assetId,
        assetAmount,
        root,
        recipient,
        relayer,
        fee,
        refund
    ]
} = Withdraw(21);
// $TEMPEST_TREE_LEVELS_GLOBAL