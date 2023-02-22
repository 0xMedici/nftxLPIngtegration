// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import { NFTXInventoryStaking } from "./solidity/NFTXInventoryStaking.sol";
import { NFTXVaultUpgradeable } from "./solidity/NFTXVaultUpgradeable.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract NFTXNft is ERC721 {
    
    ERC721 public collection;
    NFTXInventoryStaking public iStaking;

    uint256 public maxLPTokens;

    constructor(
        address _collection,
        address _inventoryStaking
    ) ERC721(ERC721(_collection).name(), ERC721(_collection).symbol()) {
        collection = ERC721(_collection);
        iStaking = NFTXInventoryStaking(_inventoryStaking);
    }

    function depositXToken(
        uint256 _vaultId, 
        uint256 _amount, 
        uint256[] calldata _lpTokenIds
    ) external {
        // getting vault address for confirming NFT address and vaultId match
        // NFTXInventoryStaking.vaultXToken(vaultId)
        address vault = address(iStaking.vaultXToken(_vaultId));

        // getting actual NFT address 
        address NFT = NFTXVaultUpgradeable(vault).assetAddress();
        // NFTXVaultUpgradeable.assetAddress()
        // check NFT address = collection address variable
        require(NFT == address(collection), "Collections don't match");

        // if all passes make sure amount is mod 1
        // custody token amount
        uint256 length = _lpTokenIds.length;
        require(_amount == length, "Deposit amount and mint amount don't last");
        for(uint256 i = 0; i < length; i++) {
            // mint _lpTokenIds
            _mint(msg.sender, _lpTokenIds[i]);
        }
    }

    function depositSLPToken(
        uint256 vaultId,
        uint256 _amount,
        uint256[] calldata _lpTokenIds
    ) external {
        
    }
}
