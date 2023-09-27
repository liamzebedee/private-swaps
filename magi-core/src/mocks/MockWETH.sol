
pragma solidity >=0.7.0 <0.9.0;

import {MixinResolver} from "niacin-contracts/mixins/MixinResolver.sol";
import {MixinInitializable} from "niacin-contracts/mixins/MixinInitializable.sol";
import {ERC20} from "./ERC20.sol";

contract MockWETH is 
    MixinResolver,
    MixinInitializable,
    ERC20
{
    constructor()  {}

    function initialize()
        public
        initializer
    {
        ERC20_initialize("MockETH", "ETH", 18);
        _mint(msg.sender, 1000*1e18);
    }
}