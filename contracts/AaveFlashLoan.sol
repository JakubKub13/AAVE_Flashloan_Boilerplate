//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/FlashLoanReceiverBase.sol";

contract AaveFlashLoan is FlashLoanReceiverBase {
    using SafeMath for uint;

    event Log(string message, uint val);

    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) {}

    function testFlashLoan(address asset, uint amount) external {
        uint bal = IERC20(asset).balanceOf(address(this));
        require(bal > amount, "bal <= amount");
        address receiver = address(this);
        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;

        // 0 = no debt 1 = stable 2 = variable
        // 0 = pay all loaned
        uint[] memory modes = new uint[](1);
        modes[0] = 0;
        address onBehalfOf = address(this);
        bytes memory params = ""; // here we pass extra data if we want to abi.enocode()
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiver,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

// CALLBACK FUNCTION CALLED BY AAVE PROTOCOL
    function executeOperation(
        address[] calldata assets,
        uint[] calldata amounts,
        uint[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Here we place custom code what we want to do with FlashLoan (arbitrages, liquidations, hacks....)
        // abi.decode(params) to decode params
        for (uint i = 0; i < assets.length; i++) {
            emit Log("Borrowed", amounts[i]);
            emit Log("Fee", premiums[i]);

            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }
        // Repay AAVE
        return true;
    }
}