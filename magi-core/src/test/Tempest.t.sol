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


contract TempestContractTest is 
    Test,
    TestSwapper
{
    string RPC_ETH_MAINNET = vm.envString("RPC_ETH_MAINNET");
    
    // Tokens: WETH.
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(RPC_ETH_MAINNET);
        vm.selectFork(mainnetFork);

        // Set our DAI balance.
        deal(address(DAI), address(this), 5000 ether);
    }

    
}