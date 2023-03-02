// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import { NFTXNft } from "./NFTXNft.sol";

contract Factory {

    address public admin;

    mapping(address => bool) public whitelistedCreators;
    mapping(address => address) public nftxNfts;

    event NFTXNftCreated(address nftxNft);

    constructor(
        address _admin
    ) {
        admin = _admin;
    }

    function whitelistCreator(address[] calldata _user) external {
        require(msg.sender == admin, "Not admin");
        for(uint256 i = 0; i < _user.length; i++) {
            whitelistedCreators[_user[i]] = true;
        }
    }

    function createNFTXNft(
        address _collection,
        address _inventoryStaking,
        address _lpStaking,
        address _vaultFactory,
        address _provider,
        address _vToken,
        address _xToken,
        address _SLP, 
        address _xSLP,
        uint256 _maxLPTokens
    ) external {
        require(whitelistedCreators[msg.sender], "Not whitelisted");
        require(nftxNfts[_collection] == address(0), "NFTXNft already exists");
        NFTXNft nftxNft = new NFTXNft(
            _collection,
            _inventoryStaking,
            _lpStaking,
            _vaultFactory,
            _provider,
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