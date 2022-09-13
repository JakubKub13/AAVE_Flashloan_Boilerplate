//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";

contract AaveFlashLoan is FlashLoanSimpleReceiverBase {
    using SafeMath for uint;
    event Log(address asset, uint val);

    constructor(IPoolAddressesProvider _addressProvider) FlashLoanSimpleReceiverBase(_addressProvider) {}

    function testFlashLoan(address asset, uint amount) external {
        address receiver = address(this);
        bytes memory params = ""; // here we pass extra data if we want to abi.enocode()
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiver,
            asset,
            amount,
            params,
            referralCode
        );
    }

// CALLBACK FUNCTION CALLED BY AAVE PROTOCOL
    function executeOperation(
        address asset,
        uint amount,
        uint premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        // Here we place custom code what we want to do with FlashLoan (arbitrages, liquidations, hacks....)
        // abi.decode(params) to decode params
        uint amountOwing = amount.add(premium);
        IERC20(asset).approve(address(POOL), amountOwing);
        return true;
    }
}