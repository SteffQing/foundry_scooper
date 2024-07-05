// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AssetScooper, ApprovalHelper} from "../src/AssetScooper.sol";
import {IERC20} from "../src/Lib/TransferHelper.sol";
import {MOCKERC20} from "../src/MOCK.sol";


// 0x9DE16c805A3227b9b92e39a446F9d56cf59fe640 BENTO
// 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb DAI
// 0x4200000000000000000000000000000000000006 WETH
contract AssetScooperTest is Test {
    AssetScooper public assetScooper;
    MOCKERC20 public dai;
    MOCKERC20 public bento;

    address one = address(1);
    address two = address(2);

    function setUp() public {
        assetScooper = new AssetScooper();
        dai = new MOCKERC20();

        dai.mint(one, 1e18);

        console.log("Address One: ", one);
        console.log("Address Two: ", two);
        console.log("Address This: ", address(this));
        console.log("Address AssetScooper: ", address(assetScooper));
        console.log("Address Dai: ", address(dai));
    }

    function testSweep() public {
        uint hundredDAI = 1 * 1e18;
        vm.startPrank(one);

        console.log("Dai balance of one: ", dai.balanceOf(one));

        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(assetScooper), hundredDAI);

        uint allowance = dai.allowance(one, address(assetScooper));
        console.log(allowance, "Allowance before approval");

        (bool success, ) = address(dai).call(data);
        console.log("Approve call returned: ", success);

        allowance = dai.allowance(one, address(assetScooper));
        console.log(allowance, "Allowance after approval");

        // Test TransferFrom to address(2) from Sweep
        uint balanceTwoBefore = dai.balanceOf(two);
        assertEq(balanceTwoBefore, 0);
        console.log("Balance of two before: ", balanceTwoBefore);

        assetScooper.testTransfer(address(dai), two, hundredDAI);

        uint balanceTwoAfter = dai.balanceOf(two);
        assertEq(balanceTwoAfter, hundredDAI);
        console.log("Balance of two after: ", balanceTwoAfter);
        uint balanceOneAfter = dai.balanceOf(one);
        assertEq(balanceOneAfter, 0);
        console.log("Balance of one after: ", balanceOneAfter);

        // address[] memory tokens = new address[](2);
        // tokens[0] = address(dai);
        // tokens[1] = address(bento);

        // uint[] memory amounts = new uint[](2);
        // amounts[0] = 0;
        // amounts[1] = 0;

        // assetScooper.sweepTokens(tokens, amounts);
    }
}
