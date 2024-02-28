// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";

contract SwapHelperV3 is Ownable {
    using SafeERC20 for IERC20;

    address public immutable _weth;
    ISwapRouter public immutable _swapRouter;

    error SwapRouterIsZero();
    error SwapHelperPairTokensNotEqWeth(address token0, address token1);

    event AcceptedDeviationPrice(uint256 deviation);
    event Swapped(address indexed pool, uint256 amountIn, uint256 amountOut);

    constructor(address swapRouter_) Ownable(msg.sender) {
        if (swapRouter_ == address(0)) revert SwapRouterIsZero();
        _swapRouter = ISwapRouter(swapRouter_);
        _weth = _swapRouter.WETH9();
    }

    function swap(bytes memory data) external returns(uint256 amountOut) {
        address weth_ = _weth;
        (address poolAddress, uint256 amountIn, uint256 minAmountOut) = abi.decode(data, (address, uint256, uint256));
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        if (token0 != weth_ && token1 != weth_) revert SwapHelperPairTokensNotEqWeth(token0, token1);
        IERC20(weth_).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(weth_).forceApprove(address(_swapRouter), amountIn);
        amountOut = _swapRouter.exactInput(
            ISwapRouter.ExactInputParams(
                abi.encodePacked(weth_, pool.fee(), token0 == weth_ ? token1 : token0),
                msg.sender,
                block.timestamp,
                amountIn,
                minAmountOut
            )
        );
        emit Swapped(poolAddress, amountIn, amountOut);
    }
}
