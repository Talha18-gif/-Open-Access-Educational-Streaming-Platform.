// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Smart contract for the Open Access Educational Streaming Platform
contract OpenAccessEduStreaming {

    address public owner;  // Declare the owner of the contract

    // Event to emit when a new content is added
    event NewContentAdded(address indexed creator, uint256 contentId, string title, string contentUrl);
    
    // Event to emit when a user subscribes to a content
    event ContentSubscribed(address indexed user, uint256 contentId);

    // Struct to hold content details
    struct Content {
        address creator;
        string title;
        string contentUrl;
        uint256 price; // price for renting or accessing content (in wei)
        bool isActive; // flag to check if content is still active
    }

    // Mapping to store content by contentId
    mapping(uint256 => Content) public contents;
    
    // Mapping to store users' subscriptions to contents
    mapping(address => mapping(uint256 => bool)) public userSubscriptions;

    uint256 public nextContentId;

    // Only the creator of the content can modify or remove it
    modifier onlyCreator(uint256 contentId) {
        require(contents[contentId].creator == msg.sender, "You are not the creator of this content.");
        _;
    }

    // Only the owner can perform certain actions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    // Constructor to set the owner of the contract
    constructor() {
        owner = msg.sender;  // Set the owner to the address deploying the contract
    }

    // Function to add a new content (video/educational resource)
    function addContent(string memory title, string memory contentUrl, uint256 price) public {
        require(bytes(title).length > 0, "Content title cannot be empty");
        require(bytes(contentUrl).length > 0, "Content URL cannot be empty");

        contents[nextContentId] = Content({
            creator: msg.sender,
            title: title,
            contentUrl: contentUrl,
            price: price,
            isActive: true
        });

        emit NewContentAdded(msg.sender, nextContentId, title, contentUrl);
        nextContentId++;
    }

    // Function to remove content (Only creator can do this)
    function removeContent(uint256 contentId) public onlyCreator(contentId) {
        require(contents[contentId].isActive, "Content is already removed.");

        contents[contentId].isActive = false;
        emit NewContentAdded(msg.sender, contentId, contents[contentId].title, contents[contentId].contentUrl);  // Optional: Emit event when content is deactivated
    }

    // Function for users to subscribe to the content (pay the price for access)
    function subscribeToContent(uint256 contentId) public payable {
        require(contents[contentId].isActive, "Content is not available.");
        require(msg.value >= contents[contentId].price, "Insufficient funds to access the content.");

        userSubscriptions[msg.sender][contentId] = true;
        payable(contents[contentId].creator).transfer(msg.value);

        emit ContentSubscribed(msg.sender, contentId);
    }

    // Function to check if a user has subscribed to the content
    function hasSubscribed(address user, uint256 contentId) public view returns (bool) {
        return userSubscriptions[user][contentId];
    }

    // Function to get content details by ID
    function getContent(uint256 contentId) public view returns (string memory title, string memory contentUrl, uint256 price, bool isActive) {
        Content memory content = contents[contentId];
        return (content.title, content.contentUrl, content.price, content.isActive);
    }

    // Function to withdraw contract balance (for owner/admin) — if needed for further functionality
    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }

    // Fallback function to accept ether sent directly to the contract
    receive() external payable {}
}
