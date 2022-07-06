const { expectRevert, time } = require('@openzeppelin/test-helpers');

const CandyKitty = artifacts.require("CandyKitty");

const Web3 = require('web3');
const truffleAssert = require('truffle-assertions');
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

const tokenPrecision = web3.utils.toBN(1e18)

const BaseURI = "https://mintverse.mypinata.cloud/ipfs/QmdwAhR7U2VbizMT1QW3ySReV4pMw6Cdf9rnUnnYYSVYLh/"

contract('CandyKitty Contract', (accounts) => {
    
});