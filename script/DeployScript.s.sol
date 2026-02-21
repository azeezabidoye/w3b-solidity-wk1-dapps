// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {Script} from "forge-std/Script.sol";
import {Todo} from "../src/Todo.sol";
import {ERC20} from "../src/ERC20.sol";
import {SaveEther} from "../src/SaveEther.sol";
import {SaveAsset} from "../src/SaveAsset.sol";
import {SchoolManagement} from "../src/SchMgmt.sol";

contract DeployScript is Script {
    Todo public todo;
    ERC20 public erc20;
    SaveEther public saveEther;
    SaveAsset public saveAsset;
    SchoolManagement public schoolManagement;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        todo = new Todo();
        erc20 = new ERC20();
        saveEther = new SaveEther();
        saveAsset = new SaveAsset(address(erc20));
        schoolManagement = new SchoolManagement(address(erc20));

        vm.stopBroadcast();
    }
}
