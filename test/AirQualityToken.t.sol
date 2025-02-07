// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {AirQualityToken} from "../src/AirQualityToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";


contract AirQualityTokenTest is Test {
    AirQualityToken public token;
    address public owner;
    address public testUser;


    function setUp() public {
        // Set up the contract and initial conditions
        owner = address(this);
        testUser = address(0x1234);
        token = new AirQualityToken();
    }

    // Test successful AQI update with increasing AQI
    function testSuccessfulAQIIncreaseUpdate() public {
        uint256 initialSupply = token.totalSupply();
        uint256 initialAQI = 0;
        uint256 newAQI = 50;

        // Update AQI
        token.updateAQI(newAQI);

        // Check that tokens were minted
        uint256 expectedMintAmount = (newAQI - initialAQI) * 100 * 10 ** token.decimals();
        assertEq(token.totalSupply(), initialSupply + expectedMintAmount);
        assertEq(token.lastAQI(), newAQI);
    }

    // Test successful AQI update with decreasing AQI
    function testSuccessfulAQIDecreaseUpdate() public {
        // First increase AQI to have tokens to burn
        token.updateAQI(100);
        uint256 initialSupply = token.totalSupply();
        
        // Then decrease AQI
        uint256 newAQI = 50;
        token.updateAQI(newAQI);

        // Check that tokens were burned
        uint256 expectedBurnAmount = (100 - newAQI) * 100 * 10 ** token.decimals();
        assertEq(token.totalSupply(), initialSupply - expectedBurnAmount);
        assertEq(token.lastAQI(), newAQI);
    }

    // Test AQI update fails when paused
    function testAQIUpdateFailsWhenPaused() public {
        token.pause();

        // vm.expectRevert("Pausable: paused");
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        token.updateAQI(50);
    }

    // Test AQI update fails for non-owner
    function testAQIUpdateFailsForNonOwner() public {
        vm.prank(testUser);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, testUser));
        token.updateAQI(50);
    }

    // Test AQI update fails for invalid AQI values
    function testAQIUpdateFailsForInvalidAQI() public {
        // Test AQI too low
        vm.expectRevert("AQI must be between 0 and 500");
        token.updateAQI(0);

        // Test AQI too high
        vm.expectRevert("AQI must be between 0 and 500");
        token.updateAQI(501);
    }

    // Test burn does not reduce supply below MIN_SUPPLY
    function testBurnDoesNotReduceBelowMinSupply() public {
        // First, increase AQI to mint tokens
        token.updateAQI(100);
        
        // Calculate burn amount that would reduce supply below MIN_SUPPLY
        uint256 minSupply = token.MIN_SUPPLY();
        uint256 currentSupply = token.totalSupply();
        
        // Attempt to reduce AQI significantly
        token.updateAQI(1);

        // Verify supply does not go below MIN_SUPPLY
        assertGe(token.totalSupply(), minSupply);
    }

    // Test pause and unpause functionality
    function testPauseAndUnpause() public {
        // Pause the contract
        token.pause();
        assertTrue(token.paused());

        // Unpause the contract
        token.unpause();
        assertFalse(token.paused());
    }

    // Test pause fails for non-owner
    function testPauseFailsForNonOwner() public {
        vm.prank(testUser);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, testUser));
        token.pause();
    }
}