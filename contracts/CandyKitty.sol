// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CandyKitty is Ownable, ERC721, AccessControl {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Whitelist,
        FreeMint,
        Finished
    }

    Status public status;

    string public baseURI;
    string public defaultURI;
    uint256 public tokenIdx = 1000;
    uint256 public maxSupply = 10000;

    uint256 public preSalePrice;
    uint256 public publicSalePrice;

    mapping(bytes32 => bool) public usedMessages;
    address public signerAddress;

    event WhitelistMint(address to, uint256 tokenId);
    event NestingOpened(bool open);
    event NewSignerAddress(address newSigner);
    event NewStatus(Status status);
    event NewPrice(uint256 preSalePrice, uint256 publicSalePrice);
    event NewBaseURI(string uri);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _defaultURI,
        uint256 _preSalePrice,
        uint256 _publicSalePrice,
        address _signerAddress
    ) ERC721(_name, _symbol) {
        defaultURI = _defaultURI;
        status = Status.Pending;
        preSalePrice = _preSalePrice;
        publicSalePrice = _publicSalePrice;
        signerAddress = _signerAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function preSaleMint(address _to, uint256 _quantity, bytes32 _nonce, bytes calldata _sig) external payable {
        require(status == Status.PreSale, "not in presale mint period");
        require(_quantity > 0, "_quantity must greater than zero");
        require(tokenIdx + _quantity <= maxSupply, "exceed max mint amount");
        require(msg.value == _quantity*preSalePrice, "insufficient value");
        requireValidSignature(_to, _nonce, _sig);
        _batchMint(_to, _quantity);
    }

    function publicMint(address _to,  uint256 _quantity) external payable {
        require(status == Status.PublicSale, "not in public sale mint period");
        require(_quantity > 0, "_quantity must greater than zero");
        require(tokenIdx + _quantity <= maxSupply, "exceed max mint amount");
        require(msg.value == _quantity*publicSalePrice, "insufficient value");
        _batchMint(_to, _quantity);
    }

    function freeMint(address _to, bytes32 _nonce, bytes calldata _sig) external {
        require(status == Status.FreeMint, "not in free mint period");
        require(tokenIdx + 1 <= maxSupply, "exceed max mint amount");
        requireValidSignature(_to, _nonce, _sig);
        _batchMint(_to, 1);
    }

    function _batchMint(address _to, uint256 _quantity) internal {
        for (uint256 idx = 0; idx < _quantity; idx++) {
            tokenIdx++;
            _safeMint(_to, tokenIdx, "");
        }
    }

    function whitelistMint( address _to, uint256[] calldata _tokenIds, bytes32 _nonce, bytes calldata _sig) external payable {
        require(status == Status.Whitelist, "not in whitelist mint period");
        bytes memory bNonce = new bytes((_tokenIds.length+1)*32);
        for (uint256 idx = 0; idx < _tokenIds.length; idx++) {
            uint256 tokenId = _tokenIds[idx];
            require(tokenId <= 1000 && tokenId > 0, "incorrect tokenId");
            assembly { mstore(add(bNonce, add(0x20, mul(idx, 0x20))), tokenId) }
        }
        assembly { mstore(add(bNonce, mul(add(_tokenIds.length, 1), 32)), _nonce) }

        requireValidSignature(_to, keccak256(bNonce), _sig);

        for (uint256 idx = 0; idx < _tokenIds.length; idx++) {
            _safeMint(_to, _tokenIds[idx], "");
            emit WhitelistMint(_to, _tokenIds[idx]);
        }
    }

    function mintToMarketplace(address _to, uint256 _quantity) public onlyRole(MANAGER_ROLE) {
        require(tokenIdx + _quantity <= maxSupply, "exceed max mint amount");
        _batchMint(_to, _quantity);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function alreadyMinted(address _to, bytes32 _nonce) external view returns (bool) {
        return usedMessages[ECDSA.toEthSignedMessageHash(abi.encodePacked(_to, _nonce))];
    }

    function setSignerAddress(address _newSigner) external onlyOwner {
        signerAddress = _newSigner;
        emit NewSignerAddress(_newSigner);
    }

    function requireValidSignature(address _to, bytes32 _nonce, bytes memory _sig) internal {
        bytes32 message = ECDSA.toEthSignedMessageHash(abi.encodePacked(_to, _nonce));
        require(!usedMessages[message], "SignatureChecker: Message already used");
        usedMessages[message] = true;
        address signer = ECDSA.recover(message, _sig);
        require(signer != address(0x00), "signer cannot be zero address");
        require(signer == signerAddress, "SignatureChecker: Invalid signature");
    }

    mapping(uint256 => uint256) private nestingStarted;
    mapping(uint256 => uint256) private nestingTotal;

    uint256 private nestingTransfer = 1;

    bool public nestingOpen = false;

    event Nested(uint256 indexed tokenId);
    event Unnested(uint256 indexed tokenId);
    event Expelled(uint256 indexed tokenId);

    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total) {
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = current + nestingTotal[tokenId];
    }

    function safeTransferWhileNesting(address from, address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "CandyKitty: Only owner");
        nestingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        nestingTransfer = 1;
    }

    function _beforeTokenTransfer(address, address, uint256 tokenId) internal view override {
        require(nestingStarted[tokenId] == 0 || nestingTransfer == 2, "CandyKitty: nesting");
    }

    function setNestingOpen(bool open) external onlyOwner {
        nestingOpen = open;
        emit NestingOpened(open);
    }

    function toggleNesting(uint256 tokenId) internal {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");
        uint256 start = nestingStarted[tokenId];
        if (start == 0) {
            require(nestingOpen, "CandyKitty: nesting closed");
            nestingStarted[tokenId] = block.timestamp;
            emit Nested(tokenId);
        } else {
            nestingTotal[tokenId] += block.timestamp - start;
            nestingStarted[tokenId] = 0;
            emit Unnested(tokenId);
        }
    }

    function toggleNesting(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleNesting(tokenIds[i]);
        }
    }

    function expelFromNest(uint256 tokenId) external onlyOwner {
        require(nestingStarted[tokenId] != 0, "CandyKitty: not nested");
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        nestingStarted[tokenId] = 0;
        emit Unnested(tokenId);
        emit Expelled(tokenId);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (bytes(baseURI).length == 0) {
            return defaultURI;
        }
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function setBaseURI(string memory _uri) public onlyOwner returns(bool) {
        baseURI = _uri;
        emit NewBaseURI(_uri);
        return true;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit NewStatus(_status);
    }

    function setPrice(uint256 _preSalePrice, uint256 _publicSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
        publicSalePrice = _publicSalePrice;
        emit NewPrice(_preSalePrice, _publicSalePrice);
    }

    function withdraw(address payable _recipient, IERC20 _token) external onlyOwner returns(bool) {
        require(_recipient != address(0x00), "recipient is zero address");
        if (address(_token) == address(0x00)) {
            uint256 balance = address(this).balance;
            _recipient.transfer(balance);
        } else {
            uint256 balance = _token.balanceOf(address(this));
            _token.safeTransfer(_recipient, balance);
        }
        return true;
    }
}