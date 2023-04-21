// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import { NFTXLPStaking } from "./solidity/NFTXLPStaking.sol";
import { NFTXInventoryStaking } from "./solidity/NFTXInventoryStaking.sol";
import { NFTXVaultFactoryUpgradeable } from "./solidity/NFTXVaultFactoryUpgradeable.sol";
import { StakingTokenProvider } from "./solidity/StakingTokenProvider.sol";
import { NFTXNft } from "./NFTXNft.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Factory {

    address public admin;
    address public iStaking;
    address public lpStaking;
    address public vaultFactory;
    address public provider;

    mapping(address => bool) public whitelistedCreators;
    mapping(address => address) public nftxNfts;

    event NFTXNftCreated(address nftxNft);

    constructor(
        address _admin,
        address _inventoryStaking,
        address _lpStaking,
        address _vaultFactory,
        address _provider
    ) {
        admin = _admin;
        iStaking = _inventoryStaking;
        lpStaking = _lpStaking;
        vaultFactory = _vaultFactory;
        provider = _provider;
    }

    function whitelistCreator(address[] calldata _user) external {
        require(msg.sender == admin, "Not admin");
        for(uint256 i = 0; i < _user.length; i++) {
            whitelistedCreators[_user[i]] = true;
        }
    }

    function createNFTXNft(
        address _collection,
        address _vToken,
        address _xToken,
        address _SLP, 
        address _xSLP,
        uint256 _vaultId,
        uint256 _maxLPTokens
    ) external {
        require(
            whitelistedCreators[msg.sender]
            , "Not whitelisted"
        );
        require(
            nftxNfts[_collection] == address(0)
            , "NFTXNft already exists"
        );
        require(
            NFTXVaultFactoryUpgradeable(vaultFactory).vault(_vaultId) == _vToken
            , "Vault does not exist"
        );
        require(
            NFTXInventoryStaking(iStaking).vaultXToken(_vaultId) == _xToken
            , "Improper xToken"
        );
        (address stakingToken, ) = NFTXLPStaking(lpStaking).vaultStakingInfo(_vaultId);
        require(
            stakingToken == _SLP
            , "Improper SLP"
        );
        require(
            address(NFTXLPStaking(lpStaking).newRewardDistributionToken(_vaultId)) == _xSLP
            , "Improper xSLP"
        );
        NFTXNft nftxNft = new NFTXNft(
            _collection,
            iStaking,
            lpStaking,
            vaultFactory,
            provider,
            _vToken,
            _xToken,
            _SLP,
            _xSLP,
            _maxLPTokens
        );

        nftxNfts[_collection] = address(nftxNft);
        emit NFTXNftCreated(
            address(nftxNft)
        );
    }
}