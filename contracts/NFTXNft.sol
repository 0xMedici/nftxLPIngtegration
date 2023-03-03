// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

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

    mapping(uint256 => uint256) public idType;

    event VTokenDeposited(
        address indexed user,
        uint256 amount,
        uint256[] lpTokenIds
    );

    event VTokenRedeemed(
        address indexed user,
        uint256[] lpTokenIds
    );

    event XTokenDeposited(
        address indexed user,
        uint256 amount,
        uint256[] lpTokenIds
    );

    event XTokenRedeemed(
        address indexed user,
        uint256[] lpTokenIds
    );

    event SLPDeposited(
        address indexed user,
        uint256 amount,
        uint256[] lpTokenIds
    );

    event SLPRedeemed(
        address indexed user,
        uint256[] lpTokenIds
    );

    event XSLPDeposited(
        address indexed user,
        uint256 amount,
        uint256[] lpTokenIds
    );

    event XSLPRedeemed(
        address indexed user,
        uint256[] lpTokenIds
    );

    constructor(
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
        maxLPTokens = _maxLPTokens;
    }

    function depositVToken(
        uint256[] calldata _lpTokenIds
    ) external {
        address vault = address(vToken);
        address NFT = NFTXVaultUpgradeable(vault).assetAddress();
        uint256 _amount = _lpTokenIds.length * 1e18;
        require(
            NFT == address(collection)
            , "Collections don't match"
        );
        require(
            vToken.balanceOf(msg.sender) >= _amount
            , "Insufficient balance"
        );
        for(uint256 i = 0; i < _lpTokenIds.length; i++) {
            require(
                !_exists(_lpTokenIds[i])
                , "ID already exists"
            );
            _mint(msg.sender, _lpTokenIds[i]);
            idType[_lpTokenIds[i]] = 1;
        }
        vToken.transferFrom(msg.sender, address(this), _amount);
        emit VTokenDeposited(msg.sender, _amount, _lpTokenIds);
    }

    function redeemVToken(
        uint256[] calldata _lpTokenIds
    ) external {
        uint256 length = _lpTokenIds.length;
        for(uint256 i = 0; i < length; i++) {
            require(
                idType[_lpTokenIds[i]] == 1
                , "Not an vToken lp token"
            );
            require(
                ownerOf(_lpTokenIds[i]) == msg.sender
                , "Not your lp token"
            );
            _burn(_lpTokenIds[i]);
        }
        vToken.transfer(
            msg.sender,
            _lpTokenIds.length * 1e18
        );
        emit VTokenRedeemed(msg.sender, _lpTokenIds);
    }

    function depositXToken(
        uint256[] calldata _lpTokenIds
    ) external {
        address vault = address(vToken);
        address NFT = NFTXVaultUpgradeable(vault).assetAddress();
        uint256 _amount = _lpTokenIds.length * 1e18 * xToken.totalSupply() / vToken.balanceOf(address(xToken));
        uint256 length = _lpTokenIds.length;
        require(
            NFT == address(collection)
            , "Collections don't match"
        );
        require(
            xToken.balanceOf(msg.sender) >= _amount
            , "Insufficient balance"
        );
        for(uint256 i = 0; i < length; i++) {
            require(
                !_exists(_lpTokenIds[i])
                , "ID already exists"
            );
            _mint(msg.sender, _lpTokenIds[i]);
            idType[_lpTokenIds[i]] = 2;
        }
        xToken.transferFrom(msg.sender, address(this), _amount);
    }

    function redeemXToken(
        uint256[] calldata _lpTokenIds
    ) external {
        uint256 length = _lpTokenIds.length;
        for(uint256 i = 0; i < length; i++) {
            require(
                idType[_lpTokenIds[i]] == 2
                , "Not an xToken lp token"
            );
            require(
                ownerOf(_lpTokenIds[i]) == msg.sender
                , "Not your lp token"
            );
            _burn(_lpTokenIds[i]);
        }
        xToken.transfer(
            msg.sender,
            (_lpTokenIds.length * 1e18) * xToken.totalSupply() / vToken.balanceOf(address(xToken))
        );
        emit XTokenRedeemed(msg.sender, _lpTokenIds);
    }

    function depositSLP(
        uint256[] calldata _lpTokenIds
    ) external {
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        uint256 slpSupply = SLP.totalSupply();
        uint256 pairBalance = vToken.balanceOf(address(SLP));
        uint256 _amount = _lpTokenIds.length * 1e18 * slpSupply / pairBalance;
        for(uint256 i = 0; i < _lpTokenIds.length; i++) {
            require(
                !_exists(_lpTokenIds[i])
                , "ID already exists"
            );
            _mint(msg.sender, _lpTokenIds[i]);
            idType[_lpTokenIds[i]] = 3;
        }
        SLP.transferFrom(msg.sender, address(this), _amount);
        emit SLPDeposited(msg.sender, _amount, _lpTokenIds);
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
        uint256 pairBalance = vToken.balanceOf(address(SLP));
        for(uint256 i = 0; i < length; i++) {
            require(
                idType[_lpTokenIds[i]] == 3
                , "Not an SLP token"
            );
            require(
                ownerOf(_lpTokenIds[i]) == msg.sender
                , "Not your lp token"
            );
            _burn(_lpTokenIds[i]);
        }
        SLP.transfer(
            msg.sender,
            (_lpTokenIds.length * 1e18) * slpSupply / pairBalance
        );
        emit SLPRedeemed(msg.sender, _lpTokenIds);
    }

    function depositXSLP(
        uint256[] calldata _lpTokenIds
    ) external {
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        uint256 slpSupply = SLP.totalSupply();
        uint256 pairBalance = vToken.balanceOf(address(SLP));
        uint256 _amount = _lpTokenIds.length * 1e18 * slpSupply / pairBalance;
        for(uint256 i = 0; i < _lpTokenIds.length; i++) {
            require(
                !_exists(_lpTokenIds[i])
                , "ID already exists"
            );
            _mint(msg.sender, _lpTokenIds[i]);
            idType[_lpTokenIds[i]] = 4;
        }
        xSLP.transferFrom(msg.sender, address(this), _amount);
        emit XSLPDeposited(msg.sender, _amount, _lpTokenIds);
    }

    function redeemXSLP(
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
        uint256 pairBalance = vToken.balanceOf(address(SLP));
        for(uint256 i = 0; i < length; i++) {
            require(idType[_lpTokenIds[i]] == 4, "Not an xSLP token");
            require(
                ownerOf(_lpTokenIds[i]) == msg.sender
                , "Not your lp token"
            );
            _burn(_lpTokenIds[i]);
        }
        xSLP.transfer(
            msg.sender,
            (_lpTokenIds.length * 1e18) * slpSupply / pairBalance
        );
        emit XSLPRedeemed(msg.sender, _lpTokenIds);
    }

    function getVtoX(uint256 _amount) external view returns(uint256) {
        uint256 vTokenAmount = 
            _amount * xToken.totalSupply() / vToken.balanceOf(address(xToken));
        return vTokenAmount;
    }

    function getXtoV(uint256 _amount) external view returns(uint256) {
        uint256 vTokenAmount = 
            _amount * vToken.balanceOf(address(xToken)) / xToken.totalSupply(); 
        return vTokenAmount;
    }

    function getVtoSLP(uint256 _amount) external view returns(uint256) {
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        uint256 slpSupply = SLP.totalSupply();
        uint256 pairBalance = vToken.balanceOf(address(SLP));
        uint256 vTokenAmount = _amount * slpSupply / pairBalance;
        return vTokenAmount;
    }

    function getSLPtoV(uint256 _amount) external view returns(uint256) {
        address pair;
        if(provider.pairForVaultToken(address(vToken), WETH) == address(0)) {
            pair = provider.pairForVaultToken(WETH, address(vToken));    
        } else {
            pair = provider.pairForVaultToken(address(vToken), WETH);    
        }
        uint256 slpSupply = SLP.totalSupply();
        uint256 pairBalance = vToken.balanceOf(address(SLP));
        uint256 vTokenAmount = _amount * pairBalance / slpSupply;
        return vTokenAmount;
    }
}