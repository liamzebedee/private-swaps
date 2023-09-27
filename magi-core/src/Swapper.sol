

pragma solidity >=0.7.0 <0.9.0;

import {MixinResolver} from "niacin-contracts/mixins/MixinResolver.sol";
import {MixinInitializable} from "niacin-contracts/mixins/MixinInitializable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract Swapper {
    // Swaps.
    // ============================================

    // Address of WETH
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Uniswap Router address
    ISwapRouter internal constant v3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // Uniswap Quoter address for getting quote
    IQuoter internal constant v3Quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    // Slippage tolerance (1% for example)
    uint256 internal constant slippageTolerance = 100;

    uint24 constant fee = 3000; // 

    function _quoteETH(
        address tokenIn, 
        uint256 ethAmountOut
    ) internal returns (uint256 q) {
        q = v3Quoter.quoteExactOutputSingle(
            tokenIn,
            WETH,
            fee,
            ethAmountOut,
            0
        );
    }

    function _swapForETH(
        address tokenIn, 
        uint256 tokenInAmount, 
        uint256 ethAmountOut,
        address recipient
    ) internal {
        _swap(
            tokenIn,
            tokenInAmount,
            WETH,
            ethAmountOut,
            recipient
        );
    }

    function _swap(
        address tokenIn,
        uint256 tokenInAmount, 
        address tokenOut,
        uint256 amountOut,
        address recipient
    ) internal {
        // Approve tokens for swapRouter contract
        require(tokenInAmount <= ERC20(tokenIn).balanceOf(address(this)), "no balance");
        ERC20(tokenIn).approve(address(v3Router), tokenInAmount);
        // require(tokenInAmount <= ERC20(tokenIn).allowance(address(this), address(v3Router)), "no allowance");

        // Execute the swap
        v3Router.exactOutput(ISwapRouter.ExactOutputParams({
            path: abi.encodePacked(tokenOut, fee, tokenIn),
            recipient: recipient,
            deadline: block.timestamp,
            amountOut: amountOut,
            amountInMaximum: tokenInAmount
        }));
    }

    function _calculateAmountInWithSlippage(
        uint256 tokenAmountIn
    ) internal returns (uint256) {

        // Calculate the maximum amount in to control slippage
        // amountIn * (1 + slippageTolerance / 10000)
        uint256 amountInMaximum = tokenAmountIn * (10000 + slippageTolerance) / 10000;
        return amountInMaximum;
    }
}