pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/pedersen.circom";
include "../../node_modules/circomlib/circuits/mimcsponge.circom";
include "merkleTree.circom";

template Withdraw(levels) {
    
    // =======
    // Inputs.
    // =======

    // Public.
    signal input assetId;      // u256
    signal input assetAmount;  // u256
    signal input root;
    signal input recipient; // not taking part in any computations
    signal input relayer;  // not taking part in any computations
    signal input fee;      // not taking part in any computations
    signal input refund;   // not taking part in any computations

    // Private.
    signal input nullifier;
    signal input secret;
    signal input pathElements[levels];
    signal input pathIndices[levels];

    // ========
    // Outputs.
    // ========
    
    signal output nullifierHash;

    // ==========
    // Function.
    // ==========

    // Reveal the commitment to the leaf.
    // (1) Compute the hash from (assetId, assetAmount, secret, nullifier).
    <%
    let fields = [
        'nullifier: 248',
        'secret: 248'
    ].map(field => {
        const [id, size] = field.split(': ')
        return {id,size: parseInt(size)}
    })
    %>

    <% // component bits_assetId = Num2Bits(256); %>
    <%_ fields.map(({ id, size }) => { -%>
    component bits_<%= id %> = Num2Bits(<%= size %>);
    <%_ }) %>

    <% // bits_assetId.in <== assetId; %>
    <%_ fields.map(({ id, size }) => { -%>
    bits_<%= id %>.in <== <%= id %>;
    <%_ }) %>

    component spendingKeyCommitment = Pedersen(<%= fields.reduce((acc, field) => acc + field.size, 0) %>);

    <%_
    let i = 0;
    for(let field of fields) {
    -%>
    for(var i = 0; i < <%= field.size %>; i++) {
        <%_ // spendingKeyCommitment.in[i] <== bits_assetId.out[i]; -%>
        spendingKeyCommitment.in[<%= i %> + i] <== bits_<%= field.id %>.out[i];
    }
    <%_ 
    i += field.size 
    }
    -%>

    // C = MiMCSponge(MiMCSponge(assetId, assetAmount), Pedersen(nullifier ++ secret))
    component commitment1 = HashLeftRight();
    commitment1.left <== assetId;
    commitment1.right <== assetAmount;
    component commitment2 = HashLeftRight();
    commitment2.left <== commitment1.hash;
    commitment2.right <== spendingKeyCommitment.out[0];
    
    // (2) Prove the merkle path to the `root` to reveal the commitment.
    component tree = MerkleTreeChecker(levels);
    // tree.leaf <== hash.out[0];
    tree.leaf <== commitment2.hash;
    tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndices[i] <== pathIndices[i];
    }

    // (3) Assert nullifier hash.
    component nullifierHash_circuit = Pedersen(248);
    for (var i = 0; i < 248; i++) {
        nullifierHash_circuit.in[i] <== bits_nullifier.out[i];
    }
    nullifierHash <== nullifierHash_circuit.out[0];

    
    // Assert the unused inputs, to protect against proof malleability attacks.
    signal recipientSquare;
    signal feeSquare;
    signal relayerSquare;
    signal refundSquare;
    recipientSquare <== recipient * recipient;
    feeSquare <== fee * fee;
    relayerSquare <== relayer * relayer;
    refundSquare <== refund * refund;
}