// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Project
 * @dev Smart contract for decentralized content monetization platform
 */
contract Project {
    address public owner;
    uint256 public platformFeePercentage;
    uint256 private constant PERCENTAGE_BASE = 100;

    struct Content {
        address creator;
        string contentHash;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Content) public contents;
    mapping(address => mapping(uint256 => bool)) public purchases;
    uint256 public contentCounter;
    mapping(address => uint256) public creatorBalance;

    event ContentPublished(uint256 indexed contentId, address indexed creator, uint256 price);
    event ContentPurchased(uint256 indexed contentId, address indexed buyer, address indexed creator, uint256 price);
    event CreatorWithdraw(address indexed creator, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(uint256 _platformFeePercentage) {
        require(_platformFeePercentage < PERCENTAGE_BASE, "Fee too high");
        owner = msg.sender;
        platformFeePercentage = _platformFeePercentage;
        contentCounter = 0;
    }

    /**
     * @dev Publish new content to the platform
     * @param _contentHash IPFS or other decentralized storage hash for the content
     * @param _price Price in wei to access the content
     */
    function publishContent(string memory _contentHash, uint256 _price) external {
        contentCounter++;
        
        contents[contentCounter] = Content({
            creator: msg.sender,
            contentHash: _contentHash,
            price: _price,
            isActive: true
        });
        
        emit ContentPublished(contentCounter, msg.sender, _price);
    }

    /**
     * @dev Purchase access to content
     * @param _contentId ID of the content to purchase
     */
    function purchaseContent(uint256 _contentId) external payable {
        Content storage content = contents[_contentId];
        require(content.creator != address(0), "Content does not exist");
        require(content.isActive, "Content is not active");
        require(msg.value >= content.price, "Insufficient payment");
        require(!purchases[msg.sender][_contentId], "Already purchased");
        
        uint256 platformFee = (content.price * platformFeePercentage) / PERCENTAGE_BASE;
        uint256 creatorPayment = content.price - platformFee;
        
        creatorBalance[content.creator] += creatorPayment;
        purchases[msg.sender][_contentId] = true;
        
        // Refund excess payment if any
        if (msg.value > content.price) {
            payable(msg.sender).transfer(msg.value - content.price);
        }
        
        emit ContentPurchased(_contentId, msg.sender, content.creator, content.price);
    }

    /**
     * @dev Withdraw creator earnings
     */
    function withdrawEarnings() external {
        uint256 amount = creatorBalance[msg.sender];
        require(amount > 0, "No earnings to withdraw");
        
        creatorBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        
        emit CreatorWithdraw(msg.sender, amount);
    }
}
