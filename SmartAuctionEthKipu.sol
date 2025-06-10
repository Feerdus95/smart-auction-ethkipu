// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Advanced Auction Contract with Dynamic Extension and Partial Refunds
/// @author Feerdus95
/// @notice Implements auction with 5% minimum increment, refund with 2% fee, and dynamic end time extension
/// @dev Bids are in wei. Handles Ether only, rewards must be delivered separately.

contract SmartAuctionEthKipu is ReentrancyGuard, Ownable, Pausable {
    using Address for address payable;

    // ------------------- State Variables ---------------------
    /// @notice Address of the auction creator/seller
    address payable public seller;
    /// @notice Address of the current highest bidder
    address public highestBidder;
    /// @notice Highest bid amount
    uint public highestBid;
    /// @notice Start time (timestamp) 
    uint public startTime;
    /// @notice End time (timestamp, dynamically extended)
    uint public endTime;
    /// @notice Auction active flag
    bool public ended;

    // ------------------- Constants ---------------------
    /// @notice Minimum percentage increment required for new bids (5% = 105)
    uint public constant MIN_INCREMENT_PERCENT = 105;
    /// @notice Time (seconds) for auction extension (10 min = 600 seconds)
    uint public constant EXTENSION_TIME = 600;
    /// @notice Time window before end when extensions allowed (10 minutes)
    uint public constant EXTENSION_WINDOW = 600;
    /// @notice Commission fee percentage taken from refund (2% = 2)
    uint public constant REFUND_FEE_PERCENT = 2;

    // ------------------- Data Structures ---------------------
    /// @notice Struct to record each offer
    struct Offer {
        address bidder;
        uint amount;
        uint timestamp;
    }

    /// @notice Array of all offers
    Offer[] public offers;
    /// @notice Tracks total deposits for each participant
    mapping(address => uint) public deposits;
    /// @notice Tracks latest offer index for each bidder
    mapping(address => uint) private lastOfferIndex;
    /// @notice Tracks total fees collected
    uint private collectedFees;

    // ------------------- Events ---------------------
    /// @notice Emitted when new valid offer received
    /// @param bidder Address of participant who made offer
    /// @param amount Amount of offer
    event NewOffer(address indexed bidder, uint amount);
    
    /// @notice Emitted when auction ends
    /// @param winner Address of winner
    /// @param amount Winning bid amount
    event AuctionEnded(address indexed winner, uint amount);
    
    /// @notice Emitted on withdrawal
    /// @param bidder Address of participant withdrawing
    /// @param amount Amount withdrawn
    event Withdrawal(address indexed bidder, uint amount);

    // ------------------- Modifiers ---------------------
    /// @dev Only allows auction to operate while active
    modifier onlyWhileActive(){
        require(!ended, "Auction ended");
        require(block.timestamp >= startTime, "Not started");
        require(block.timestamp < endTime, "Time expired");
        _;
    }

    /// @dev Only after auction has ended
    modifier onlyAfterEnd(){
        require(block.timestamp >= endTime || ended, "Not ended");
        _;
    }

    /// @dev Only seller can call
    modifier onlySeller(){
        require(msg.sender == seller, "Not seller");
        _;
    }

    /// @dev If sender is not highest bidder
    modifier onlyNotWinner(){
        require(msg.sender != highestBidder, "Winner cannot withdraw");
        _;
    }

    // ------------------- Constructor ---------------------
    /// @notice Initializes auction
    /// @param _startTime Start timestamp
    /// @param _durationMinutes Auction duration in minutes
    constructor(uint _startTime, uint _durationMinutes) Ownable(msg.sender) {
        require(_durationMinutes > 0, "Invalid duration");
        require(_startTime > block.timestamp, "Invalid start");
        require(_durationMinutes <= 43200, "Too long"); // Max 30 days
        
        seller = payable(msg.sender);
        startTime = _startTime;
        endTime = _startTime + (_durationMinutes * 1 minutes);
    }

    // ------------------- Private Helper Functions ---------------------
    /// @dev Internal function to safely transfer ETH
    /// @param to Recipient address
    /// @param amount Amount to transfer
    function _safeTransfer(address payable to, uint amount) private {
        to.sendValue(amount);
    }

    /// @dev Internal function to calculate fees
    /// @param amount Total amount
    /// @return fee Fee amount
    /// @return refund Refund amount after fee
    function _calculateFee(uint amount) private pure returns (uint fee, uint refund) {
        fee = (amount * REFUND_FEE_PERCENT) / 100;
        refund = amount - fee;
    }

    // ------------------- Auction Functions ---------------------
    
    /// @notice Place new bid. Must be 5% higher than previous bid during auction time
    /// @dev Updates deposits, records offer, updates highest bid, may extend time
    function bid() external payable onlyWhileActive nonReentrant whenNotPaused {
        require(msg.value > 0, "Zero bid");
        
        uint newTotalBid = deposits[msg.sender] + msg.value;
        uint minRequired = highestBid == 0 ? 0 : (highestBid * MIN_INCREMENT_PERCENT) / 100;
        require(newTotalBid > minRequired, "Bid too low");

        // State updates
        deposits[msg.sender] += msg.value;
        offers.push(Offer(msg.sender, msg.value, block.timestamp));
        lastOfferIndex[msg.sender] = offers.length - 1;
        highestBid = newTotalBid;
        highestBidder = msg.sender;

        // Extend auction if needed
        if (endTime - block.timestamp <= EXTENSION_WINDOW) {
            endTime = block.timestamp + EXTENSION_TIME;
        }

        emit NewOffer(msg.sender, newTotalBid);
    }

    /// @notice Partial withdrawal of excess funds while auction active
    /// @dev Allows non-highest bidders to withdraw during auction
    function partialWithdrawExcess() public onlyWhileActive nonReentrant {
        require(msg.sender != highestBidder, "Winner cannot withdraw");
        
        uint totalDeposit = deposits[msg.sender];
        require(totalDeposit > 0, "No funds");

        // Single state update
        deposits[msg.sender] = 0;
        
        _safeTransfer(payable(msg.sender), totalDeposit);
        emit Withdrawal(msg.sender, totalDeposit);
    }

    /// @notice Show current winner and bid amount
    /// @dev Only callable after auction ends
    /// @return winner Winner address
    /// @return amount Winning bid
    function showWinner() public view onlyAfterEnd returns(address winner, uint amount) {
        return (highestBidder, highestBid);
    }

    /// @notice Returns list of all offers
    /// @dev For off-chain reading
    /// @return Array of Offer structs
    function showOffers() public view returns (Offer[] memory) {
        return offers;
    }

    /// @notice Returns current number of offers
    /// @return Number of offers made
    function numOffers() public view returns(uint) {
        return offers.length;
    }

    /// @notice Withdraws funds for non-winning bidders after auction ends
    /// @dev Deducts 2% commission fee
    function withdrawDeposit() public onlyAfterEnd onlyNotWinner nonReentrant {
        uint totalToReturn = deposits[msg.sender];
        require(totalToReturn > 0, "No funds");

        // Single state update
        deposits[msg.sender] = 0;
        
        (uint fee, uint refund) = _calculateFee(totalToReturn);
        collectedFees += fee;

        _safeTransfer(payable(msg.sender), refund);
        emit Withdrawal(msg.sender, refund);
    }

    /// @notice Ends auction and transfers winning bid to seller
    /// @dev Can be called by anyone after time expires. Only executes once
    function endAuction() public onlyAfterEnd nonReentrant {
        require(!ended, "Already ended");
        
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        if (highestBid > 0) {
            uint winningAmount = deposits[highestBidder];
            deposits[highestBidder] = 0;
            _safeTransfer(seller, winningAmount);
        }
    }

    /// @notice MANDATORY: Owner distributes ETH to non-winning offers using loop
    /// @dev Distributes refunds with 2% fee to all non-winners
    function distributeRefunds() external onlyOwner onlyAfterEnd nonReentrant {
        require(ended, "Auction not ended");
        
        // Variables declared outside loop (dirty variables)
        uint offersLength = offers.length;
        address currentBidder;
        uint currentDeposit;
        uint fee;
        uint refund;
        
        for (uint i = 0; i < offersLength; i++) {
            currentBidder = offers[i].bidder;
            
            // Skip if winner or no deposit
            if (currentBidder == highestBidder) continue;
            
            currentDeposit = deposits[currentBidder];
            if (currentDeposit == 0) continue;
            
            // Calculate refund with fee
            fee = (currentDeposit * REFUND_FEE_PERCENT) / 100;
            refund = currentDeposit - fee;
            
            // Single state update per bidder
            deposits[currentBidder] = 0;
            collectedFees += fee;
            
            // Transfer refund
            _safeTransfer(payable(currentBidder), refund);
            emit Withdrawal(currentBidder, refund);
        }
    }

    /// @notice Allows seller to withdraw collected fees
    /// @dev Only callable by auction seller
    function withdrawFees() external onlySeller nonReentrant {
        uint fees = collectedFees;
        require(fees > 0, "No fees");
        
        collectedFees = 0;
        _safeTransfer(seller, fees);
    }

    /// @notice Emergency ETH recovery function
    /// @dev Only owner can recover stuck ETH
    function emergencyWithdraw() external onlyOwner {
        require(ended, "Auction active");
        
        uint balance = address(this).balance;
        require(balance > 0, "No ETH");
        
        _safeTransfer(seller, balance);
    }

    /// @notice Emergency pause function
    /// @dev Only owner can pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Emergency unpause function  
    /// @dev Only owner can unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    // ------------------- Getter Functions ---------------------
    /// @notice Returns collected fees
    /// @dev Only seller can view
    /// @return Amount of collected fees
    function getCollectedFees() external view onlySeller returns (uint) {
        return collectedFees;
    }

    /// @notice Returns last offer index for caller
    /// @dev Returns caller's last offer index
    /// @return Last offer index
    function getLastOfferIndex() external view returns (uint) {
        return lastOfferIndex[msg.sender];
    }

    /// @notice Fallback function reverts all ethers sent directly
    receive() external payable {
        revert("Use bid()");
    }

    /// @notice Fallback function reverts invalid calls
    fallback() external payable {
        revert("Invalid call");
    }
}