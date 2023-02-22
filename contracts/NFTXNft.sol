// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import { NFTXInventoryStaking } from "./solidity/NFTXInventoryStaking.sol";
import { NFTXVaultUpgradeable } from "./solidity/NFTXVaultUpgradeable.sol";
import { NFTXVaultFactoryUpgradeable } from "./solidity/NFTXVaultFactoryUpgradeable.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract NFTXNft is ERC721 {
    
    ERC721 public collection;
    NFTXInventoryStaking public iStaking;
    NFTXVaultFactoryUpgradeable public factory;

    uint256 public maxLPTokens;

    constructor(
        address _collection,
        address _inventoryStaking,
        address _vaultFactory
    ) ERC721(ERC721(_collection).name(), ERC721(_collection).symbol()) {
        collection = ERC721(_collection);
        iStaking = NFTXInventoryStaking(_inventoryStaking);
        factory = NFTXVaultFactoryUpgradeable(_vaultFactory);
    }

    function depositXToken(
        uint256 _vaultId, 
        uint256 _amount, 
        uint256[] calldata _lpTokenIds
    ) external {
        address vault = address(iStaking.vaultXToken(_vaultId));
        address NFT = NFTXVaultUpgradeable(vault).assetAddress();
        address baseToken = factory.vault(_vaultId);
        ERC20Upgradeable xToken = ERC20Upgradeable(iStaking.xTokenAddr(baseToken));
        uint256 length = _lpTokenIds.length;
        require(NFT == address(collection), "Collections don't match");
        require(_amount == length, "Deposit amount and mint amount don't last");
        require(xToken.balanceOf(msg.sender) == _amount, "Insufficient balance");
        for(uint256 i = 0; i < length; i++) {
            _mint(msg.sender, _lpTokenIds[i]);
        }
        xToken.transferFrom(msg.sender, address(this), _lpTokenIds.length);
    }

    function redeemXToken(
        uint256 _vaultId,
        uint256[] calldata _lpTokenIds
    ) external {
        address baseToken = factory.vault(_vaultId);
        ERC20Upgradeable xToken = ERC20Upgradeable(iStaking.xTokenAddr(baseToken));
        uint256 length = _lpTokenIds.length;
        for(uint256 i = 0; i < length; i++) {
            require(ownerOf(_lpTokenIds[i]) == msg.sender, "Not your lp token");
            _burn(_lpTokenIds[i]);
        }
        xToken.transferFrom(address(this), msg.sender, _lpTokenIds.length);
    }

    function depositSLPToken(
        uint256 vaultId,
        uint256 _amount,
        uint256[] calldata _lpTokenIds
    ) external {
        
    }

    function redeemSLP(

    ) external {

    }
}
