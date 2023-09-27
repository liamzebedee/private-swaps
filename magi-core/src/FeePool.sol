pragma solidity >=0.7.0 <0.9.0;

import {MixinResolver} from "niacin-contracts/mixins/MixinResolver.sol";
import {MixinInitializable} from "niacin-contracts/mixins/MixinInitializable.sol";
import {ERC20} from "./mocks/ERC20.sol";

contract FeePool is
    MixinResolver
{
    // This can be set by redeploying the contract.
    address feeAddress = address(0);

    function withdraw(
        address[] calldata tokens
    ) external {
        for(uint i = 0; i < tokens.length; i++) {
            ERC20(tokens[i]).transfer(feeAddress, ERC20(tokens[i]).balanceOf(address(this)));
        }
    }
}