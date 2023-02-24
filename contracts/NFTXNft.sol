// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import { NFTXInventoryStaking } from "./solidity/NFTXInventoryStaking.sol";
import { NFTXLPStaking } from "./solidity/NFTXLPStaking.sol";
import { NFTXVaultUpgradeable } from "./solidity/NFTXVaultUpgradeable.sol";
import { NFTXVaultFactoryUpgradeable } from "./solidity/NFTXVaultFactoryUpgradeable.sol";
import { StakingTokenProvider } from "./solidity/StakingTokenProvider.sol";


import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract NFTXNft is ERC721 {
    
    ERC721 public collection;
    NFTXInventoryStaking public iStaking;
    NFTXLPStaking public lpStaking;
    NFTXVaultFactoryUpgradeable public factory;
    StakingTokenProvider public provider;
    ERC20Upgradeable public vToken;
    ERC20Upgradeable public xToken;
    ERC20Upgradeable public SLP;
    ERC20Upgradeable public xSLP;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public maxLPTokens;

    constructor(
        address _collection,
        address _inventoryStaking,
        address _lpStaking,
        address _vaultFactory,
        address _provider,
        address _vToken,
        address _xToken,
        address _SLP, 
        address _xSLP
    ) ERC721(ERC721(_collection).name(), ERC721(_collection).symbol()) {
        collection = ERC721(_collection);
        iStaking = NFTXInventoryStaking(_inventoryStaking);
        lpStaking = NFTXLPStaking(_lpStaking);
        factory = NFTXVaultFactoryUpgradeable(_vaultFactory);
        provider = StakingTokenProvider(_provider);
        vToken = ERC20Upgradeable(_vToken);
        xToken = ERC20Upgradeable(_xToken);
        SLP = ERC20Upgradeable(_SLP);
        xSLP = ERC20Upgradeable(_xSLP);
    }

    function depositVToken(
        uint256 _vaultId, 
        uint256 _amount, 
        uint256[] calldata _lpTokenIds
    ) external {
        address vault = address(iStaking.vaultXToken(_vaultId));
        address NFT = NFTXVaultUpgradeable(vault).assetAddress();
        ERC20Upgradeable baseToken = ERC20Upgradeable(factory.vault(_vaultId));
        require(NFT == address(collection), "Collections don't match");
        require(baseToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(_amount >= _lpTokenIds.length * 1e18, "Not enough tokens");
        for(uint256 i = 0; i < _lpTokenIds.length; i++) {
            _mint(msg.sender, _lpTokenIds[i]);
        }
        baseToken.transferFrom(msg.sender, address(this), _amount);
    }

    function redeemVToken(
        uint256[] calldata _lpTokenIds
    ) external {
        uint256 length = _lpTokenIds.length;
        for(uint256 i = 0; i < length; i++) {
            require(ownerOf(_lpTokenIds[i]) == msg.sender, "Not your lp token");
            _burn(_lpTokenIds[i]);
        }
        vToken.transferFrom(
            address(this),
            msg.sender,
            _lpTokenIds.length * 1e18
        );
    }

    function depositXToken(
        uint256 _vaultId, 
        uint256 _amount, 
        uint256[] calldata _lpTokenIds
    ) external {
        address vault = address(iStaking.vaultXToken(_vaultId));
        address NFT = NFTXVaultUpgradeable(vault).assetAddress();
        uint256 vTokenAmount = 
            _amount * vToken.balanceOf(address(xToken)) / xToken.totalSupply(); 
        uint256 length = _lpTokenIds.length;
        require(NFT == address(collection), "Collections don't match");
        require(xToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(vTokenAmount >= _lpTokenIds.length * 1e18, "Not enough tokens");
        for(uint256 i = 0; i < length; i++) {
            _mint(msg.sender, _lpTokenIds[i]);
        }
        xToken.transferFrom(msg.sender, address(this), _amount);
        if(vTokenAmount % 1e18 != 0) {
            xToken.transferFrom(
                address(this), 
                msg.sender, 
                (vTokenAmount % 1e18) * xToken.totalSupply() / vToken.balanceOf(address(xToken))
            );
        }
    }

    function redeemXToken(
        uint256[] calldata _lpTokenIds
    ) external {
        uint256 length = _lpTokenIds.length;
        for(uint256 i = 0; i < length; i++) {
            require(ownerOf(_lpTokenIds[i]) == msg.sender, "Not your lp token");
            _burn(_lpTokenIds[i]);
        }
        xToken.transferFrom(
            address(this),
            msg.sender,
            _lpTokenIds.length * xToken.totalSupply() / vToken.balanceOf(address(xToken))
        );
    }

    function depositSLPToken(
        uint256 _amount,
        uint256[] calldata _lpTokenIds
    ) external {
        //multiply vToken balance of sushi pool by _amount / SLP balance
            // this will return the proportion of the pool represented by the _amount
            // being deposited. therefore, the vToken balance of xSLP deposited is
            // _amount * vToken balance / total SLP balance. 

        //get pair
            // StakingTokenProvider.pairForVaultToken(address _vaultToken, address _pairedToken)
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        //get SLP total supply
            // address = NFTXLPStaking.vaultStakingInfo[_vaultId]
            // supply = SLP(address).totalSupply()
        uint256 slpSupply = SLP.totalSupply();

        //get vToken liquidity in the pool
            // address baseToken = factory.vault(_vaultId);
            // ... balanceOf(pair)
        uint256 pairBalance = vToken.balanceOf(pair);
        //calculate _amount * vToken balance / SLP total supply
            // self explan
        uint256 vTokenAmount = _amount * pairBalance / slpSupply;
        //make sure calculation results in same amount of tokens as _lpTokensIds.length
            // self explan
        require(vTokenAmount >= _lpTokenIds.length, "Underpaying for the amount of LP tokens you're trying to mint");
        //mint NFT
            // self explan
        for(uint256 i = 0; i < _lpTokenIds.length; i++) {
            _mint(msg.sender, _lpTokenIds[i]);
        }
        //take SLP
        SLP.transferFrom(msg.sender, address(this), _amount);
        //return any excess xSLP
        if(vTokenAmount % 1e18 != 0) {
            SLP.transferFrom(
                address(this), 
                msg.sender, 
                (vTokenAmount % 1e18) * slpSupply / pairBalance
            );
        }
    }

    function redeemSLP(
        uint256[] calldata _lpTokenIds
    ) external {
        uint256 length = _lpTokenIds.length;
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        uint256 slpSupply = SLP.totalSupply();
        uint256 pairBalance = vToken.balanceOf(pair);
        for(uint256 i = 0; i < length; i++) {
            require(ownerOf(_lpTokenIds[i]) == msg.sender, "Not your lp token");
            _burn(_lpTokenIds[i]);
        }
        SLP.transferFrom(
            address(this),
            msg.sender,
            _lpTokenIds.length * slpSupply / pairBalance
        );
    }

    function depositXSLPToken(
        uint256 _amount,
        uint256[] calldata _lpTokenIds
    ) external {
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        uint256 slpSupply = SLP.totalSupply();
        uint256 pairBalance = vToken.balanceOf(pair);
        uint256 vTokenAmount = _amount * pairBalance / slpSupply;
        require(vTokenAmount >= _lpTokenIds.length, "Underpaying for the amount of LP tokens you're trying to mint");
        for(uint256 i = 0; i < _lpTokenIds.length; i++) {
            _mint(msg.sender, _lpTokenIds[i]);
        }
        xSLP.transferFrom(msg.sender, address(this), _amount);
        if(vTokenAmount % 1e18 != 0) {
            xSLP.transferFrom(
                address(this), 
                msg.sender, 
                (vTokenAmount % 1e18) * slpSupply / pairBalance
            );
        }
    }

    function redeemXSLPToken(
        uint256[] calldata _lpTokenIds
    ) external {
        uint256 length = _lpTokenIds.length;
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        uint256 slpSupply = SLP.totalSupply();
        uint256 pairBalance = vToken.balanceOf(pair);
        for(uint256 i = 0; i < length; i++) {
            require(ownerOf(_lpTokenIds[i]) == msg.sender, "Not your lp token");
            _burn(_lpTokenIds[i]);
        }
        xSLP.transferFrom(
            address(this),
            msg.sender,
            _lpTokenIds.length * slpSupply / pairBalance
        );
    }
}
