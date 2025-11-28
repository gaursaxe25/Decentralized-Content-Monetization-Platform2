// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DecentralizedContentMonetizationPlatform
 * @dev Basic platform for creators to register content, set prices, and receive payments directly
 * @notice Viewers pay per content; platform can take an optional fee
 */
contract DecentralizedContentMonetizationPlatform {
    address public owner;
    uint256 public platformFeeBP; // fee in basis points (e.g. 250 = 2.5%)

    struct Content {
        uint256 id;
        address payable creator;
        string  uri;           // metadata or content reference
        uint256 price;         // price in wei per access
        bool    isActive;
        uint256 createdAt;
    }

    uint256 public nextContentId;

    // contentId => Content
    mapping(uint256 => Content) public contents;

    // user => contentId => hasAccess
    mapping(address => mapping(uint256 => bool)) public hasAccess;

    // creator => total earned (before withdrawals)
    mapping(address => uint256) public pendingCreatorBalance;

    uint256 public totalVolume;
    uint256 public totalPlatformFees;

    event ContentRegistered(
        uint256 indexed id,
        address indexed creator,
        string uri,
        uint256 price,
        uint256 timestamp
    );

    event ContentUpdated(
        uint256 indexed id,
        uint256 price,
        bool isActive,
        uint256 timestamp
    );

    event ContentPurchased(
        uint256 indexed id,
        address indexed buyer,
        uint256 amount,
        uint256 fee,
        uint256 timestamp
    );

    event CreatorWithdrawal(address indexed creator, uint256 amount);
    event PlatformFeeUpdated(uint256 newFeeBP);
    event OwnerWithdrawal(uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyCreator(uint256 id) {
        require(contents[id].creator == msg.sender, "Not creator");
        _;
    }

    modifier contentExists(uint256 id) {
        require(contents[id].creator != address(0), "Content not found");
        _;
    }

    constructor(uint256 _platformFeeBP) {
        owner = msg.sender;
        require(_platformFeeBP <= 1000, "Fee too high"); // max 10%
        platformFeeBP = _platformFeeBP;
    }

    /**
     * @dev Register new monetizable content
     * @param uri Metadata or content URI
     * @param price Price in wei per access
     */
    function registerContent(string calldata uri, uint256 price) external returns (uint256 id) {
        require(price > 0, "Price = 0");

        id = nextContentId++;
        contents[id] = Content({
            id: id,
            creator: payable(msg.sender),
            uri: uri,
            price: price,
            isActive: true,
            createdAt: block.timestamp
        });

        emit ContentRegistered(id, msg.sender, uri, price, block.timestamp);
    }

    /**
     * @dev Update price or active flag for existing content
     */
    function updateContent(
        uint256 id,
        uint256 price,
        bool isActive
    )
        external
        contentExists(id)
        onlyCreator(id)
    {
        require(price > 0, "Price = 0");
        Content storage c = contents[id];
        c.price = price;
        c.isActive = isActive;

        emit ContentUpdated(id, price, isActive, block.timestamp);
    }

    /**
     * @dev Purchase access to content
     * @param id Content identifier
     */
    function buyAccess(uint256 id)
        external
        payable
        contentExists(id)
    {
        Content memory c = contents[id];
        require(c.isActive, "Inactive content");
        require(msg.value == c.price, "Incorrect payment");

        // fee and creator share
        uint256 fee = (msg.value * platformFeeBP) / 10000;
        uint256 creatorShare = msg.value - fee;

        pendingCreatorBalance[c.creator] += creatorShare;
        totalPlatformFees += fee;
        totalVolume += msg.value;

        hasAccess[msg.sender][id] = true;

        emit ContentPurchased(id, msg.sender, creatorShare, fee, block.timestamp);
    }

    /**
     * @dev Check if a user has paid access to a content
     */
    function userHasAccess(address user, uint256 id)
        external
        view
        returns (bool)
    {
        return hasAccess[user][id];
    }

    /**
     * @dev Creator withdraws accumulated earnings
     */
    function withdrawCreatorEarnings() external {
        uint256 amount = pendingCreatorBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingCreatorBalance[msg.sender] = 0;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Withdraw failed");
        emit CreatorWithdrawal(msg.sender, amount);
    }

    /**
     * @dev Owner withdraws platform fees
     */
    function withdrawPlatformFees(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Exceeds balance");
        require(amount <= totalPlatformFees, "Exceeds fees");
        totalPlatformFees -= amount;

        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "Fee withdraw failed");
        emit OwnerWithdrawal(amount);
    }

    /**
     * @dev Owner can adjust platform fee
     */
    function updatePlatformFee(uint256 newFeeBP) external onlyOwner {
        require(newFeeBP <= 1000, "Fee too high"); // max 10%
        platformFeeBP = newFeeBP;
        emit PlatformFeeUpdated(newFeeBP);
    }

    /**
     * @dev View helper: get basic content info
     */
    function getContent(uint256 id)
        external
        view
        contentExists(id)
        returns (
            address creator,
            string memory uri,
            uint256 price,
            bool isActive,
            uint256 createdAt
        )
    {
        Content memory c = contents[id];
        return (c.creator, c.uri, c.price, c.isActive, c.createdAt);
    }
}
