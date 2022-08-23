// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CandyKittyBatchTransfer is Ownable {

    address public candyKittyNft;

    constructor(
        address _candykitty
    ) {
        require(_candykitty != address(0), "CandyKittyBatchTransfer: _candykitty is zero address");
        candyKittyNft = _candykitty;
    }

    function batchTransferByIds(address _from, address _to, uint256[] calldata _tokenIds) external {
        for (uint256 idx = 0; idx < _tokenIds.length; idx++) {
            IERC721(candyKittyNft).safeTransferFrom(_from, _to, _tokenIds[idx]);
        }
    }

    function batchTransferByIndex(address _from, address _to, uint256 _tokenIdBegin, uint256 _tokenIdEnd) external {
        for (uint256 idx = _tokenIdBegin; idx <= _tokenIdEnd; idx++) {
            IERC721(candyKittyNft).safeTransferFrom(_from, _to, idx);
        }
    }

    function setCandyKitty(address _candyKittyNft) external onlyOwner {
        candyKittyNft = _candyKittyNft;
    }
}


