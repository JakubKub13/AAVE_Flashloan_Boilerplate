const { expect, assert } = require("chai");
const { BigNumber } = require("ethers");
const { ethers, waffle, artifacts } = require("hardhat");
const hre = require("hardhat")

const { DAI, DAI_WHALE, LENDINGPOOL_ADDRESS_PROVIDER } = require("../constants")

describe("Deploy a FlashLoan", function () {
    it("Should take a flashloan and be able to return it", async function () {
        const AaveFlashLoan = await ethers.getContractFactory("AaveFlashLoan")
        const aaveFlashLoan = await AaveFlashLoan.deploy(LENDINGPOOL_ADDRESS_PROVIDER);
        await aaveFlashLoan.deployed();

        const dai = await ethers.getContractAt("IERC20", DAI);
        const amountOfDai = ethers.utils.parseEther("2000");

        // Impersonate DAI whale to be able to send transactions from that account
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [DAI_WHALE],
        });
        const signer = await ethers.getSigner(DAI_WHALE);

        // Now after that we create a signer for DAI_WHALE so that we can call the simulated DAI contract with the
        // address of DAI_WHALE and transfer some DAI to FlashLoanExample Contract. We need to do this so we can pay
        // off the loan with premium, as we will otherwise not be able to pay the premium. In real world applications,
        // the premium would be paid off the profits made from arbitrage or attacking a smart contract.
        await dai.connect(signer).transfer(aaveFlashLoan.address, amountOfDai) // send our contract dai amount from dai whale
        const tx = await aaveFlashLoan.testFlashLoan(DAI, 1000) // We are borrowing 1000 DAI
        await tx.wait();
        const remainingBalance = await dai.balanceOf(aaveFlashLoan.address); // Check balance of DAI in FlashLoan contract after action
        console.log(remainingBalance.toString())
        expect(remainingBalance.lt(amountOfDai)).to.be.true; // We must have less than 2000 DAI now because premium fee was paid from contract balance
    })
})