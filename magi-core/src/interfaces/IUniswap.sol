
pragma solidity >=0.7.0 <0.9.0;

interface IUniswap
{
    function swap(
        address tokenA,
        uint amountA,
        address tokenB,
        uint amountB
    ) external;
}