
pragma solidity >=0.7.0 <0.9.0;

import {MixinResolver} from "niacin-contracts/mixins/MixinResolver.sol";
import {MixinInitializable} from "niacin-contracts/mixins/MixinInitializable.sol";
import {ERC20} from "./ERC20.sol";

contract MockUniswap is 
    MixinResolver,
    MixinInitializable
{
    constructor() {}

    function initialize()
        public
        initializer
    {
    }

    function swap(
        address tokenA,
        uint amountA,
        address tokenB,
        uint amountB
    ) external {
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transfer(msg.sender, amountB);
    }
}