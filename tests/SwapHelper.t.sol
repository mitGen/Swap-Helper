// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SwapHelperV3} from "../contracts/SwapHelperV3.sol";
import {ISwapRouter} from "../contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "../contracts/interfaces/IUniswapV3Pool.sol";

contract SwapHelper is Test {
    using SafeERC20 for IERC20;

    uint256 public constant SWAP_AMOUNT = 1e15;
    uint256 public constant FORK_BLOCK_NUMBER = 10606106;

    Account private _swapper = makeAccount("swapper");
    address private _pool = 0x0a394AB66dD9651fD6d036FB222AF9E015A75778;
    address private _router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    SwapHelperV3 private _swapHelper;
    IERC20 private _weth;

    function setUp() public {
        vm.createSelectFork("goerli", FORK_BLOCK_NUMBER);
        _swapHelper = new SwapHelperV3(_router);
        _weth = IERC20(_swapHelper._weth());
        deal(address(_weth), _swapper.addr, SWAP_AMOUNT);
    }

    function test_swap() public {
        vm.startPrank(_swapper.addr);
        IUniswapV3Pool pool_ = IUniswapV3Pool(_pool);
        IERC20 tokenOut = IERC20(pool_.token0() == address(_weth) ? pool_.token1() : pool_.token0());
        _weth.forceApprove(address(_swapHelper), SWAP_AMOUNT);

        console.log("-----------------------------------------------------------------------------");
        console.log("BeforeSwap :: Balance TokenIn Swapper: ", _weth.balanceOf(_swapper.addr));
        console.log("BeforeSwap :: Balance TokenOut Swapper: ", tokenOut.balanceOf(_swapper.addr));
        console.log("-----------------------------------------------------------------------------");

        uint256 amountOut = _swapHelper.swap(abi.encode(_pool, SWAP_AMOUNT, 0));
        uint256 tokenOutBalance = tokenOut.balanceOf(_swapper.addr);
        assertEq(amountOut, tokenOutBalance);

        console.log("-----------------------------------------------------------------------------");
        console.log("AfterSwap :: Balance TokenIn Swapper: ", _weth.balanceOf(_swapper.addr));
        console.log("AfterSwap :: Balance TokenOut Swapper: ", tokenOut.balanceOf(_swapper.addr));
        console.log("-----------------------------------------------------------------------------");

        vm.stopPrank();
    }
}
