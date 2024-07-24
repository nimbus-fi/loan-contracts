// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CommunityUnion.sol";
import "./CollateralManager.sol";

contract LendingPool is ReentrancyGuard {
    IERC20 public token;
    CommunityUnion public communityUnion;
    CollateralManager public collateralManager;
    
    struct Loan {
        uint256 amount;
        uint256 collateralAmount;
        uint256 interestRate;
        uint256 startTime;
        uint256 duration;
        bool repaid;
    }
    
    mapping(address => Loan) public loans;
    
    uint256 public constant INTEREST_RATE = 5; // 5% annual interest
    uint256 public constant LOAN_DURATION = 30 days;
    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateralization
    
    event LoanTaken(address borrower, uint256 amount, uint256 collateralAmount);
    event LoanRepaid(address borrower, uint256 amount);
    
    constructor(address _tokenAddress, address _communityUnionAddress, address _collateralManagerAddress) {
        token = IERC20(_tokenAddress);
        communityUnion = CommunityUnion(_communityUnionAddress);
        collateralManager = CollateralManager(_collateralManagerAddress);
    }
    
    function takeLoan(uint256 amount) external nonReentrant {
        require(communityUnion.isMember(msg.sender), "Not a member");
        require(loans[msg.sender].amount == 0, "Existing loan not repaid");
        require(amount <= communityUnion.totalDeposits() / 2, "Loan amount too high");
        
        uint256 collateralRequired = (amount * COLLATERAL_RATIO) / 100;
        require(collateralManager.lockCollateral(msg.sender, collateralRequired), "Collateral lock failed");
        
        loans[msg.sender] = Loan({
            amount: amount,
            collateralAmount: collateralRequired,
            interestRate: INTEREST_RATE,
            startTime: block.timestamp,
            duration: LOAN_DURATION,
            repaid: false
        });
        
        require(token.transfer(msg.sender, amount), "Loan transfer failed");
        emit LoanTaken(msg.sender, amount, collateralRequired);
    }
    
    function repayLoan() external nonReentrant {
        Loan storage loan = loans[msg.sender];
        require(loan.amount > 0, "No active loan");
        require(!loan.repaid, "Loan already repaid");
        
        uint256 interestAmount = calculateInterest(loan.amount, loan.interestRate, loan.duration);
        uint256 totalRepayment = loan.amount + interestAmount;
        
        require(token.transferFrom(msg.sender, address(this), totalRepayment), "Repayment transfer failed");
        
        loan.repaid = true;
        collateralManager.releaseCollateral(msg.sender, loan.collateralAmount);
        
        emit LoanRepaid(msg.sender, totalRepayment);
    }
    
    function calculateInterest(uint256 principal, uint256 rate, uint256 time) internal pure returns (uint256) {
        return (principal * rate * time) / (365 days * 100);
    }
}