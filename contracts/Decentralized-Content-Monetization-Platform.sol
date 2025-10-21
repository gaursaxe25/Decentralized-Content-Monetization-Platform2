// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
 * @title Project
 * @dev Smart contract for decentralized content monetization platform
 */
contract Project 
    address public 
    uint256 public platformFeePercentag

    struct Conten
        address creator;
        string contentHash;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Content) public contents;
    mapping(address => mapping(uint256 => bool)) public purchases;
    uint256 public contentCounter;
    mapping(address => uint256) public creatorBalance;
    uint256 public platformBalance;

    event ContentPublished(uint256 indexed contentId, address indexed creator, uint256 price);
    event ContentPurchased(uint256 indexed contentId, address indexed buyer, address indexed creator, uint256 price);
    event CreatorWithdraw(address indexed creator, uint256 amount);
    event ContentDeactivated(uint256 indexed contentId)
    event ContentReactivated(uint256 indexed contentId);
    event ContentPriceUpdated(uint256 indexed contentId, uint256 newPrice);
    event PlatformFeeUpdated(uint256 newFee);
    event PlatformFeesWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyCreator(uint256 _contentId) {
        require(contents[_contentId].creator == msg.sender, "Not content creator");
        _;
    }

    constructor(uint256 _platformFeePercentage) {
        require(_platformFeePercentage < PERCENTAGE_BASE, "Fee too high");
        owner = msg.sender;
        platformFeePercentage = _platformFeePercentage;
        contentCounter = 0;
    }

    function publishContent(string memory _contentHash, uint256 _price) external {
        contentCounter++;

        emit ContentPublished(contentCounter, msg.sender, _price);
    }

    function purchaseContent(uint256 _contentId) external payable {
        Content storage content = contents[_contentId];
        require(content.creator != address(0), "Content does not exist");
        require(content.isActive, "Content is not active");
        require(msg.value >= content.price, "Insufficient payment");
        require(!purchases[msg.sender][_contentId], "Already purchased");

        uint256 platformFee = (content.price * platformFeePercentage) / PERCENTAGE_BASE;
        uint256 creatorPayment = content.price - platformFee;

        creatorBalance[content.creator] += creatorPayment;
        platformBalance += platformFee;
        purchases[msg.sender][_contentId] = true;

        if (msg.value > content.price) {
            payable(msg.sender).transfer(msg.value - content.price);
        }

        emit ContentPurchased(_contentId, msg.sender, content.creator, content.price);
    }

    function withdrawEarnings() external {
        uint256 amount = creatorBalance[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        creatorBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit CreatorWithdraw(msg.sender, amount);
    }

    function deactivateContent(uint256 _contentId) external onlyCreator(_contentId) {
        Content storage content = contents[_contentId];
        require(content.isActive, "Content already inactive");

        content.isActive = false;
        emit ContentDeactivated(_contentId);
    }

    function reactivateContent(uint256 _contentId) external onlyCreator(_contentId) {
        Content storage content = contents[_contentId];
        require(!content.isActive, "Content already active");

        content.isActive = true;
        emit ContentReactivated(_contentId);
    }

    function updateContentPrice(uint256 _contentId, uint256 _newPrice) external onlyCreator(_contentId) {
        require(_newPrice > 0, "Price must be greater than 0");

        contents[_contentId].price = _newPrice;
        emit ContentPriceUpdated(_contentId, _newPrice);
    }

    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee < PERCENTAGE_BASE, "Invalid fee");
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    function withdrawPlatformFees() external onlyOwner {
        require(platformBalance > 0, "No platform fees to withdraw");

        uint256 amount = platformBalance;
        platformBalance = 0;
        payable(owner).transfer(amount);

        emit PlatformFeesWithdrawn(owner, amount);
    }

    function getContent(uint256 _contentId) external view returns (
        address creator,
        string memory contentHash,
        uint256 price,
        bool isActive
    ) {
        Content memory c = contents[_contentId];
        return (c.creator, c.contentHash, c.price, c.isActive);
    }
}  
{

    function publishContent(string memory _contentHash, uint256 _price) external {
        contentCounter++;

        contents[contentCounter] = Content({
            creator: msg.sender,
            contentHash: _contentHash,
            price: _price,
            isActive: true
        });
// START
Updated on 2025-10-21
// END
