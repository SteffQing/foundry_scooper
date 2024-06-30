// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Import necessary contracts from Uniswap
import "./Interfaces/IUniswapV2Pair.sol";
import "./Lib/UniswapV2Library.sol";
import "./Lib/TransferHelper.sol";
import "solady/ReentrancyGuard.sol";
import "forge-std/console.sol";

contract AssetScooper is ReentrancyGuard {
    address private immutable i_owner;

    string private constant i_version = "1.0.0";

    bytes4 private constant interfaceId = 0x36372b07;

    address private constant weth = 0x4200000000000000000000000000000000000006;

    address private constant factory =
        0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;

    event TokenSwapped(
        address indexed user,
        address indexed tokenA,
        uint256 amountIn,
        uint amountOut
    );

    error AssetScooper__AddressZero();
    error AssetScooper__MisMatchToken();
    error AssetScooper__ZeroLengthArray();
    error AssetScooper__UnsupportedToken();
    error AssetScooper__InsufficientOutputAmount();
    error AssetScooper__InsufficientLiquidity();
    error AssetScooper__UnsuccessfulBalanceCall();
    error AssetScooper__UnsuccessfulDecimalCall();
    error AssetScooper_PairDoesNotExist();
    error AssetScooper__InsufficientBalance();
    error AssetScooper__MisMatchLength();
    error AssetScooper__UnsuccessfulSwapTx();

    constructor() {
        i_owner = msg.sender;
    }

    function owner() public view returns (address) {
        return i_owner;
    }

    function version() public pure returns (string memory) {
        return i_version;
    }

    function _checkIfPairExists(
        address _factory,
        address tokenAddress
    ) public pure returns (bool) {
        address pairAddress = UniswapV2Library.pairFor(
            _factory,
            tokenAddress,
            weth
        );
        return pairAddress != address(0);
    }

    function _getAmountIn(
        address token,
        uint256 tokenBalance
    ) internal view returns (uint256 amountIn) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        if (!success) revert AssetScooper__UnsuccessfulDecimalCall();
        uint256 tokenDecimals = abi.decode(data, (uint256));
        amountIn = (tokenBalance * (10 ** (18 - tokenDecimals))) / 1;
    }

    function _getTokenBalance(
        address token,
        address _owner
    ) internal view returns (uint256 tokenBalance) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("balanceOf(address)", _owner)
        );
        if (!success) revert AssetScooper__UnsuccessfulBalanceCall();
        tokenBalance = abi.decode(data, (uint256));
    }

    function sweepTokens(
        address[] calldata tokenAddress,
        uint256[] calldata minAmountOut
    ) public nonReentrant {
        if (tokenAddress.length == 0) revert AssetScooper__ZeroLengthArray();
        if (tokenAddress.length != minAmountOut.length)
            revert AssetScooper__MisMatchLength();

        uint256 totalEth;

        for (uint256 i = 0; i < tokenAddress.length; i++) {
            address pairAddress = UniswapV2Library.pairFor(
                factory,
                tokenAddress[i],
                weth
            );
            totalEth += _swap(pairAddress, minAmountOut[i]);
        }
        console.log("totalEth", totalEth);
        console.log("balanceEth", address(this).balance);

        TransferHelper.safeTransferETH(msg.sender, totalEth);

        console.log("Done");
    }

    function _swap(
        address pairAddress,
        uint256 minimumOutputAmount
    ) private returns (uint256 amountOut) {
        address addr = pairAddress;
        IUniswapV2Pair pair = IUniswapV2Pair(addr);

        address tokenA = pair.token0();
        address tokenB = pair.token1();
        address tokenIn = tokenA == weth ? tokenB : tokenA;

        uint256 tokenBalance = _getTokenBalance(tokenIn, msg.sender);
        if (tokenBalance < 0) revert AssetScooper__InsufficientBalance();

        uint256 amountIn = _getAmountIn(tokenIn, tokenBalance);
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(
            pair.factory(),
            tokenA,
            tokenB
        );

        amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reserveA,
            reserveB
        );
        if (amountOut < minimumOutputAmount)
            revert AssetScooper__InsufficientOutputAmount();

        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            addr,
            amountIn
        );
        uint amount0Out = tokenA == weth ? amountOut : 0;
        uint amount1Out = tokenA == weth ? 0 : amountOut;
        console.log("Swap amount", amountIn, amountOut);
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

        emit TokenSwapped(msg.sender, tokenA, amountIn, amountOut);
    }
}
