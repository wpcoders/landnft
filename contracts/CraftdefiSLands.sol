// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/// @custom:security-contact contract@innova-interactive.com
contract CraftdefiSLands is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _zoneAvailableCounter;
    using StringsUpgradeable for uint256;

    uint256 internal constant  MAX_INT_NUMBER = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Our zone count is 20 zones
    uint256 internal constant ZONE_MAX_COUNT = 20;

    // Our grid is 250 x 200 lands
    uint256 internal constant ZONE_SIZE_WIDTH = 250;
    uint256 internal constant ZONE_SIZE_LENGTH = 200;
    // Our area is 25 x 20 areas
    uint256 internal constant AREA_SIZE_WIDTH = 25;
    uint256 internal constant AREA_SIZE_LENGTH = 20;

    mapping(uint256 => string) private _zoneNames;

    //Count of bits of uint256
    uint256 internal constant BIT_COUNT = 256;
    // Our bucket size is (ZONE_SIZE_WIDTH * ZONE_SIZE_LENGTH)/ BIT_COUNT equal to 196
    uint256 internal constant LAND_BUCKET_SIZE = 196;
    mapping(uint256 => mapping(uint256 => uint256)) private _map;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Craftdefi's Lands", "CLAND");
        __ERC721URIStorage_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    /// @notice add new zone
    /// @param name name of zone
    function newZone(string memory name) public onlyRole(MINTER_ROLE) {
        require(_zoneAvailableCounter.current() < ZONE_MAX_COUNT, "the amount of zone has reached.");
        _zoneAvailableCounter.increment();
        _zoneNames[_zoneAvailableCounter.current()] = name;
    }

    /// @notice get map data
    /// @param offset offset for paginate area
    /// @param limit count of return
    /// @param zoneIndex zone index
    /// @return mapBuckets
    function getMapByArea(uint256 offset,uint256 limit,uint256 zoneIndex) external view returns(uint256[] memory) {
        uint256 areaWidth = ZONE_SIZE_WIDTH/AREA_SIZE_WIDTH;
        uint256 areaLength = ZONE_SIZE_LENGTH/AREA_SIZE_LENGTH;
        uint256 areaCount =  areaWidth * areaLength;
        require(zoneIndex > 0 && zoneIndex <= _zoneAvailableCounter.current(),"this zone is not available." );
        require(offset >= 0 && offset <= areaCount,"offset is over scope." );
        require(limit > 0 && limit <= areaCount,"limit is over scope." );
        require(offset + limit <= areaCount,"pagination is over scope." );

        uint256 zone = zoneIndex;
        uint256 length = limit;
        uint256[] memory buckets = new uint256[](length*2);
        uint16 count = 0;
        for(uint256 i = offset; i < offset+limit;i++)
        {
            uint256 _bitCount = 0;
            for( uint256 y = 0; y < AREA_SIZE_LENGTH;y++)
            {
                uint256 positionY = (i / areaWidth) * AREA_SIZE_LENGTH + y;
                uint256 startPos  = (i % areaWidth) * AREA_SIZE_WIDTH + positionY * ZONE_SIZE_WIDTH;

                uint256 bucketIndex= startPos / BIT_COUNT;
                uint256 bucket = _map[zone][bucketIndex];
                uint256 bucketPos = startPos%BIT_COUNT;
                uint256 bucketPosDiff = 0;
                if (bucketPos + AREA_SIZE_WIDTH > BIT_COUNT) {
                    bucketPosDiff = bucketPos + AREA_SIZE_WIDTH - BIT_COUNT;
                }
                bucket = bucket << (BIT_COUNT - bucketPos - (AREA_SIZE_WIDTH - bucketPosDiff));
                bucket = bucket >> (BIT_COUNT - (AREA_SIZE_WIDTH - bucketPosDiff));
                bucket = bucket << _bitCount;
                buckets[count] |= bucket;
                _bitCount += AREA_SIZE_WIDTH - bucketPosDiff;
                if (_bitCount >= BIT_COUNT) {
                    _bitCount -= BIT_COUNT;
                    count++;
                }
                if (bucketPosDiff > 0)
                {
                    uint256 bucketNext = _map[zone][bucketIndex+1];
                    bucketNext = bucketNext << BIT_COUNT - bucketPosDiff;
                    bucketNext = bucketNext >> BIT_COUNT - bucketPosDiff;
                    bucketNext = bucketNext << _bitCount;
                    buckets[count] |= bucketNext;
                    _bitCount += bucketPosDiff;
                }

                if (_bitCount >= BIT_COUNT) {
                    _bitCount -= BIT_COUNT;
                    count++;
                }
            }

            count++;
            _bitCount = 0;
        }
        return buckets;
    }

    /// @notice get map data
    /// @param offset offset for paginate
    /// @param limit limit count of return
    /// @param zoneIndex zone index
    /// @return mapBuckets
    function getMap(uint256 offset,uint256 limit,uint16 zoneIndex) external view returns(uint256[] memory) {
        require(zoneIndex > 0 && zoneIndex <= _zoneAvailableCounter.current(),"this zone is not available." );
        require(offset >= 0 && offset <= LAND_BUCKET_SIZE,"offset is over scope." );
        require(limit > 0 && limit <= LAND_BUCKET_SIZE,"limit is over scope." );
        require(offset + limit <= LAND_BUCKET_SIZE,"pagination is over scope." );


        uint256 length = limit;
        uint256[] memory bucket = new uint256[](length);
        uint16 count = 0;
        for(uint256 i = offset; i < offset+limit;i++)
        {
            bucket[count] = _map[zoneIndex][i];
            count++;
        }
        return bucket;
    }

    function _setMap(uint256 tokenId,uint256 zoneIndex) internal {
        uint256 landCount = ZONE_SIZE_WIDTH * ZONE_SIZE_LENGTH;
        uint256 _tokenId = tokenId%landCount;
        uint256 bucketPosition = _tokenId % BIT_COUNT;
        uint256 bucketIndex = _tokenId/BIT_COUNT;
        _map[zoneIndex][bucketIndex] |= (1 << bucketPosition);
    }

    /// @notice Is Ownership
    /// @param x x coordinate
    /// @param y y coordinate
    /// @param zoneIndex zone index
    /// @return isOwnership
    function isOwnership(uint256 x,uint256 y,uint16 zoneIndex) external view returns(bool) {
        require(zoneIndex > 0 && zoneIndex <= _zoneAvailableCounter.current(),"zone out of bounds.");
        require( (x >= 0 && x < ZONE_SIZE_WIDTH) && (y >= 0 && y < ZONE_SIZE_LENGTH),"out of locations.");

        uint256 tokenId = (x + y * ZONE_SIZE_WIDTH);
        uint256 bucketIndex = tokenId/BIT_COUNT;
        uint256 bucket = _map[zoneIndex][bucketIndex];
        uint256 bucketPosition = 1 << (tokenId % BIT_COUNT);
        return (bucket & bucketPosition) == bucketPosition;
    }

    /// @notice get size of bucket
    /// @return bucketSize
    function bucketSize() public pure returns(uint256) {
        return LAND_BUCKET_SIZE;
    }

    /// @notice get count of bit
    /// @return bitCount
    function bitCount() public pure returns(uint256) {
        return BIT_COUNT;
    }

    /// @notice get max count of zone
    /// @return zoneMaxCount
    function zoneMaxCount() public pure returns(uint256) {
        return ZONE_MAX_COUNT;
    }

    /// @notice get current available count of zone
    /// @return zoneAvailableCount
    function zoneAvailableCount() public view returns(uint256) {
        return _zoneAvailableCounter.current();
    }

    /// @notice get zone name by index
    /// @param zoneIndex zoneIndex
    /// @return name
    function zoneNameByIndex(uint16 zoneIndex) external view returns(string memory) {
        require(zoneIndex > 0 && zoneIndex <= _zoneAvailableCounter.current(),"this zone is not available." );

        return _zoneNames[zoneIndex];
    }

    /// @notice total width of the zone
    /// @return width
    function zoneSizeWidth() public pure returns(uint256) {
        return ZONE_SIZE_WIDTH;
    }

    /// @notice total length of the zone
    /// @return length
    function zoneSizeLength() public pure returns(uint256) {
        return ZONE_SIZE_LENGTH;
    }

    /// @notice total width of the area
    /// @return width
    function areaSizeWidth() public pure returns(uint256) {
        return AREA_SIZE_WIDTH;
    }

    /// @notice total length of the area
    /// @return length
    function areaSizeLength() public pure returns(uint256) {
        return AREA_SIZE_LENGTH;
    }

    /// @notice get coordinate by tokenId
    /// @param id tokenId
    function getCoordinateByID(uint256 id) external view returns(uint256 x, uint256 y) {
        require(ownerOf(id) != address(0), "token does not exist");

        uint256 landCount = ZONE_SIZE_WIDTH * ZONE_SIZE_LENGTH;
        uint256 _id = id % landCount;
        x = _id % ZONE_SIZE_WIDTH;
        y = _id / ZONE_SIZE_WIDTH;
    }

    /// @notice get area by tokenId
    /// @param id tokenId
    /// @return area
    function getAreaByID(uint256 id) external view returns(uint256 area) {
        require(ownerOf(id) != address(0), "token does not exist");

        uint256 landCount = ZONE_SIZE_WIDTH * ZONE_SIZE_LENGTH;

        uint256 _id = id % landCount;
        
        uint256 x = _id % ZONE_SIZE_WIDTH;
        uint256 y = _id / ZONE_SIZE_WIDTH;

        uint256 areaWidth = ZONE_SIZE_WIDTH / AREA_SIZE_WIDTH;

        area = x/AREA_SIZE_WIDTH + (y/AREA_SIZE_LENGTH)*areaWidth;
    }

    /// @notice get zone by tokenId
    /// @param id tokenId
    /// @return zone
    function getZoneIndexByID(uint256 id) external view returns(uint256 zone) {
        require(ownerOf(id) != address(0), "token does not exist");

        uint256 landCount = ZONE_SIZE_WIDTH * ZONE_SIZE_LENGTH;

        zone = (id / landCount) + 1;
    }

    function safeMint(address to, uint256 x,uint256 y,uint256 zoneIndex)
        public
        onlyRole(MINTER_ROLE)
    {
        require(zoneIndex > 0 && zoneIndex <= _zoneAvailableCounter.current(),"zone out of bounds.");
        require( (x >= 0 && x < ZONE_SIZE_WIDTH) && (y >= 0 && y < ZONE_SIZE_LENGTH),"out of locations.");

        uint256 landCount = ZONE_SIZE_WIDTH * ZONE_SIZE_LENGTH;
        uint256 tokenId = (x + y * ZONE_SIZE_WIDTH) + (landCount  * (zoneIndex - 1));

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
        _setMap(tokenId, zoneIndex);
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}