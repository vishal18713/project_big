// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MyNFTCollection is ERC1155 {
    uint256 public currentTokenID = 0;
    address public contractOwner;

    // Mapping from token ID to total supply (remaining fractions)
    mapping(uint256 => uint256) public tokenSupply;

    // Mapping from token ID to the URI of the token
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from token ID to the artist (creator)
    mapping(uint256 => address) public tokenCreator;

    // Mapping from token ID to fractional ownership
    mapping(uint256 => mapping(address => uint256)) public fractionalOwnership;

    // Mapping from token ID to total fractional amount (in wei)
    mapping(uint256 => uint256) public totalFractionalAmount;

    // Mapping from token ID to the amount of funds collected
    mapping(uint256 => uint256) public fundsCollected;

    //address[] public participants;
    mapping(uint256 => address[]) public count ;
    mapping(uint256 => uint256) public countoftotalsupply;
    

    event NFTMinted(uint256 indexed tokenId, address indexed creator, uint256 totalSupply, uint256 totalFractionalAmount);
    event RevenueDistributed(uint256 indexed tokenId, uint256 amount);
    event FundsAdded(uint256 indexed tokenId, uint256 amount);
    event StakePurchased(uint256 indexed tokenId, address indexed buyer, uint256 tokensPurchased, uint256 amountPaid);

    constructor(string memory baseURI) ERC1155(baseURI) {
        contractOwner = msg.sender;
    }

    // Mint a new NFT representing a song with fractional ownership
    function mintNFT(uint256 _totalSupply, string memory _uri, uint256 _totalFractionalAmount) external {
        uint256 _id = currentTokenID;
        _mint(msg.sender, _id, _totalSupply, ""); // Mint one NFT with total supply representing fractions
        _setTokenURI(_id, _uri);
        tokenSupply[_id] = _totalSupply;
        countoftotalsupply[_id] = _totalSupply;
        tokenCreator[_id] = msg.sender;
        totalFractionalAmount[_id] = _totalFractionalAmount;
        fundsCollected[_id] = 0; // Initialize funds collected to 0
        currentTokenID++;

        emit NFTMinted(_id, msg.sender, _totalSupply, _totalFractionalAmount);
    }

    // Set the URI for a specific token ID
    function _setTokenURI(uint256 tokenId, string memory _uri) internal {
        _tokenURIs[tokenId] = _uri;
    }

    // Override the uri function to return the correct metadata URI
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }
    

    // Buy stakes in an NFT by specifying the number of tokens
    function buyStake(uint256 tokenId) external payable {
        uint256 availableFraction = tokenSupply[tokenId]; // Get the available fractions for the tokenId
        require(availableFraction > 0, "No fractional ownership available");
        require( availableFraction>=1, "Not enough fractional ownership available");

        uint256 pricePerToken = totalFractionalAmount[tokenId] / tokenSupply[tokenId];
        uint256 requiredAmount = pricePerToken ;
        

        // Ensure enough ETH is sent (should be handled by the front-end)
        require(msg.value >= requiredAmount, "Incorrect amount of ETH sent");

        // Update ownership and collected funds

        if(fractionalOwnership[tokenId][msg.sender]==0){
            count[tokenId].push(msg.sender);
        }
        fractionalOwnership[tokenId][msg.sender]++;
        fundsCollected[tokenId] += msg.value;
        tokenSupply[tokenId]--;

        emit StakePurchased(tokenId, msg.sender, 1 , requiredAmount);

        // If all fractions are sold, transfer funds to the artist
        if (tokenSupply[tokenId] == 0) {
            address artist = tokenCreator[tokenId];
            uint256 amountToTransfer = fundsCollected[tokenId];
            fundsCollected[tokenId] = 0;
            payable(artist).transfer(amountToTransfer);
        }
        
    }

    // Distribute revenue to all token holders based on their fractional ownership
    function distributeRevenue(uint256 tokenId) public payable {
        uint256 totalSupply = totalFractionalAmount[tokenId];
        require(totalSupply > 0, "Token supply must be greater than zero");

        uint256 amountToDistribute = address(this).balance;
        require(amountToDistribute > 0, "No revenue to distribute");

        uint256 totalFraction = countoftotalsupply[tokenId];
        require(totalFraction > 0, "No fractions sold");

        for(uint256 i = 0; i<count[tokenId].length; i++){
            address reciever = count[tokenId][i];

            uint256 holderFraction = fractionalOwnership[tokenId][reciever];
            if (holderFraction > 0) {
                uint256 share = (amountToDistribute * holderFraction) / totalFraction;
                payable(reciever).transfer(share);
            }

            
        }
        // for (uint256 i = 0; i < totalSupply; i++) {
        //     address holder = address(uint160(i)); // Simplified example, should be replaced with actual holders
        //     uint256 holderFraction = fractionalOwnership[tokenId][holder];
        //     if (holderFraction > 0) {
        //         uint256 share = (amountToDistribute * holderFraction) / totalFraction;
        //         payable(holder).transfer(share);
        //     }
        // }

        emit RevenueDistributed(tokenId, amountToDistribute);
    }

    // Function for the owner to add funds to a specific NFT
    function addFundsToNFT(uint256 tokenId) public payable onlyOwner {
        require(totalFractionalAmount[tokenId] > 0, "NFT does not exist");
        require(msg.value > 0, "No funds provided");

        emit FundsAdded(tokenId, msg.value);

        //distributeRevenue(tokenId);
    }

    // Burn (destroy) a portion of the NFT's tokens
    function burnNFT(uint256 tokenId, uint256 amount) external {
        require(fractionalOwnership[tokenId][msg.sender] >= amount, "Insufficient balance to burn");
        fractionalOwnership[tokenId][msg.sender] -= amount;
    }

    // Withdraw any leftover funds from the contract
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(contractOwner).transfer(balance);
    }

    modifier onlyOwner {
        require(msg.sender == contractOwner, "Not the owner");
        _;
    }

    // Fallback function to accept ether
    receive() external payable {}

    fallback() external payable {}
}