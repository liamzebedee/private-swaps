pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/switcher.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";

template Test() {
    // =======
    // Inputs.
    // =======

    // input
    signal input x;
    signal input y;
    signal output s;


}

component main = Test();