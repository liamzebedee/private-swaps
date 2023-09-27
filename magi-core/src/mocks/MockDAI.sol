
pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "./ERC20.sol";

contract MockDAI is 
    ERC20
{
    function initialize()
        public
    {
        ERC20_initialize("MockDAI", "DAI", 18);
        _mint(msg.sender, 1000*1e18);
    }
}