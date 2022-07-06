const CandyKitty = artifacts.require("CandyKitty");


const DefaultTokenURI = "https://mintverse.mypinata.cloud/ipfs/bafkreihbngzt2c6b3euz2ewveyaheigpoq72qynlw3wbfwvl4xzpxv2xai"


module.exports = function (deployer, network, accounts) {
    deployer.deploy(CandyKitty, "0x0000000000000000000000000000000000000000", DefaultTokenURI);
};