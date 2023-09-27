pragma solidity >=0.7.0 <0.9.0;

import {MixinResolver} from "niacin-contracts/mixins/MixinResolver.sol";
import {MixinInitializable} from "niacin-contracts/mixins/MixinInitializable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MerkleTreeAccumulator, IHasher} from "./lib/MerkleTreeAccumulator.sol";
import {DepositVerifier} from "./verifiers/DepositVerifier.sol";
import {WithdrawVerifier} from "./verifiers/WithdrawVerifier.sol";
import {SwapVerifier} from "./verifiers/SwapVerifier.sol";
import {IUniswap} from "./interfaces/IUniswap.sol";
import {Swapper} from "./Swapper.sol";

contract Tempest is
    MixinResolver,
    MixinInitializable,
    MerkleTreeAccumulator,
    Swapper
{
    // Settings.
    // ================================
    uint256 public feeRate = 1000 * 3; // 0.3%

    // Accumulator and nullifier state.
    // ====================================
    mapping(bytes32 => bool) public nullifierHashes;
    uint256 public numCommitments = 0;
    mapping(uint256 => uint256) public commitments;


    // Events.
    // =============
    event Deposit(address indexed token, uint256 indexed amount, bytes32 indexed spendKeyCommitment, bytes32 commitment);
    event Withdraw();
    event Commitment(uint256 totalCommitments, bytes32 commitment);
    

    function initialize() 
        public 
        initializer 
    {
        // $TEMPEST_TREE_LEVELS_GLOBAL
        initialize_MerkleTreeAccumulator(21, IHasher(requireAddress("MiMC")));
    }

    function getDependencies() public override pure returns (bytes32[] memory addresses) {
        bytes32[] memory deps = new bytes32[](4);
        deps[0] = bytes32("DepositVerifier");
        deps[1] = bytes32("WithdrawVerifier");
        deps[2] = bytes32("MiMC");
        deps[3] = bytes32("SwapVerifier");
        return deps;
    }

    function depositVerifier() public view returns (DepositVerifier) {
        return DepositVerifier(requireAddress("DepositVerifier"));
    }

    function withdrawVerifier() public view returns (WithdrawVerifier) {
        return WithdrawVerifier(requireAddress("WithdrawVerifier"));
    }

    function swapVerifier() public view returns (SwapVerifier) {
        return SwapVerifier(requireAddress("SwapVerifier"));
    }

    function feePool() public view returns (address) {
        return requireAddress("DepositVerifier");
    }

    // function merkleTreeAccumulator() public view returns (MerkleTreeAccumulator) {
    //     return MerkleTreeAccumulator(address(this));
    // }

    struct DepositArgs {
        address token;
        uint256 amount;
        bytes32 spendKeyCommitment;
    }

    // Deposit tokens into the pool.
    function deposit(DepositArgs memory args)
        external
        returns (bytes32)
    {
        // (1) Transfer assets.
        require(ERC20(args.token).allowance(msg.sender, address(this)) >= args.amount, "error: allowance");
        ERC20(args.token).transferFrom(msg.sender, address(this), args.amount);

        // (2) Insert commitment into accumulator.
        bytes32 commitment = _computeInsertLeaf(args.token, args.amount, args.spendKeyCommitment);

        emit Deposit(args.token, args.amount, args.spendKeyCommitment, commitment);
        return commitment;
    }

    struct WithdrawArgs {
        // uint256[24] proof;
        uint256[2] _pA;
        uint256[2][2] _pB;
        uint256[2] _pC;
        uint256[8] _pubSignals;

        uint256 nullifierHash;
        address assetId;
        uint256 assetAmount;
        bytes32 root;
        address payable recipient;
        address payable relayer;
        
        /// @notice The relayer reimbursement/fee in ether.
        uint256 relayerFeeETH;
        uint256 refund;
    }

    function withdraw(WithdrawArgs calldata args)
        external
    {
        // 1. Verify withdraw proof.
        // --------------------------
        require(
            // withdrawVerifier().verifyProof(
            //     args.proof,
            //     [uint256(args.nullifierHash), uint256(uint160(args.assetId)), args.assetAmount, uint256(args.root), uint256(pRecipient), uint256(pRelayer), args.relayerFeeETH, args.refund]
            // ),
            withdrawVerifier().verifyProof(
                args._pA, args._pB, args._pC, 
                args._pubSignals
            ),
            "tempest: proof verify failed"
        );
        _useLeaf(args.root, bytes32(args.nullifierHash));
        
        // 2. Process withdraw.
        // --------------------

        // The relayer is paid in ETH.
        // To get ETH, we swap the token being withdrawn into ETH using UniV3.
        uint256 amountSubFee = args.assetAmount;
        if (0 < args.relayerFeeETH) {
            uint256 qq = _quoteETH(args.assetId, args.relayerFeeETH);
            require(qq <= args.assetAmount, "assets not enough for fee");
            _swapForETH(args.assetId, qq, args.relayerFeeETH, address(args.relayer));
            amountSubFee -= qq;
        }
        ERC20(args.assetId).transfer(args.recipient, amountSubFee);

        emit Withdraw();
    }

    // Withdraw a portion of pooled tokens, swap them, and re-deposit.
    struct SwapArgs {
        uint256[24] _proof;
        bytes32 _nullifierHash;
        address token;
        uint256 amount;
        bytes32 _root;
        address payable _recipient;
        address payable _relayer;
        uint256 _relayerFeeETH;
        uint256 _refund;

        address tokenA;
        uint amountA;
        address tokenB;
        uint amountB;
        bytes32 commitment;
    }

    function swap(
        SwapArgs memory args
    )
        external 
    {
        // 1. Verify swap proof.
        // --------------------------

        // (1) Prove withdrawal of a partial amount from the balances tree.
        
        // (2) Levy fee.
        uint256 feeAmount = args.amountA / 1000 * 3;
        ERC20(args.tokenA).transfer(feePool(), feeAmount);
        args.amountA -= feeAmount;

        // (3) Perform swap with these assets.
        IUniswap(requireAddress("MockUniswap")).swap(
            args.tokenA,
            args.amountA,
            args.tokenB,
            args.amountB
        );

        // (4) Redeposit the private and public leaves into tree.
        // 4a. public leaf.
        _computeInsertLeaf(args.tokenB, args.amountB, bytes32(args.commitment));
        // 4b. private leaf.
        bytes32 privateLeaf;
        _insertLeaf(privateLeaf);
    }

    // Transfer/withdraw your tokens.
    function transfer()
        external
    {
        // Verify proof.
        // Nullify note.
        // Transfer tokens.
        // Insert new note.
    }

    // =====================================
    // INTERNAL FUNCTIONS.
    // =====================================

    // 
    // Accounting logic.
    // 


    // 
    // Accumulator logic.
    // 

    function computeCommitment(
        address token,
        uint256 amount,
        bytes32 spendKeyCommitment
    ) public view returns (bytes32) {
        IHasher mimc = IHasher(requireAddress("MiMC"));
        // spend_key: nullifier ++ secret
        // C = H(H(token ++ amount), pedersen(nullifier ++ secret))
        // a. c1 = H(token ++ amount)
        bytes32 commitment1 = MerkleTreeAccumulator.hashLeftRight(mimc, bytes32(uint256(uint160(token))), bytes32(amount));
        // b. c2 = H(c1, spend_key_commitment)
        bytes32 commitment2 = MerkleTreeAccumulator.hashLeftRight(mimc, commitment1, spendKeyCommitment);
        return commitment2;
    }

    function _computeInsertLeaf(
        address token,
        uint256 amount,
        bytes32 spendKeyCommitment
    ) internal returns (bytes32) {
        bytes32 leaf = computeCommitment(token, amount, spendKeyCommitment);
        _insertLeaf(leaf);
        return leaf;
    }

    function _insertLeaf(
        bytes32 leaf
    ) internal returns (bytes32) {
        _insert(leaf);
        numCommitments++;
        commitments[numCommitments] = uint256(leaf);
        emit Commitment(numCommitments, leaf);
        return leaf;
    }

    // Verifies a leaf is unspent from the balances tree, and spends it.
    function _useLeaf(
        bytes32 _root,
        bytes32 _nullifierHash
    ) internal {
        // 1. Check membership of leaf inside accumulator.
        require(isKnownRoot(_root), "tempest: Cannot find your merkle root");
        // 2. Check leaf is not already "spent" aka revealed in ZK aka nullified.
        require(!nullifierHashes[_nullifierHash], "tempest: The note has been already spent");
        // 3. Nullify it.
        nullifierHashes[_nullifierHash] = true;
    }
}