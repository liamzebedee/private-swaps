pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/pedersen.circom";
include "merkleTree.circom";
include "../lib/range_proof.circom";
include "../lib/deposit_lib.circom";
include "../lib/withdraw_lib.circom";

// Splits a leaf.
// (asset-id, amount) ->   (public  (asset-id, amount)) 
//                         (private (asset-id, amount)) 
template SplitLeaf() {
    // =======
    // Inputs.
    // =======

    // input
    signal input inAssetId;
    signal input inAssetAmount;
    // output.public
    signal input outPublicAssetId;      // u256
    signal input outPublicAssetAmount;  // u256
    // output.private
    signal input outPrivateAssetId;
    signal input outPrivateAssetAmount;
    signal input outPrivateDepositNullifier;
    signal input outPrivateDepositSecret;

    // ========
    // Outputs.
    // ========
    
    signal output outPrivateCommitment;

    // ==========
    // Function.
    // ==========

    // 1. Verify split constraint.
    // `in.amount == out_public.amount + out_private.amount`
    inAssetAmount === outPublicAssetAmount + outPrivateAssetAmount;
    // overflow check
    component rangeCheck = RangeProof(251);
    rangeCheck.in <== outPublicAssetAmount + outPrivateAssetAmount;
    rangeCheck.max_abs_value <== 2**251 - 1;

    // 2. Verify asset ID's match.
    inAssetId === outPublicAssetId;
    inAssetId === outPrivateAssetId;
    
    // 3. Compute private leaf commitment.
    component deposit = Deposit();
    deposit.assetId <== outPrivateAssetId;
    deposit.assetAmount <== outPrivateAssetAmount;
    deposit.nullifier <== outPrivateDepositNullifier;
    deposit.secret <== outPrivateDepositSecret;

    // Output leaves.
    outPrivateCommitment <== deposit.commitment;
}

template Swap(levels) {
    // =======
    // Inputs.
    // =======

    // Public.
    signal input outPublicAssetId;      // u256
    signal input outPublicAssetAmount;  // u256
    signal input root;
    signal input relayer;  // not taking part in any computations
    signal input fee;      // not taking part in any computations
    signal input refund;   // not taking part in any computations

    // Private.
    signal input inAssetId;
    signal input inAssetAmount;
    signal input outPrivateAssetId;
    signal input outPrivateAssetAmount;
    signal input outPrivateDepositNullifier;
    signal input outPrivateDepositSecret;
    signal input nullifier;
    signal input secret;
    signal input pathElements[levels];
    signal input pathIndices[levels];

    // ========
    // Outputs.
    // ========
    
    signal output inNullifierHash;
    signal output outPrivateCommitment;


    // ==========
    // Function.
    // ==========

    // 1. Prove the leaf we are withdrawing.
    // 
    component withdraw = Withdraw(levels);
    withdraw.assetId <== inAssetId;
    withdraw.assetAmount <== inAssetAmount;
    withdraw.root <== root;
    withdraw.recipient <== 0;
    withdraw.relayer <== relayer;
    withdraw.fee <== fee;
    withdraw.refund <== refund;
    withdraw.nullifier <== nullifier;
    withdraw.secret <== secret;
    withdraw.pathElements <== pathElements;
    withdraw.pathIndices <== pathIndices;
    
    // 2. Commit a split.
    // 
    // This outputs two leafs:
    // - public: the token ID and amount
    // - private: just the commitment
    
    component splitLeaf = SplitLeaf();
    // input
    splitLeaf.inAssetId <== inAssetId;
    splitLeaf.inAssetAmount <== inAssetAmount;
    // output.public
    splitLeaf.outPublicAssetId <== outPublicAssetId;
    splitLeaf.outPublicAssetAmount <== outPublicAssetAmount;
    // output.private
    splitLeaf.outPrivateAssetId <== outPrivateAssetId;
    splitLeaf.outPrivateAssetAmount <== outPrivateAssetAmount;
    splitLeaf.outPrivateDepositNullifier <== outPrivateDepositNullifier;
    splitLeaf.outPrivateDepositSecret <== outPrivateDepositSecret;

    // 
    // 3. Outputs.
    // 
    inNullifierHash <== withdraw.nullifierHash;
    outPrivateCommitment <== splitLeaf.outPrivateCommitment;


    // Assert the unused inputs, to protect against proof malleability attacks.
    signal feeSquare;
    signal relayerSquare;
    signal refundSquare;
    feeSquare <== fee * fee;
    relayerSquare <== relayer * relayer;
    refundSquare <== refund * refund;
}