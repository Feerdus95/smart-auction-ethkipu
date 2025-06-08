# SmartAuctionEthKipu

> A smart contract auction system built on Ethereum. Think of it like _insert your favorite bidding platform_, but decentralized and automated.

## 📋 Overview

Creates an auction where people can bid cryptocurrency (ETH) on items. The contract handles everything automatically - no middleman needed.

## ✨ Key Features

- **Minimum 5% increment**: Each bid must be 5% higher than the last
- **Auto-extension**: Auction extends 10 minutes if someone bids in the final 10 minutes
- **Partial withdrawals**: Get your money back during auction if you're not winning
- **2% platform fee**: Small fee on refunds (like payment processing fees in web2)
- **Emergency controls**: Can pause if something goes wrong

## 🛠 Main Functions

### For Bidders
```solidity
function bid() external payable;           // Place a bid
function withdrawDeposit() external;       // Get refund after auction ends
function partialWithdrawExcess() external; // Get excess money back during auction
```

### For Sellers
```solidity
function endAuction() external;     // End the auction and get paid
function withdrawFees() external;    // Collect platform fees
```

### For Everyone
```solidity
function showWinner() external view returns (address, uint256); // See who won
function showOffers() external view returns (Bid[] memory);     // See all bids
```

## 🏗 Contract Architecture

### State Variables
- `seller`: Auction creator who receives winning bid
- `highestBidder`: Current highest bidder
- `highestBid`: Current highest bid amount
- `deposits`: Total deposits per participant
- `offers`: Array of all bid records
- `collectedFees`: Accumulated commission fees

### Constants
- `MIN_INCREMENT_PERCENT`: 105 (5% minimum increase)
- `EXTENSION_TIME`: 600 seconds (10 minutes)
- `EXTENSION_WINDOW`: 600 seconds (10 minutes before end)
- `REFUND_FEE_PERCENT`: 2 (2% commission on refunds)

### Events
```solidity
event NewOffer(address indexed bidder, uint amount);     // When someone bids
event AuctionEnded(address indexed winner, uint amount); // When auction ends
event Withdrawal(address indexed bidder, uint amount);   // When funds withdrawn
```

## 🔒 Security Features

Uses OpenZeppelin contracts:
- **ReentrancyGuard**: Prevents double-spending attacks
- **Ownable**: Admin controls
- **Pausable**: Emergency stop functionality
- **Address**: Safe money transfers

## 🚀 Setup

1. Open [remix.ethereum.org](https://remix.ethereum.org/)
2. Upload `SmartAuctionEthKipu.sol`
3. Compile with Solidity ^0.8.30
4. Deploy with constructor parameters:
   - `_startTime`: Unix timestamp for auction start
   - `_durationMinutes`: Auction duration in minutes

### Constructor Example
```solidity
// For an auction starting in 1 hour, lasting 24 hours
startTime: 1703529600  // Unix timestamp
durationMinutes: 1440  // 24 * 60 minutes
```

## ⛽ Gas Costs

| Function           | Estimated Gas |
|--------------------|---------------|
| `bid()`            | ~150,000      |
| `withdrawDeposit()`| ~80,000       |
| `endAuction()`     | ~100,000      |

## 📁 Project Structure

```
SmartAuctionEthKipu/
├── SmartAuctionEthKipu.sol  // Main contract
├── README.md               // This file
└── remix.ethereum created files  // Dependencies and build files
```

## ⚠️ Important Notes

- **Immutable**: Once deployed, contract rules cannot be changed
- **Testnet First**: Always test on testnet before mainnet deployment
- **Gas Fees**: Users pay transaction fees, not the contract deployer
- **No Cancellation**: Auctions cannot be cancelled once started

## ❌ Error Messages

| Error Message | Meaning |
|--------------|---------|
| "Auction is not active" | Auction hasn't started or has ended |
| "Bid must be at least 5% higher" | Insufficient bid increment |
| "Winner cannot withdraw refund" | Winner trying to withdraw |
| "No funds to withdraw" | No deposit available |

> **⚠️ Disclaimer**: Test thoroughly before deploying to mainnet with real funds.
