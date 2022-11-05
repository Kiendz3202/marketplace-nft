// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct NFTListing {
    uint256 price;
    address seller;
}

contract Marketplace is ERC721URIStorage, Ownable {
    IERC20 public wanakaToken;
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIDs;
    mapping(uint256 => NFTListing) private _listings;

    // if tokenURI is not an empty string => an NFT was created
    // if price is not 0 => an NFT was listed
    // if price is 0 && tokenURI is an empty string => NFT was transferred (either bought, or the listing was canceled)
    event NFTTransfer(
        uint256 tokenID,
        address from,
        address to,
        string tokenURI,
        uint256 price
    );

    constructor(address _tokenAddress) ERC721("Abdou's NFTs", "ANFT") {
        wanakaToken = IERC20(_tokenAddress);
    }

    function createNFT(string calldata tokenURI) public {
        _tokenIDs.increment();
        uint256 currentID = _tokenIDs.current();
        _safeMint(msg.sender, currentID);
        _setTokenURI(currentID, tokenURI);
        emit NFTTransfer(currentID, address(0), msg.sender, tokenURI, 0);
    }

    //seller list nft on marketplace
    function listNFT(uint256 tokenID, uint256 price) public {
        require(price > 0, "NFTMarket: price must be greater than 0");
        transferFrom(msg.sender, address(this), tokenID);
        _listings[tokenID] = NFTListing(price, msg.sender);
        emit NFTTransfer(tokenID, msg.sender, address(this), "", price);
    }

    function buyNFT(uint256 tokenID, uint256 _price) public payable {
        NFTListing memory listing = _listings[tokenID];

        require(listing.price > 0, "NFTMarket: nft not listed for sale");
        require(_price == listing.price, "NFTMarket: incorrect price");

        ERC721(address(this)).transferFrom(address(this), msg.sender, tokenID);
        clearListing(tokenID);

        wanakaToken.approve(address(this), 1000000 * 10**18);

        //token from buyer send 95% to seller and 5% to marketplace contract
        for (uint i = 0; i <= 1; i++) {
            if (i == 0) {
                wanakaToken.transferFrom(
                    msg.sender,
                    listing.seller,
                    listing.price.mul(95).div(100)
                );
            } else {
                wanakaToken.transferFrom(
                    msg.sender,
                    address(this),
                    listing.price.mul(5).div(100)
                );
            }
        }
        emit NFTTransfer(tokenID, address(this), msg.sender, "", 0);
    }

    //seller cancel nft that is listed in marketplace
    function cancelListing(uint256 tokenID) public {
        NFTListing memory listing = _listings[tokenID];
        require(listing.price > 0, "NFTMarket: nft not listed for sale");
        require(
            listing.seller == msg.sender,
            "NFTMarket: you're not the seller"
        );
        ERC721(address(this)).transferFrom(address(this), msg.sender, tokenID);
        clearListing(tokenID);
        emit NFTTransfer(tokenID, address(this), msg.sender, "", 0);
    }

    //withdraw all token from marketplace contract to marketplace's signer
    function withdrawFunds() public onlyOwner {
        uint256 balance = wanakaToken.balanceOf(address(this));
        require(balance > 0, "NFTMarket: balance is zero");
        wanakaToken.transferFrom(address(this), msg.sender, balance);
    }

    function clearListing(uint256 tokenID) private {
        _listings[tokenID].price = 0;
        _listings[tokenID].seller = address(0);
    }
}
