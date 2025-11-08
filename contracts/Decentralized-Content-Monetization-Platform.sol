URL or IPFS hash for content metadata
        uint256 totalFunds;   Tracks the pending withdrawal balances for creators
    mapping(address => uint256) public pendingWithdrawals;

    event ContentRegistered(uint256 indexed contentId, address indexed creator, string metadataURI);
    event ContentSupported(uint256 indexed contentId, address indexed supporter, uint256 amount);
    event FundsWithdrawn(address indexed creator, uint256 amount);

    modifier onlyCreator(uint256 contentId) {
        require(contents[contentId].exists, "Content does not exist");
        require(msg.sender == contents[contentId].creator, "Caller is not content creator");
        _;
    }

    /**
     * @dev Register new content by creator
     * @param metadataURI Content metadata URI (e.g., IPFS hash)
     */
    function registerContent(string memory metadataURI) external returns (uint256) {
        contentCount++;
        contents[contentCount] = Content({
            id: contentCount,
            creator: payable(msg.sender),
            metadataURI: metadataURI,
            totalFunds: 0,
            exists: true
        });

        emit ContentRegistered(contentCount, msg.sender, metadataURI);
        return contentCount;
    }

    /**
     * @dev Support content by sending ETH. ETH is credited to the creator's withdrawal balance.
     * @param contentId ID of the content to support
     */
    function supportContent(uint256 contentId) external payable {
        Content storage content = contents[contentId];
        require(content.exists, "Content does not exist");
        require(msg.value > 0, "Support amount must be greater than zero");

        content.totalFunds += msg.value;
        pendingWithdrawals[content.creator] += msg.value;

        emit ContentSupported(contentId, msg.sender, msg.value);
    }

    /**
     * @dev Creator withdraws supported funds
     */
    function withdrawFunds() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingWithdrawals[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Withdrawal failed");

        emit FundsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Get content details including metadata and total funds raised
     * @param contentId ID of the content
     */
    function getContent(uint256 contentId) external view returns (
        uint256 id,
        address creator,
        string memory metadataURI,
        uint256 totalFunds
    ) {
        Content storage content = contents[contentId];
        require(content.exists, "Content does not exist");

        return (
            content.id,
            content.creator,
            content.metadataURI,
            content.totalFunds
        );
    }
}
// 
End
// 
