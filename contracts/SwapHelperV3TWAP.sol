// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {FullMath} from "./libraries/FullMath.sol";
import {OracleLibraryPlus} from "./libraries/OracleLibraryPlus.sol";
import {TickMath} from "./libraries/TickMath.sol";

contract SwapHelperV3TWAP is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e18;
    uint32 public constant TWAP_LENGTH = 30 minutes;
    uint32 public constant OFFSET = 30;

    address public immutable _weth;
    ISwapRouter public immutable _swapRouter;

    uint256 public acceptedDeviationPrice;

    error SwapRouterIsZero();
    error SwapHelperPairTokensNotEqWeth(address token0, address token1);
    error DeviationRateLimitLtLiveDeviation(uint256 deviationLimit, uint256 liveDeviation);
    error SetAcceptedDeviationPrice(uint256 deviation);

    event AcceptedDeviationPrice(uint256 deviation);
    event Swapped(address indexed pool, uint256 amountIn, uint256 amountOut);

    constructor(address swapRouter_, uint256 acceptedDeviationPrice_) Ownable(msg.sender) {
        if (swapRouter_ == address(0)) revert SwapRouterIsZero();
        _swapRouter = ISwapRouter(swapRouter_);
        _weth = _swapRouter.WETH9();
        _setAcceptedDeviationPrice(acceptedDeviationPrice_);
    }

    function setAcceptedDeviationPrice(uint256 deviation) external onlyOwner {
        _setAcceptedDeviationPrice(deviation);
    }

    function swap(bytes memory data) external returns (uint256 amountOut) {
        address weth_ = _weth;
        (address poolAddress, uint256 amountIn) = abi.decode(data, (address, uint256));
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        if (token0 != weth_ && token1 != weth_) revert SwapHelperPairTokensNotEqWeth(token0, token1);
        (bool valid, uint256 livePriceToken0ToToken1, uint256 meanPriceToken0ToToken1) = _validatePrice(poolAddress);
        if (!valid) revert DeviationRateLimitLtLiveDeviation(livePriceToken0ToToken1, meanPriceToken0ToToken1);
        IERC20(weth_).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(weth_).forceApprove(address(_swapRouter), amountIn);
        amountOut = _swapRouter.exactInput(
            ISwapRouter.ExactInputParams(
                abi.encodePacked(weth_, pool.fee(), token0 == weth_ ? token1 : token0),
                msg.sender,
                block.timestamp,
                amountIn,
                0
            )
        );
        emit Swapped(poolAddress, amountIn, amountOut);
    }

    function _validatePrice(
        address pool
    ) private view returns (bool valid, uint256 livePriceToken0ToToken1, uint256 meanPriceToken0ToToken1) {
        (uint256 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        livePriceToken0ToToken1 = FullMath.mulDiv(PRECISION, sqrtPriceX96 ** 2, 1 << 192);
        int24 arithmeticMeanTick = OracleLibraryPlus.consultOffsetted(pool, TWAP_LENGTH, OFFSET);
        meanPriceToken0ToToken1 = FullMath.mulDiv(
            PRECISION,
            uint256(TickMath.getSqrtRatioAtTick(arithmeticMeanTick)) ** 2,
            1 << 192
        );
        uint256 differenceLiveToMean = livePriceToken0ToToken1 > meanPriceToken0ToToken1
            ? livePriceToken0ToToken1 - meanPriceToken0ToToken1
            : meanPriceToken0ToToken1 - livePriceToken0ToToken1;
        if (differenceLiveToMean <= (meanPriceToken0ToToken1 * acceptedDeviationPrice) / PRECISION) valid = true;
    }

    function _setAcceptedDeviationPrice(uint256 deviation) private {
        if (deviation > PRECISION) revert SetAcceptedDeviationPrice(deviation);
        acceptedDeviationPrice = deviation;
        emit AcceptedDeviationPrice(deviation);
    }
}
