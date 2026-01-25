// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFTMarketplaceV3
 * @dev Decentralized NFT marketplace with listings, offers, and royalties
 * @author Adekunle Bamz
 * @notice NEW V3 CONTRACT - Buy, sell, and trade NFTs
 * 
 * FEATURES:
 *   - List NFTs for fixed price
 *   - Make offers on any NFT
 *   - Accept/reject offers
 *   - Automatic royalty distribution
 *   - Auction support
 *   - Platform fees
 */
contract NFTMarketplaceV3 is Ownable, ReentrancyGuard {
    
    string public constant VERSION = "3.0.0";
    
    /// @dev Listing info
    struct Listing {
        address seller;
        uint256 price;
        uint256 listedAt;
        bool active;
    }
    
    /// @dev Offer info
    struct Offer {
        address buyer;
        uint256 amount;
        uint256 expiresAt;
        bool active;
    }
    
    /// @dev Auction info
    struct Auction {
        address seller;
        uint256 startPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    /// @dev NFT contract reference
    IERC721 public nftContract;
    
    /// @dev Royalty contract for fee lookup
    address public royaltyContract;
    
    /// @dev Platform fee (basis points, 250 = 2.5%)
    uint256 public platformFee = 250;
    
    /// @dev Platform fee recipient
    address public feeRecipient;
    
    /// @dev Listings: tokenId => Listing
    mapping(uint256 => Listing) public listings;
    
    /// @dev Offers: tokenId => offerer => Offer
    mapping(uint256 => mapping(address => Offer)) public offers;
    
    /// @dev All offers for a token
    mapping(uint256 => address[]) public tokenOffers;
    
    /// @dev Auctions: tokenId => Auction
    mapping(uint256 => Auction) public auctions;
    
    /// @dev User stats
    mapping(address => uint256) public totalSales;
    mapping(address => uint256) public totalPurchases;

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Delisted(uint256 indexed tokenId, address indexed seller);
    event PriceUpdated(uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event OfferMade(uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 expiresAt);
    event OfferCancelled(uint256 indexed tokenId, address indexed buyer);
    event OfferAccepted(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 amount);
    event AuctionCreated(uint256 indexed tokenId, address indexed seller, uint256 startPrice, uint256 endTime);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 amount);
    event AuctionCancelled(uint256 indexed tokenId);

    error NotTokenOwner();
    error NotListed();
    error AlreadyListed();
    error InsufficientPayment();
    error InvalidPrice();
    error OfferExpired();
    error NoActiveOffer();
    error AuctionActive();
    error AuctionNotActive();
    error AuctionNotEnded();
    error BidTooLow();
    error CannotBidOwnAuction();

    constructor(address _nftContract) Ownable(msg.sender) {
        nftContract = IERC721(_nftContract);
        feeRecipient = msg.sender;
    }

    // ============ LISTINGS ============

    function list(uint256 tokenId, uint256 price) external nonReentrant {
        if (nftContract.ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (listings[tokenId].active) revert AlreadyListed();
        if (auctions[tokenId].active) revert AuctionActive();
        if (price == 0) revert InvalidPrice();
        
        // Must have approval
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)) ||
            nftContract.getApproved(tokenId) == address(this),
            "NFTMarketplaceV3: Not approved"
        );
        
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            listedAt: block.timestamp,
            active: true
        });
        
        emit Listed(tokenId, msg.sender, price);
    }

    function delist(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        if (!listing.active) revert NotListed();
        if (listing.seller != msg.sender && msg.sender != owner()) revert NotTokenOwner();
        
        listing.active = false;
        emit Delisted(tokenId, listing.seller);
    }

    function updatePrice(uint256 tokenId, uint256 newPrice) external {
        Listing storage listing = listings[tokenId];
        if (!listing.active) revert NotListed();
        if (listing.seller != msg.sender) revert NotTokenOwner();
        if (newPrice == 0) revert InvalidPrice();
        
        uint256 oldPrice = listing.price;
        listing.price = newPrice;
        
        emit PriceUpdated(tokenId, oldPrice, newPrice);
    }

    function buy(uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[tokenId];
        if (!listing.active) revert NotListed();
        if (msg.value < listing.price) revert InsufficientPayment();
        
        address seller = listing.seller;
        uint256 price = listing.price;
        
        // Mark as sold
        listing.active = false;
        
        // Transfer NFT
        nftContract.transferFrom(seller, msg.sender, tokenId);
        
        // Distribute funds
        _distributeFunds(tokenId, seller, price);
        
        // Update stats
        totalSales[seller]++;
        totalPurchases[msg.sender]++;
        
        emit Sold(tokenId, seller, msg.sender, price);
    }

    // ============ OFFERS ============

    function makeOffer(uint256 tokenId, uint256 expiresIn) external payable nonReentrant {
        require(msg.value > 0, "NFTMarketplaceV3: Zero offer");
        require(expiresIn >= 1 hours, "NFTMarketplaceV3: Min 1 hour");
        
        uint256 expiresAt = block.timestamp + expiresIn;
        
        // Refund any existing offer
        Offer storage existing = offers[tokenId][msg.sender];
        if (existing.active && existing.amount > 0) {
            payable(msg.sender).transfer(existing.amount);
        }
        
        offers[tokenId][msg.sender] = Offer({
            buyer: msg.sender,
            amount: msg.value,
            expiresAt: expiresAt,
            active: true
        });
        
        // Track offer
        tokenOffers[tokenId].push(msg.sender);
        
        emit OfferMade(tokenId, msg.sender, msg.value, expiresAt);
    }

    function cancelOffer(uint256 tokenId) external nonReentrant {
        Offer storage offer = offers[tokenId][msg.sender];
        if (!offer.active) revert NoActiveOffer();
        
        uint256 refund = offer.amount;
        offer.active = false;
        offer.amount = 0;
        
        payable(msg.sender).transfer(refund);
        
        emit OfferCancelled(tokenId, msg.sender);
    }

    function acceptOffer(uint256 tokenId, address buyer) external nonReentrant {
        if (nftContract.ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        
        Offer storage offer = offers[tokenId][buyer];
        if (!offer.active) revert NoActiveOffer();
        if (block.timestamp > offer.expiresAt) revert OfferExpired();
        
        uint256 amount = offer.amount;
        offer.active = false;
        offer.amount = 0;
        
        // Delist if listed
        if (listings[tokenId].active) {
            listings[tokenId].active = false;
        }
        
        // Transfer NFT
        nftContract.transferFrom(msg.sender, buyer, tokenId);
        
        // Distribute funds
        _distributeFunds(tokenId, msg.sender, amount);
        
        // Update stats
        totalSales[msg.sender]++;
        totalPurchases[buyer]++;
        
        emit OfferAccepted(tokenId, msg.sender, buyer, amount);
    }

    // ============ AUCTIONS ============

    function createAuction(uint256 tokenId, uint256 startPrice, uint256 duration) external nonReentrant {
        if (nftContract.ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (listings[tokenId].active) revert AlreadyListed();
        if (auctions[tokenId].active) revert AuctionActive();
        
        require(duration >= 1 hours && duration <= 7 days, "NFTMarketplaceV3: Invalid duration");
        
        // Transfer NFT to marketplace (escrow)
        nftContract.transferFrom(msg.sender, address(this), tokenId);
        
        auctions[tokenId] = Auction({
            seller: msg.sender,
            startPrice: startPrice,
            currentBid: 0,
            highestBidder: address(0),
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            active: true
        });
        
        emit AuctionCreated(tokenId, msg.sender, startPrice, block.timestamp + duration);
    }

    function bid(uint256 tokenId) external payable nonReentrant {
        Auction storage auction = auctions[tokenId];
        if (!auction.active) revert AuctionNotActive();
        if (block.timestamp > auction.endTime) revert AuctionNotActive();
        if (msg.sender == auction.seller) revert CannotBidOwnAuction();
        
        uint256 minBid = auction.currentBid > 0 
            ? auction.currentBid + (auction.currentBid / 10) // 10% increment
            : auction.startPrice;
            
        if (msg.value < minBid) revert BidTooLow();
        
        // Refund previous bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.currentBid);
        }
        
        auction.currentBid = msg.value;
        auction.highestBidder = msg.sender;
        
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) external nonReentrant {
        Auction storage auction = auctions[tokenId];
        if (!auction.active) revert AuctionNotActive();
        if (block.timestamp < auction.endTime) revert AuctionNotEnded();
        
        auction.active = false;
        
        if (auction.highestBidder != address(0)) {
            // Transfer NFT to winner
            nftContract.transferFrom(address(this), auction.highestBidder, tokenId);
            
            // Distribute funds
            _distributeFunds(tokenId, auction.seller, auction.currentBid);
            
            emit AuctionEnded(tokenId, auction.highestBidder, auction.currentBid);
        } else {
            // No bids - return NFT to seller
            nftContract.transferFrom(address(this), auction.seller, tokenId);
            emit AuctionCancelled(tokenId);
        }
    }

    function cancelAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        if (!auction.active) revert AuctionNotActive();
        if (auction.seller != msg.sender) revert NotTokenOwner();
        require(auction.highestBidder == address(0), "NFTMarketplaceV3: Has bids");
        
        auction.active = false;
        
        // Return NFT
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        
        emit AuctionCancelled(tokenId);
    }

    // ============ INTERNAL ============

    function _distributeFunds(uint256 tokenId, address seller, uint256 amount) internal {
        uint256 platformAmount = (amount * platformFee) / 10000;
        uint256 royaltyAmount = 0;
        address royaltyReceiver = address(0);
        
        // Get royalty info if contract set
        if (royaltyContract != address(0)) {
            try IERC2981(royaltyContract).royaltyInfo(tokenId, amount) returns (address receiver, uint256 royalty) {
                royaltyReceiver = receiver;
                royaltyAmount = royalty;
            } catch {}
        }
        
        uint256 sellerAmount = amount - platformAmount - royaltyAmount;
        
        // Transfer platform fee
        if (platformAmount > 0) {
            payable(feeRecipient).transfer(platformAmount);
        }
        
        // Transfer royalty
        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            payable(royaltyReceiver).transfer(royaltyAmount);
        }
        
        // Transfer to seller
        payable(seller).transfer(sellerAmount);
    }

    // ============ ADMIN ============

    function setNFTContract(address _nftContract) external onlyOwner {
        nftContract = IERC721(_nftContract);
    }

    function setRoyaltyContract(address _royaltyContract) external onlyOwner {
        royaltyContract = _royaltyContract;
    }

    function setPlatformFee(uint256 _fee) external onlyOwner {
        require(_fee <= 1000, "NFTMarketplaceV3: Max 10%");
        platformFee = _fee;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "NFTMarketplaceV3: Zero address");
        feeRecipient = _recipient;
    }

    // ============ VIEW ============

    function getListing(uint256 tokenId) external view returns (Listing memory) {
        return listings[tokenId];
    }

    function getAuction(uint256 tokenId) external view returns (Auction memory) {
        return auctions[tokenId];
    }

    function getOffers(uint256 tokenId) external view returns (address[] memory) {
        return tokenOffers[tokenId];
    }

    function getOffer(uint256 tokenId, address buyer) external view returns (Offer memory) {
        return offers[tokenId][buyer];
    }
}

interface IERC2981 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}
