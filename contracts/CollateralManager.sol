// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CollateralManager is Ownable {
    IERC20 public collateralToken;
    mapping(address => uint256) public lockedCollateral;
    
    event CollateralLocked(address user, uint256 amount);
    event CollateralReleased(address user, uint256 amount);
    
    constructor(address _collateralTokenAddress, address initialOnwer) Ownable(initialOnwer) {
        collateralToken = IERC20(_collateralTokenAddress);
    }
    
    function lockCollateral(address user, uint256 amount) external onlyOwner returns (bool) {
        require(collateralToken.transferFrom(user, address(this), amount), "Collateral transfer failed");
        lockedCollateral[user] += amount;
        emit CollateralLocked(user, amount);
        return true;
    }
    
    function releaseCollateral(address user, uint256 amount) external onlyOwner {
        require(lockedCollateral[user] >= amount, "Insufficient locked collateral");
        lockedCollateral[user] -= amount;
        require(collateralToken.transfer(user, amount), "Collateral release failed");
        emit CollateralReleased(user, amount);
    }
    
    function getLockedCollateral(address user) external view returns (uint256) {
        return lockedCollateral[user];
    }
}