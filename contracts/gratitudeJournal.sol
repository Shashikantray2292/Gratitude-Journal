// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Gratitude Journal
 * @dev A smart contract for storing and sharing gratitude entries on the blockchain
 * @author Your Name
 */
contract GratitudeJournal {
    
    struct GratitudeEntry {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        bool isPrivate;
        uint256 likes;
    }
    
    // State variables
    mapping(uint256 => GratitudeEntry) public gratitudeEntries;
    mapping(address => uint256[]) public userEntries;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    
    uint256 public totalEntries;
    uint256 private nextEntryId;
    
    // Events
    event GratitudeAdded(uint256 indexed entryId, address indexed author, string content, bool isPrivate);
    event GratitudeLiked(uint256 indexed entryId, address indexed liker);
    event EntryMadePublic(uint256 indexed entryId, address indexed author);
    
    // Modifiers
    modifier onlyEntryOwner(uint256 _entryId) {
        require(gratitudeEntries[_entryId].author == msg.sender, "Not the owner of this entry");
        _;
    }
    
    modifier validEntry(uint256 _entryId) {
        require(_entryId < nextEntryId, "Entry does not exist");
        _;
    }
    
    /**
     * @dev Add a new gratitude entry
     * @param _content The gratitude message content
     * @param _isPrivate Whether the entry should be private or public
     */
    function addGratitudeEntry(string memory _content, bool _isPrivate) external {
        require(bytes(_content).length > 0, "Content cannot be empty");
        require(bytes(_content).length <= 500, "Content too long (max 500 characters)");
        
        uint256 entryId = nextEntryId;
        
        gratitudeEntries[entryId] = GratitudeEntry({
            id: entryId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            isPrivate: _isPrivate,
            likes: 0
        });
        
        userEntries[msg.sender].push(entryId);
        totalEntries++;
        nextEntryId++;
        
        emit GratitudeAdded(entryId, msg.sender, _content, _isPrivate);
    }
    
    /**
     * @dev Like a public gratitude entry
     * @param _entryId The ID of the entry to like
     */
    function likeEntry(uint256 _entryId) external validEntry(_entryId) {
        GratitudeEntry storage entry = gratitudeEntries[_entryId];
        
        require(!entry.isPrivate, "Cannot like private entries");
        require(entry.author != msg.sender, "Cannot like your own entry");
        require(!hasLiked[_entryId][msg.sender], "Already liked this entry");
        
        hasLiked[_entryId][msg.sender] = true;
        entry.likes++;
        
        emit GratitudeLiked(_entryId, msg.sender);
    }
    
    /**
     * @dev Make a private entry public
     * @param _entryId The ID of the entry to make public
     */
    function makeEntryPublic(uint256 _entryId) external validEntry(_entryId) onlyEntryOwner(_entryId) {
        GratitudeEntry storage entry = gratitudeEntries[_entryId];
        require(entry.isPrivate, "Entry is already public");
        
        entry.isPrivate = false;
        
        emit EntryMadePublic(_entryId, msg.sender);
    }
    
    /**
     * @dev Get public entries with pagination to avoid gas limit issues
     * @param _offset Starting index for pagination
     * @param _limit Maximum number of entries to return
     * @return Arrays of entry data for public entries
     */
    function getPublicEntries(uint256 _offset, uint256 _limit) external view returns (
        uint256[] memory ids,
        address[] memory authors,
        string[] memory contents,
        uint256[] memory timestamps,
        uint256[] memory likes,
        uint256 totalPublicEntries
    ) {
        require(_limit > 0 && _limit <= 50, "Limit must be between 1 and 50");
        
        // Count total public entries
        uint256 publicCount = 0;
        for (uint256 i = 0; i < nextEntryId; i++) {
            if (!gratitudeEntries[i].isPrivate) {
                publicCount++;
            }
        }
        
        // Calculate actual entries to return
        uint256 startIndex = _offset;
        uint256 endIndex = _offset + _limit;
        if (endIndex > publicCount) {
            endIndex = publicCount;
        }
        
        uint256 returnCount = endIndex > startIndex ? endIndex - startIndex : 0;
        
        // Initialize arrays
        ids = new uint256[](returnCount);
        authors = new address[](returnCount);
        contents = new string[](returnCount);
        timestamps = new uint256[](returnCount);
        likes = new uint256[](returnCount);
        
        // Populate arrays
        uint256 publicIndex = 0;
        uint256 arrayIndex = 0;
        
        for (uint256 i = 0; i < nextEntryId && arrayIndex < returnCount; i++) {
            if (!gratitudeEntries[i].isPrivate) {
                if (publicIndex >= _offset) {
                    GratitudeEntry memory entry = gratitudeEntries[i];
                    ids[arrayIndex] = entry.id;
                    authors[arrayIndex] = entry.author;
                    contents[arrayIndex] = entry.content;
                    timestamps[arrayIndex] = entry.timestamp;
                    likes[arrayIndex] = entry.likes;
                    arrayIndex++;
                }
                publicIndex++;
            }
        }
        
        totalPublicEntries = publicCount;
    }
    
    /**
     * @dev Get user's own entries (both private and public)
     * @param _user The address of the user
     * @return Array of entry IDs belonging to the user
     */
    function getUserEntries(address _user) external view returns (uint256[] memory) {
        return userEntries[_user];
    }
    
    /**
     * @dev Get entry details by ID (only if public or owned by caller)
     * @param _entryId The ID of the entry
     * @return Entry details
     */
    function getEntry(uint256 _entryId) external view validEntry(_entryId) returns (
        uint256 id,
        address author,
        string memory content,
        uint256 timestamp,
        bool isPrivate,
        uint256 likes
    ) {
        GratitudeEntry memory entry = gratitudeEntries[_entryId];
        
        require(!entry.isPrivate || entry.author == msg.sender, "Cannot view private entry");
        
        return (
            entry.id,
            entry.author,
            entry.content,
            entry.timestamp,
            entry.isPrivate,
            entry.likes
        );
    }
    
    /**
     * @dev Get total number of entries by a user
     * @param _user The address of the user
     * @return Number of entries
     */
    function getUserEntryCount(address _user) external view returns (uint256) {
        return userEntries[_user].length;
    }
}
