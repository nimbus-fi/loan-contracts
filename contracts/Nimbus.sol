// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlatformToken is ERC20, Ownable {
    uint256 public faucetAmount = 10 * 10 ** decimals(); // 10 tokens with 18 decimals
    uint256 public faucetCooldown = 1 days; // Cooldown period of 24 hours
    uint256 public initialSupply = 10000000000 * 10 ** decimals(); // 10 billion tokens with 18 decimals

    mapping(address => uint256) private lastFaucetTime;

    constructor(address initialOwner) ERC20("Nimbus Token", "NIBS") Ownable(initialOwner) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function faucet() external {
        require(
            block.timestamp >= lastFaucetTime[msg.sender] + faucetCooldown,
            "You can only claim tokens once every 24 hours"
        );

        // Update the last claim time
        lastFaucetTime[msg.sender] = block.timestamp;

        // Mint faucet amount to the caller
        _mint(msg.sender, faucetAmount);
    }
}
