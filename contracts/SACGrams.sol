// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SACGrams is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    address public treasuryWallet;
    address public rewardsWallets;
    address public developmentWallet;
    address public teamWallet;

    bool initAddress;
    bool initMint;

    constructor() ERC20("SACGrams", "SACGRAMS") ERC20Permit("SACGrams") {}

    receive() external payable {}

    //set wallet addresses, can be executed only once
    function setWalletAddresses(address _treasuryWallet, address _rewardsWallets, address _developmentWallet, address _teamWallet) external onlyOwner {
        require(!initAddress, "Addresses have already been set");
        treasuryWallet = _treasuryWallet;
        rewardsWallets = _rewardsWallets;
        developmentWallet = _developmentWallet;
        teamWallet = _teamWallet;
        initAddress = true;
    }

    //mint the total supply, can be executed only once
    function mint() external onlyOwner {
        require(!initMint, "Supply have already been minted");
        require(initAddress, "Recepient wallet addresses have not been set");
        _mint(treasuryWallet, 209999950 * 10 ** decimals());
        _mint(rewardsWallets, 209999950 * 10 ** decimals());
        _mint(developmentWallet, 50 * 10 ** decimals());
        _mint(teamWallet, 50 * 10 ** decimals());
        initMint = true;
    }
}