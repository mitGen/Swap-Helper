// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "../interfaces/IUniswapV3Pool.sol";

library OracleLibraryPlus {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param _pool Address of the pool that we want to observe
    /// @param _twapLength Length in seconds of the TWAP calculation length
    /// @param _offset Number of seconds ago to start the TWAP calculation
    /// @return _arithmeticMeanTick The arithmetic mean tick from _secondsAgos[0] to _secondsAgos[1]
    function consultOffsetted(
        address _pool,
        uint32 _twapLength,
        uint32 _offset
    ) internal view returns (int24 _arithmeticMeanTick) {
        uint32[] memory _secondsAgos = new uint32[](2);
        _secondsAgos[0] = _twapLength + _offset;
        _secondsAgos[1] = _offset;
        (int56[] memory _tickCumulatives, ) = IUniswapV3Pool(_pool).observe(_secondsAgos);
        int56 _tickCumulativesDelta = _tickCumulatives[1] - _tickCumulatives[0];
        int56 twapLengthInt = int56(int32(_twapLength));
        _arithmeticMeanTick = int24(_tickCumulativesDelta / twapLengthInt);
        if (_tickCumulativesDelta < 0 && (_tickCumulativesDelta % twapLengthInt != 0)) _arithmeticMeanTick--;
    }
}
