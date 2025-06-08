// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Advanced Auction Contract with Dynamic Extension and Partial Refunds
/// @author Feerdus95
/// @notice Implements an auction with 5% minimum increment, refund with 2% fee, and dynamic end time extension
/// @dev Bids are in wei. Handles Ether only, rewards must be delivered separately.

contract SmartAuctionEthKipu is ReentrancyGuard, Ownable, Pausable {
    using Address for address payable;

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

    /// @notice Minimum percentage increment required for new bids (e.g., 5% = 105)
    uint public constant MIN_INCREMENT_PERCENT = 105;

    /// @notice Time (seconds) for auction extension when a valid bid is made near ending (10 min = 600 seconds)
    uint public constant EXTENSION_TIME = 600;

    /// @notice Time window before the end when extensions are allowed (10 minutes)
    uint public constant EXTENSION_WINDOW = 600;

    /// @notice Commission fee percentage taken from refund to losers (2% = 2)
    uint public constant REFUND_FEE_PERCENT = 2;

    /// @notice Auction active flag
    bool public ended;

    /// @notice Struct to record each offer
    struct Offer {
        address bidder;
        uint amount;
        uint timestamp;
    }
    Offer[] public offers;

    /// @notice Tracks total deposits for each participant (used for withdrawal/refund)
    mapping(address => uint) public deposits;

    /// @notice Tracks the latest offer index for each bidder (for partial withdrawal computation)
    mapping(address => uint) private lastOfferIndex;

    /// @notice Tracks total fees collected from refunds
    uint private collectedFees;

    // ----------------------- Events --------------------
    /// @notice Emitted when a new valid offer is received
    /// @param bidder The address of the participant who made the offer
    /// @param amount The amount of the offer
    event NewOffer(address indexed bidder, uint amount);

    /// @notice Emitted when the auction ends
    /// @param winner The address of the winner
    /// @param amount The winning bid amount
    event AuctionEnded(address indexed winner, uint amount);

    /// @notice Emitted on withdrawal
    /// @param bidder The address of the participant withdrawing
    /// @param amount The amount withdrawn
    event Withdrawal(address indexed bidder, uint amount);

    // -------------------- Modifiers -----------------
    /// @dev Only allows auction to operate while active
    modifier onlyWhileActive(){
        require(!ended && block.timestamp >= startTime && block.timestamp < endTime, "Auction is not active");
        _;
    }

    /// @dev Only after auction has ended
    modifier onlyAfterEnd(){
        require(block.timestamp >= endTime || ended, "Auction not yet ended");
        _;
    }

    /// @dev Only seller can call
    modifier onlySeller(){
        require(msg.sender == seller, "Only seller can call");
        _;
    }

    /// @dev If the sender is not the highest bidder
    modifier onlyNotWinner(){
        require(msg.sender != highestBidder, "Winner cannot withdraw refund");
        _;
    }

    // ------------------- Private Helper Functions ---------------------
    /// @dev Internal function to safely transfer ETH using OpenZeppelin's Address library
    function _safeTransfer(address payable to, uint amount) private {
        to.sendValue(amount);
    }

    /// @dev Internal function to calculate fees
    function _calculateFee(uint amount) private pure returns (uint fee, uint refund) {
        fee = (amount * REFUND_FEE_PERCENT) / 100;
        refund = amount - fee;
    }

    // ------------------- Constructor ---------------------
    /// @notice Initializes the auction
    /// @param _startTime The start timestamp
    /// @param _durationMinutes Auction duration in minutes
    constructor(uint _startTime, uint _durationMinutes) Ownable(msg.sender) {
        require(_durationMinutes > 0, "Duration must be greater than zero");
        require(_startTime > block.timestamp, "Start time must be in future");
        require(_durationMinutes <= 30 * 24 * 60, "Duration too long");
        
        seller = payable(msg.sender);
        startTime = _startTime;
        endTime = _startTime + (_durationMinutes * 1 minutes);
    }

    // -------------------- Auction logic --------------------

    /// @notice Place a new bid. Must be at least 5% higher than previous bid and during auction time
    function bid() external payable onlyWhileActive nonReentrant whenNotPaused {
        require(msg.value > 0, "Bid must be greater than 0");
        
        // Calculate new total bid for this bidder
        uint newTotalBid = deposits[msg.sender] + msg.value;
        uint minRequired = highestBid == 0 ? 0 : (highestBid * MIN_INCREMENT_PERCENT) / 100;
        
        require(newTotalBid > minRequired, "Bid must be at least 5% higher than highest bid");

        // Track deposit for bidder
        deposits[msg.sender] += msg.value;

        // Record offer
        offers.push(Offer(msg.sender, msg.value, block.timestamp));
        lastOfferIndex[msg.sender] = offers.length - 1;

        // New highest bid! (Use total accumulated deposit)
        highestBid = newTotalBid;
        highestBidder = msg.sender;

        // Extend auction if bid comes in the last 10 minutes
        if (endTime - block.timestamp <= EXTENSION_WINDOW) {
            endTime = block.timestamp + EXTENSION_TIME;
        }

        emit NewOffer(msg.sender, newTotalBid);
    }

    /// @notice Show the current winner and bid amount
    /// @return winner Winner address
    /// @return amount Winning bid
    function showWinner() public view onlyAfterEnd returns(address winner, uint amount) {
        return (highestBidder, highestBid);
    }

    /// @notice Returns list of all offers (for off-chain read)
    /// @return Array of Offer structs
    function showOffers() public view returns (Offer[] memory) {
        return offers;
    }

    /// @notice Returns the current number of offers
    function numOffers() public view returns(uint) {
        return offers.length;
    }

    /// @notice Withdraws funds for non-winning bidders after auction ends.
    function withdrawDeposit() public onlyAfterEnd onlyNotWinner nonReentrant {
        uint totalToReturn = deposits[msg.sender];
        require(totalToReturn > 0, "No funds to withdraw");

        // Effects first (CEI pattern)
        deposits[msg.sender] = 0;
        
        // Calculate fee and refund using private helper
        (uint fee, uint refund) = _calculateFee(totalToReturn);
        collectedFees += fee;

        // Interactions last using OpenZeppelin's safe transfer
        _safeTransfer(payable(msg.sender), refund);

        emit Withdrawal(msg.sender, refund);
    }

    /// @notice Partial withdrawal of excess (over last offer) while auction is active
    function partialWithdrawExcess() public onlyWhileActive nonReentrant {
        require(msg.sender != highestBidder, "Current highest bidder cannot withdraw");
        
        uint totalDeposit = deposits[msg.sender];
        require(totalDeposit > 0, "No excess funds to withdraw");

        // Effects first
        deposits[msg.sender] = 0;

        // Interactions last using OpenZeppelin's safe transfer
        _safeTransfer(payable(msg.sender), totalDeposit);
        
        emit Withdrawal(msg.sender, totalDeposit);
    }

    /// @notice Ends the auction (anyone can call after time's up). Only executes once
    function endAuction() public onlyAfterEnd nonReentrant {
        require(!ended, "Already ended");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // Transfer winner's deposit to seller
        if (highestBid > 0) {
            uint winningAmount = deposits[highestBidder];
            deposits[highestBidder] = 0;
            
            _safeTransfer(seller, winningAmount);
        }
    }

    /// @notice Allows seller to withdraw collected fees from refunds
    function withdrawFees() external onlySeller nonReentrant {
        uint fees = collectedFees;
        require(fees > 0, "No fees to withdraw");
        
        collectedFees = 0;
        
        _safeTransfer(seller, fees);
    }

    // ------------------- Emergency Functions (OpenZeppelin Ownable/Pausable) ---------------------
    /// @notice Emergency pause function (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Emergency unpause function (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Emergency end auction (only owner)
    function emergencyEndAuction() external onlyOwner {
        require(!ended, "Already ended");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    // ------------------- Getter Functions for Private Variables ---------------------
    /// @notice Returns collected fees (only seller can view)
    function getCollectedFees() external view onlySeller returns (uint) {
        return collectedFees;
    }

    /// @notice Returns last offer index for caller
    function getLastOfferIndex() external view returns (uint) {
        return lastOfferIndex[msg.sender];
    }

    /// @notice Fallback function reverts all ethers sent directly
    receive() external payable {
        revert("Please use the bid() function to participate.");
    }

    fallback() external payable {
        revert("Invalid call. Use the correct function.");
    }
}
