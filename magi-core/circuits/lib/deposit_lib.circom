pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/pedersen.circom";
include "merkleTree.circom";

template Deposit() {
    // Inputs.
    signal input assetId;      // u256
    signal input assetAmount;  // u256
    signal input nullifier;    // u248
    signal input secret;       // u248
    
    // Outputs.
    signal output commitment;

    // Function.
    component bits_assetId = Num2Bits(256);
    component bits_assetAmount = Num2Bits(256);
    component bits_nullifier = Num2Bits(248);
    component bits_secret = Num2Bits(248);

    bits_assetId.in <== assetId;
    bits_assetAmount.in <== assetAmount;
    bits_nullifier.in <== nullifier;
    bits_secret.in <== secret;

    component hash = Pedersen(256 + 256 + 248 + 248);
    for (var i = 0; i < 256; i++) {
        hash.in[i] <== bits_assetId.out[i];
    }
    for (var i = 0; i < 256; i++) {
        hash.in[256 + i] <== bits_assetAmount.out[i];
    }
    for (var i = 0; i < 248; i++) {
        hash.in[512 + i] <== bits_nullifier.out[i];
    }
    for (var i = 0; i < 248; i++) {
        hash.in[760 + i] <== bits_secret.out[i];
    }

    commitment <== hash.out[0];
}