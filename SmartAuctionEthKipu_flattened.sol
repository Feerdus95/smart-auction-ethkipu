
// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol


// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Errors.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/Errors.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of common custom errors used in multiple contracts
 *
 * IMPORTANT: Backwards compatibility is not guaranteed in future versions of the library.
 * It is recommended to avoid relying on the error API for critical functionality.
 *
 * _Available since v5.1._
 */
library Errors {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedCall();

    /**
     * @dev The deployment failed.
     */
    error FailedDeployment();

    /**
     * @dev A necessary precompile is missing.
     */
    error MissingPrecompile(address);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v5.2.0) (utils/Address.sol)

pragma solidity ^0.8.20;


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert Errors.InsufficientBalance(address(this).balance, amount);
        }

        (bool success, bytes memory returndata) = recipient.call{value: amount}("");
        if (!success) {
            _revert(returndata);
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {Errors.FailedCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {Errors.FailedCall}) in case
     * of an unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {Errors.FailedCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {Errors.FailedCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            assembly ("memory-safe") {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert Errors.FailedCall();
        }
    }
}

// File: SmartAuctionEthKipu.sol


pragma solidity ^0.8.30;





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
