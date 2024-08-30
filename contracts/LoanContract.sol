// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LendingBorrowingProtocol is ReentrancyGuard {
    using SafeMath for uint256;

    struct Asset {
        IERC20 token;
        uint256 totalDeposited;
        uint256 totalBorrowed;
        uint256 interestRate;
        uint256 collateralFactor;
    }

    mapping(address => Asset) public assets;
    mapping(address => mapping(address => uint256)) public userDeposits;
    mapping(address => mapping(address => uint256)) public userBorrows;

    address public nativeToken;
    address public nibs;
    address public usdc;

    uint256 private constant PRECISION = 1e18;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event Borrow(address indexed user, address indexed token, uint256 amount);
    event Repay(address indexed user, address indexed token, uint256 amount);

    constructor(address _nativeToken, address _nibs, address _usdc) {
        nativeToken = _nativeToken;
        nibs = _nibs;
        usdc = _usdc;

        // Initialize assets
        assets[_nativeToken] = Asset(IERC20(_nativeToken), 0, 0, 5e16, 75e16); // 5% interest rate, 75% collateral factor
        assets[_nibs] = Asset(IERC20(_nibs), 0, 0, 3e16, 80e16); // 3% interest rate, 80% collateral factor
        assets[_usdc] = Asset(IERC20(_usdc), 0, 0, 2e16, 90e16); // 2% interest rate, 90% collateral factor
    }

    function deposit(address token, uint256 amount) external nonReentrant {
        require(assets[token].token != IERC20(address(0)), "Unsupported token");
        require(amount > 0, "Amount must be greater than 0");

        Asset storage asset = assets[token];
        asset.token.transferFrom(msg.sender, address(this), amount);
        asset.totalDeposited = asset.totalDeposited.add(amount);
        userDeposits[msg.sender][token] = userDeposits[msg.sender][token].add(amount);

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external nonReentrant {
        require(assets[token].token != IERC20(address(0)), "Unsupported token");
        require(amount > 0, "Amount must be greater than 0");
        require(userDeposits[msg.sender][token] >= amount, "Insufficient balance");

        Asset storage asset = assets[token];
        asset.totalDeposited = asset.totalDeposited.sub(amount);
        userDeposits[msg.sender][token] = userDeposits[msg.sender][token].sub(amount);
        asset.token.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, token, amount);
    }

    function borrow(address token, uint256 amount) external nonReentrant {
        require(assets[token].token != IERC20(address(0)), "Unsupported token");
        require(amount > 0, "Amount must be greater than 0");
        require(getAvailableBorrowLimit(msg.sender, token) >= amount, "Insufficient collateral");

        Asset storage asset = assets[token];
        asset.totalBorrowed = asset.totalBorrowed.add(amount);
        userBorrows[msg.sender][token] = userBorrows[msg.sender][token].add(amount);
        asset.token.transfer(msg.sender, amount);

        emit Borrow(msg.sender, token, amount);
    }

    function repay(address token, uint256 amount) external nonReentrant {
        require(assets[token].token != IERC20(address(0)), "Unsupported token");
        require(amount > 0, "Amount must be greater than 0");

        Asset storage asset = assets[token];
        uint256 debt = userBorrows[msg.sender][token];
        uint256 repayAmount = amount > debt ? debt : amount;

        asset.token.transferFrom(msg.sender, address(this), repayAmount);
        asset.totalBorrowed = asset.totalBorrowed.sub(repayAmount);
        userBorrows[msg.sender][token] = userBorrows[msg.sender][token].sub(repayAmount);

        emit Repay(msg.sender, token, repayAmount);
    }

    function getAvailableBorrowLimit(address user, address token) public view returns (uint256) {
        uint256 totalCollateralValue = 0;
        uint256 totalBorrowedValue = 0;

        address[3] memory supportedTokens = [nativeToken, nibs, usdc];

        for (uint i = 0; i < supportedTokens.length; i++) {
            address currentToken = supportedTokens[i];
            Asset storage asset = assets[currentToken];

            uint256 depositValue = userDeposits[user][currentToken].mul(getPrice(currentToken)).mul(asset.collateralFactor).div(PRECISION);
            totalCollateralValue = totalCollateralValue.add(depositValue);

            uint256 borrowValue = userBorrows[user][currentToken].mul(getPrice(currentToken));
            totalBorrowedValue = totalBorrowedValue.add(borrowValue);
        }

        if (totalCollateralValue <= totalBorrowedValue) {
            return 0;
        }

        uint256 availableBorrowValue = totalCollateralValue.sub(totalBorrowedValue);
        return availableBorrowValue.mul(PRECISION).div(getPrice(token));
    }

    // This function should be implemented with an oracle in a real-world scenario
    function getPrice(address token) internal pure returns (uint256) {
        // Placeholder prices
        if (token == address(0x1)) { // Native token
            return 100 * PRECISION; // $100
        } else if (token == address(0x2)) { // NIBS
            return 10 * PRECISION; // $10
        } else if (token == address(0x3)) { // USDC
            return 1 * PRECISION; // $1
        }
        return 0;
    }
}