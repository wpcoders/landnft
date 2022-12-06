// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract CraftdefiSLands {
    function safeMint(address to, uint256 x, uint256 y,uint256 zoneIndex) public virtual;
    function zoneSizeWidth() public virtual pure returns(uint256);
    function zoneSizeLength() public virtual pure returns(uint256);
    function zoneAvailableCount() public virtual view returns(uint256);
    function isOwnership(uint256 x,uint256 y,uint16 zoneIndex) external virtual view returns(bool);
}

abstract contract WhitelistContract is ERC721 {}

contract LandSale is Ownable{
    using SafeMath for uint256;
    uint256 public PRICE = 10000000000000000;
    IERC20 public token; 
    CraftdefiSLands public land;
    WhitelistContract public wl;
    uint256 public cooldownPeriod;
    address private withdrawalWallet;
    mapping(uint256 => bool) public whitelistClaimed;
    mapping(address => uint256) public lastBoughtAt;
    mapping(uint16 => bool) public saleFlag;
    mapping(uint16 => bool) public whitelistSaleFlag;

    //------------------------------ Admin Functions ------------------------------//

    function setSalePrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyOwner {
        cooldownPeriod = _cooldownPeriod;
    } 

    function setToken(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }

    function setLandContract(address _contractAddress) external onlyOwner {
        land = CraftdefiSLands(_contractAddress);
    }

    function setWhitelistContract(address _wlContractAddress) external onlyOwner {
        wl = WhitelistContract(_wlContractAddress);
    }

    function setSaleState(uint16[] memory zoneIndexes, bool state) external onlyOwner {
        uint256 len = zoneIndexes.length;
        for(uint256 i=0; i<len; i++) {
            saleFlag[zoneIndexes[i]] = state;
        }      
    }

    function setWhitelistSaleState(uint16[] memory zoneIndexes, bool state) external onlyOwner {
        uint256 len = zoneIndexes.length;
        for(uint256 i=0; i<len; i++) {
            whitelistSaleFlag[zoneIndexes[i]] = state;
        } 
    }

    function setWithdrawalWallet(address _withdrawalWallet) external onlyOwner {
        withdrawalWallet = _withdrawalWallet;
    }

    function withdraw() external onlyOwner {
        uint256 bal = token.balanceOf(address(this));
        require(bal > 0, "Insufficient balance in contract");
        token.transfer(withdrawalWallet, bal);
    }

    //------------------------------ Public Functions ------------------------------//

    function mintLand(uint256 x, uint256 y, uint16 zoneIndex) public {
        require(saleFlag[zoneIndex], "Sale for given zoneIndex is not active");
        require(x >= 0 && x < land.zoneSizeWidth(), "Incorrect x coordinate");
        require(y >= 0 && y < land.zoneSizeWidth(), "Incorrect y coordinate");
        require(zoneIndex >=1 && zoneIndex <= land.zoneAvailableCount(), "Incorrect zoneIndex");
        require(!land.isOwnership(x, y, zoneIndex),"This land is not available for sale");
        require(lastBoughtAt[msg.sender].add(cooldownPeriod) < block.timestamp,"Wait till the cooldown Periodexpires to buy new Land");
        require(token.balanceOf(msg.sender) >= PRICE, "Insufficient balance to buy land");
        token.transferFrom(msg.sender, address(this), PRICE);
        land.safeMint(msg.sender, x, y, zoneIndex);
        lastBoughtAt[msg.sender] = block.timestamp;
    }

    function whitelistMintLand(uint256 tokenId, uint256 x, uint256 y, uint16 zoneIndex) public {
        require(whitelistSaleFlag[zoneIndex], "Whitelist sale for given zoneIndex is not active");
        require(x >= 0 && x < land.zoneSizeWidth(), "Incorrect x coordinate");
        require(y >= 0 && y < land.zoneSizeWidth(), "Incorrect y coordinate");
        require(zoneIndex >=1 && zoneIndex <= land.zoneAvailableCount(), "Incorrect zoneIndex");
        require(!land.isOwnership(x, y, zoneIndex),"This land is not available for sale");
        require(msg.sender == wl.ownerOf(tokenId),"User does not hold whitelist pass");
        require(!whitelistClaimed[tokenId],"Land already claimed for this whitelist pass");
        require(token.balanceOf(msg.sender) >= PRICE, "Insufficient balance to buy land");
        token.transferFrom(msg.sender, address(this), PRICE);
        land.safeMint(msg.sender, x, y, zoneIndex);
        whitelistClaimed[tokenId] = true;
    }    
   
}