const { ethers } = require("hardhat");
// const { expect } = require("chai");
// const {MerkleTree} = require("merkletreejs");
// const keccak256 = require("keccak256");
// const { concat } = require("ethers/lib/utils");
// const { constants } = require("ethers");

async function main() {

    const [deployer] = await ethers.getSigners();
    provider = ethers.getDefaultProvider(5);

    // ERC721 = await ethers.getContractFactory("ERC721");
    // erc721 = await ERC721.attach('0x8971718bca2b7fc86649b84601b17b634ecbdf19');

    NFTXInventoryStaking = await ethers.getContractFactory("NFTXInventoryStaking");
    iStaking = await NFTXInventoryStaking.attach("0x6e91A3f27cE6753f47C66B76B03E6A7bFdDB605B");

    NFTXLPStaking = await ethers.getContractFactory("NFTXLPStaking");
    lpStaking = await NFTXLPStaking.attach("0xAfC303423580239653aFB6fb06d37D666ea0f5cA");

    NFTXVaultFactoryUpgradeable = await ethers.getContractFactory("NFTXVaultFactoryUpgradeable");
    factory = await NFTXVaultFactoryUpgradeable.attach("0x1478bEB5D18B23d2bA90FcEe91d66460AC585e6b");

    StakingTokenProvider = await ethers.getContractFactory("StakingTokenProvider");
    tokenProvider = await StakingTokenProvider.attach("0x057862b3DB9fDe38d030479FEe43Deb38b04d211");

    NFTXVaultUpgradeable = await ethers.getContractFactory("NFTXVaultUpgradeable");
    vault = await NFTXVaultUpgradeable.attach("0x5caa4a286ff97ae8ee57aed8b246e72e3f66ea0d");

    ERC20Upgradeable = await ethers.getContractFactory("contracts/solidity/token/ERC20Upgradeable.sol:ERC20Upgradeable");
    vToken = await ERC20Upgradeable.attach("0x8be7868a36d24b821aaaf2bd8f1f2dd1509a7aef");
    xToken = await ERC20Upgradeable.attach("0xbec5e1643dbc329631cb6cd23906ed22598d7d6b");
    SLP = await ERC20Upgradeable.attach("0x60ee53d26c41009e0eda2adbed4771e78475cee3");
    xSLP = await ERC20Upgradeable.attach("0x53b410b687e9f1a51dc14c8182571569264dacae");

    Factory = await ethers.getContractFactory("Factory");
    // factory = await Factory.deploy(deployer.address);
    factory = await Factory.attach('0x6E3BC6973dC9fB6BC46C54a7ef592b7CCc0993A7');
    console.log("Factory:", factory.address);

    NFTXNft = await ethers.getContractFactory("NFTXNft");
    // nft = await NFTXNft.deploy(
    //     '0x317a8fe0f1c7102e7674ab231441e485c64c178a', // address _collection,
    //     '0x6e91A3f27cE6753f47C66B76B03E6A7bFdDB605B', // address _inventoryStaking,
    //     '0xAfC303423580239653aFB6fb06d37D666ea0f5cA', // address _lpStaking,
    //     '0x1478bEB5D18B23d2bA90FcEe91d66460AC585e6b', // address _vaultFactory,
    //     '0x057862b3DB9fDe38d030479FEe43Deb38b04d211', // address _provider,
    //     vToken.address, // address _vToken,
    //     xToken.address, // address _xToken,
    //     SLP.address, // address _SLP
    //     xSLP.address  // address _xSLP
    // );
    // nft = await NFTXNft.attach('0xf666A32d53ef7ee0C480e6Cc80a33E17AE29DB8e');

    //Get addresses: asset address, x, SLP, xSLP
    // console.log("ADDRESSES");
    // let xAddress = await iStaking.vaultXToken(13);
    // console.log("X:", xAddress);
    // let assetAddress = await vault.assetAddress();
    // console.log("AA:", assetAddress);

    // console.log("BALANCES");
    // console.log("V:", (await vToken.totalSupply()).toString());
    // console.log("VOX:", (await vToken.balanceOf(xToken.address)).toString());
    // console.log("X:", (await xToken.totalSupply()).toString());
    // console.log("SLP:", (await SLP.totalSupply()).toString());
    // console.log("Deployer balance of SLP:", (await SLP.balanceOf(deployer.address)).toString());
    // console.log("xSLP:", (await xSLP.totalSupply()).toString());
    // console.log("Deployer balance of xSLP:", (await xSLP.balanceOf(deployer.address)).toString());
    // console.log("Deployer balance:", (await vToken.balanceOf(deployer.address)).toString());
    // console.log("Pair balance:", (await vToken.balanceOf('0x4ea70bf7f00602addd0cf92164e12873acf19aff')));
    // console.log(await nft.ownerOf(1));

    //Whitelist creator
    const whitelist = await factory.whitelistCreator([deployer.address, '0xE6dC2c1a17b093F4f236Fe8545aCb9D5Ad94334a']);
    whitelist.wait();
    console.log("Whitelisted creator");

    //Create NFTXNft
    // const createNFTXNft = await factory.createNFTXNft(
    //         '0xf5de760f2e916647fd766b4ad9e85ff943ce3a2b', // address _collection,
    //         '0x6e91A3f27cE6753f47C66B76B03E6A7bFdDB605B', // address _inventoryStaking,
    //         '0xAfC303423580239653aFB6fb06d37D666ea0f5cA', // address _lpStaking,
    //         '0x1478bEB5D18B23d2bA90FcEe91d66460AC585e6b', // address _vaultFactory,
    //         '0x057862b3DB9fDe38d030479FEe43Deb38b04d211', // address _provider,
    //         vToken.address, // address _vToken,
    //         xToken.address, // address _xToken,
    //         SLP.address, // address _SLP
    //         xSLP.address,  // address _xSLP
    //         10000
    // );
    // createNFTXNft.wait();
    // console.log("NFTXNFT:", await factory.nftxNfts('0xf5de760f2e916647fd766b4ad9e85ff943ce3a2b'));

    //Create NFT for vToken
    // const approveV = await vToken.approve(nft.address, '700000000000000000000000');
    // approveV.wait();
    // const depositVToken = await nft.depositVToken(
    //     (1e18).toString(), //amount of vToken to deposit
    //     [1] //LP NFT Ids
    // );
    // depositVToken.wait();

    //Redeem vToken from NFT
    // const redeemV = await nft.redeemVToken(
    //     [1]
    // );
    // redeemV.wait();

    //Create NFT for xToken
    // const approveX = await xToken.approve(nft.address, '700000000000000000000000');
    // approveX.wait();
    // const approveV = await vToken.approve(nft.address, '700000000000000000000000');
    // approveV.wait();
    // const depositXToken = await nft.depositXToken(
    //     [1] //LP NFT Ids
    // )
    // depositXToken.wait();
    // console.log(await nft.ownerOf(1));
    // console.log(await xToken.balanceOf(deployer.address));

    //Redeem xToken from NFT
    // const approveRedemptionX = await nft.setApprovalForAll(nft.address, true);
    // approveRedemptionX.wait();
    // const redeemForX = await nft.redeemXToken(
    //     [1]
    // );
    // redeemForX.wait();

    //Get v to x
    // let xTokenAmount = await nft.getVtoX(
    //     (1e18).toString()
    // );
    // console.log(xTokenAmount.toString());

    //Get x to v
    // let vTokenAmount = await nft.getXtoV(
    //     (1e18).toString()
    // );
    // console.log(vTokenAmount.toString());

    //Create NFT for SLP
    // const approveSLP = await SLP.approve(nft.address, '700000000000000000000000');
    // approveSLP.wait();
    // const depositSLP = await nft.depositSLP(
    //     [1] //LP ids
    // );
    // depositSLP.wait();

    //Redeem SLP from NFT
    // const redeemSLP = await nft.redeemSLP(
    //     [1] //LP IDS
    // );
    // redeemSLP.wait();

    //Create NFT for xSLP
    // const approvexSLP = await xSLP.approve(nft.address, '700000000000000000000000');
    // approvexSLP.wait();
    // const depositXSLP = await nft.depositXSLP(
    //     [1] //LP ids
    // );
    // depositXSLP.wait();

    //Redeem xSLP from NFT 
    // const redeemXSLP = await nft.redeemXSLP(
    //     [1] //LP IDS
    // );
    // redeemXSLP.wait();

    //Get v to SLP
    // let SLPTokenAmount = await nft.getVtoSLP(
    //     (1e18).toString()
    // );
    // console.log(SLPTokenAmount.toString());

    //Get SLP to v
    // let vTokenAmount = await nft.getSLPtoV(
    //     '719977128942788198'
    // );
    // console.log(vTokenAmount.toString());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });

