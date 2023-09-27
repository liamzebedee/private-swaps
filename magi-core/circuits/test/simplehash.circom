pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/pedersen.circom";
include "merkleTree.circom";
// include "../node_modules/circomlib/circuits/mimcsponge.circom";
// include "../node_modules/circomlib/circuits/mimc.circom";

// // Computes MiMC([left, right])
// template HashLeftRight() {
//     signal input left; 
//     signal input right;
//     signal output hash;

//     component hasher = MiMCSponge(2, 220, 1);
//     hasher.ins[0] <== left;
//     hasher.ins[1] <== right;
//     hasher.k <== 0;
//     hash <== hasher.outs[0];
// }

template Simplehash() {
    // Inputs.
    signal input assetId;      // u256
    
    // Outputs.
    signal output commitment;

    // Function.
    var levels = 22;
    component tree = MerkleTreeChecker(levels);
    tree.leaf <== 5123123123123;
    tree.root <== 1221212121212;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== i;
        tree.pathIndices[i] <== i + 1;
    }




    // component bits_assetId = Num2Bits(256);
    // bits_assetId.in <== assetId;

    // component hash = HashLeftRight();
    // hash.ins[0] = bits_assetId;

    // commitment = hash.hash;

    // signal output out[2];

    // component hash = MiMCSponge(1, 220, 1);
    // hash.ins[0] <== 12312312321321323323342;
    // hash.k <== 0;
    // commitment <== hash.outs[0];
    // hash.inputs[0] <== assetId;

    // component hash = Pedersen(256);
    // for (var i = 0; i < 256; i++) {
    //     hash.in[i] <== bits_assetId.out[i];
    // }

}

component main = Simplehash();
