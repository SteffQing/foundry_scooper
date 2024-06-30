// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AssetScooper} from "../src/AssetScooper.sol";

contract AssetScooperTest is Test {
    AssetScooper public assetScooper;

    function setUp() public {
        assetScooper = new AssetScooper();
    }


    // function testFuzz_SetNumber(uint256 x) public {
    //     assetScooper.setNumber(x);
    //     assertEq(assetScooper.number(), x);
    // }
}
