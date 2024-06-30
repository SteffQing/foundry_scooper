// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AssetScooper} from "../src/AssetScooper.sol";
import {IWETH} from "../src/Interfaces/IWETH.sol";
import {IERC20} from "../src/Lib/TransferHelper.sol";


// 0x9DE16c805A3227b9b92e39a446F9d56cf59fe640 BENTO
// 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb DAI
// 0x4200000000000000000000000000000000000006 WETH
contract AssetScooperTest is Test {
    AssetScooper public assetScooper;
    IERC20 public dai;
    IERC20 public bento;
    IWETH public weth;

    function setUp() public {
        assetScooper = new AssetScooper();
        dai = IERC20(0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb);
        bento = IERC20(0x9DE16c805A3227b9b92e39a446F9d56cf59fe640);
        weth = IWETH(0x4200000000000000000000000000000000000006);
    }

    function testSweep() public {
        uint hundredDAI = 1 * 1e18;

        deal(address(dai), address(1), hundredDAI, true);
        deal(address(bento), address(1), hundredDAI, false);
        vm.startPrank(address(1));
        dai.approve(address(assetScooper), hundredDAI);
        bento.approve(address(assetScooper), hundredDAI);
        
        address[] memory tokens = new address[](2);
        tokens[0] = address(dai);
        tokens[1] = address(bento);

        assertEq(dai.balanceOf(address(1)), hundredDAI);
        assetScooper.sweepTokens(tokens);
    }
}
