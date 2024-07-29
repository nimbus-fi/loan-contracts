// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CommunityUnion is ReentrancyGuard {
    IERC20 public token;
    mapping(address => uint256) public memberBalances;
    mapping(address => bool) public isMember;
    
    uint256 public totalMembers;
    uint256 public totalDeposits;
    
    event MemberJoined(address member);
    event Deposited(address member, uint256 amount);
    event Withdrawn(address member, uint256 amount);
    
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }
    
    function joinUnion() external {
        require(!isMember[msg.sender], "Already a member");
        isMember[msg.sender] = true;
        totalMembers++;
        emit MemberJoined(msg.sender);
    }
    
    function deposit(uint256 amount) external nonReentrant {
        require(isMember[msg.sender], "Not a member");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        memberBalances[msg.sender] += amount;
        totalDeposits += amount;
        emit Deposited(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external nonReentrant {
        require(isMember[msg.sender], "Not a member");
        require(memberBalances[msg.sender] >= amount, "Insufficient balance");
        memberBalances[msg.sender] -= amount;
        totalDeposits -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    function getMemberBalance(address member) external view returns (uint256) {
        return memberBalances[member];
    }
}