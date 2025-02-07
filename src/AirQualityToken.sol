// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AirQualityToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    uint256 public lastAQI;

    uint256 public constant MIN_SUPPLY = 10000 * 10 ** 18;

    event AQIUpdated(uint256 newAQI, uint256 tokenSupply);

    constructor() ERC20("AirQuality Token", "AQT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function updateAQI(uint256 newAQI) public onlyOwner whenNotPaused {
        require(newAQI > 0 && newAQI <= 500, "AQI must be between 0 and 500");
        if (lastAQI == newAQI) {
            return;
        }

        uint256 amount = (newAQI > lastAQI)
            ? (newAQI - lastAQI) * 100 * 10 ** decimals()
            : (lastAQI - newAQI) * 100 * 10 ** decimals();

        if (newAQI > lastAQI) {
            _mint(owner(), amount);
        } else {
            uint256 burnAmount = balanceOf(owner()) >= amount ? amount : balanceOf(owner());
            if (totalSupply() - burnAmount >= MIN_SUPPLY) {
                _burn(owner(), burnAmount);
            }
        }

        lastAQI = newAQI;
        emit AQIUpdated(newAQI, totalSupply());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
