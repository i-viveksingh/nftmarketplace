// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTMarketplace is ERC721 {
    using SafeMath for uint256;

    address payable public owner;
    uint256 public fee;
    uint256 public tokenId;

    struct NFT {
        address payable seller;
        address payable buyer;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => NFT) public nfts;

    event NFTAdded(uint256 tokenId, address seller, uint256 price);
    event NFTSold(uint256 tokenId, address seller, address buyer, uint256 price);

    constructor(string memory _name, string memory _symbol, uint256 _fee) ERC721(_name, _symbol) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    function addNFT(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        nfts[_tokenId] = NFT(payable(msg.sender), payable(address(0)), _price, false);
        emit NFTAdded(_tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _tokenId) public payable {
        NFT memory nft = nfts[_tokenId];
        require(!nft.sold, "NFT is already sold");
        require(msg.sender != nft.seller, "You cannot buy your own NFT");
        require(msg.value >= nft.price, "Insufficient payment");
                uint256 sellerShare = nft.price.mul(100 - fee).div(100);
        uint256 ownerShare = nft.price.sub(sellerShare);
        nft.buyer = payable(msg.sender);
        nft.seller.transfer(sellerShare);
        owner.transfer(ownerShare);
        nft.sold = true;
        _transfer(nft.seller, msg.sender, _tokenId);
        emit NFTSold(_tokenId, nft.seller, nft.buyer, nft.price);
    }

    function setFee(uint256 _fee) public {
        require(msg.sender == owner, "Only the owner can set the fee");
        require(_fee <= 100, "Fee cannot exceed 100%");
        fee = _fee;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
}
