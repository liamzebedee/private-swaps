pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "./harness/TestSwapper.sol";
import "../mocks/MockDAI.sol";
import "../mocks/ERC20.sol";
import "forge-std/console2.sol";

/// @title Interface for WETH9
abstract contract IWETH9 is ERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external virtual payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external virtual ;
}


contract SwapperContractTest is 
    Test,
    TestSwapper
{
    string RPC_ETH_MAINNET = vm.envString("RPC_ETH_MAINNET");
    
    // Tokens: WETH.
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(RPC_ETH_MAINNET);
        vm.selectFork(mainnetFork);

        // Set our DAI balance.
        deal(address(DAI), address(this), 5000 ether);
    }

    // Show:
    // - getting the price of 1 WETH in DAI
    // - calculating the price with a slippage parameter
    function test_quoteSlippage() public {
        // $1843
        uint256 wethPriceDAI = _quoteETH(DAI, 1 ether);
        console.log("WETH price", wethPriceDAI);
        // $1843 + 1%
        uint256 wethPriceDAISlippage = _calculateAmountInWithSlippage(_quoteETH(DAI, 1 ether));
        console.log("WETH price (+1%)", wethPriceDAISlippage);
    }

    
    // function test_swap() public {
    //     // In this test, we are testing the swapping functionality which is used to
    //     // reimburse the relayer.
    //     // A user may withdraw their tokens, and the tx fee would be 0.01 eth. 
    //     // The relayer pays this transaction fee, and is expected to be reimbursed.
    //     uint256 tokenAmountIn = 5000 ether;
    //     uint256 ethAmountOut = 0.01 ether;
        
    //     uint256 tokenAmountInMax = _calculateAmountInWithSlippage(_quoteETH(DAI, tokenAmountIn));
    //     uint256 amountInSpent = _swapTokensForETH(DAI, tokenAmountInMax, ethAmountOut);
    //     uint256 rem = tokenAmountIn - amountInSpent;
        
    //     console.log("begin with DAI", tokenAmountIn);
    //     console.log("relayer fee %", tokenAmountIn * 1e18 / tokenAmountIn);
    //     console.log("remainder %", rem * 1e18 / tokenAmountIn);
    // }

    function test_swapPayRelayer() public {
        // In this test, we are testing the swapping functionality which is used to
        // reimburse the relayer.
        // A user may withdraw their tokens, and the tx fee would be 0.01 eth. 
        // The relayer pays this transaction fee, and is expected to be reimbursed.
        uint256 depositAmount = 20000 ether; // $200 DAI
        uint256 relayerFee = 0.0025 ether;
        address token = DAI;

        // Set our DAI balance.
        deal(token, address(this), depositAmount);
        
        // Get quote.
        uint256 qq = _quoteETH(token, relayerFee);
        console.log("quote", qq);
        require(qq <= depositAmount, "assets not enough for fee");
        
        // Set allowance.
        ERC20(token).approve(address(v3Router), qq);
        
        // Swap.
        _swapForETH(token, qq, relayerFee, address(this));
    }
}