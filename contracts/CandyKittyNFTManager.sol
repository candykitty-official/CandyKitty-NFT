// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface CandyKittyNFT is IERC721{
    function mintToMarketplace(address _to, uint256 _quantity) external;
}

contract CandyKittyNFTManager is Ownable {

    // galler market
    uint256 public LAUNCH_MAX_SUPPLY;    // max launch supply
    uint256 public LAUNCH_SUPPLY;        // current launch supply

    address public LAUNCHPAD;
    address public candyKittyNft;

    constructor(
        address _candykitty,
        address _launchpad,
        uint256 _launchpadMaxSupply
    ) {
        require(_launchpad != address(0), "CandyKittyNFTManager: launchpad is zero address");

        candyKittyNft = _candykitty;
        LAUNCHPAD = _launchpad;
        LAUNCH_MAX_SUPPLY = _launchpadMaxSupply;
    }

    modifier onlyLaunchpad() {
        require(LAUNCHPAD != address(0), "launchpad address must set");
        require(msg.sender == LAUNCHPAD, "must call by launchpad");
        _;
    }

    function getMaxLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_MAX_SUPPLY;
    }

    function getLaunchpadSupply() view public returns (uint256) {
        return LAUNCH_SUPPLY;
    }

    function mintTo(address to, uint size) external onlyLaunchpad {
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(LAUNCH_SUPPLY + size <= LAUNCH_MAX_SUPPLY, "max supply reached");

        CandyKittyNFT(candyKittyNft).mintToMarketplace(to, size);
        LAUNCH_SUPPLY += size;
    }

    function setLaunchpad(uint256 _maxSupply, address _launchpad) external onlyOwner {
        LAUNCH_MAX_SUPPLY = _maxSupply;
        LAUNCHPAD = _launchpad;
    }

    function setCandyKitty(address _candyKittyNft) external onlyOwner {
        candyKittyNft = _candyKittyNft;
    }

    // pre-mint nft to NFT Marketplace
    function mintToMarket(address _to, uint256 _quantity) external onlyOwner {
        CandyKittyNFT(candyKittyNft).mintToMarketplace(_to, _quantity);
    } 

}