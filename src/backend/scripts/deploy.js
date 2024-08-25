const { ethers } = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();
    console.log("Deploying contract with the account:", deployer.address);
    
    const baseURI = "https://apricot-adorable-buzzard-685.mypinata.cloud/ipfs/QmafYVRMa9aWj2QZACYeUfbDXttryS5SydazdijXcNVfms/";
    const MyNFTCollection = await ethers.deployContract("MyNFTCollection", [baseURI]);
    await MyNFTCollection.waitForDeployment();
    
    // Log the deployed contract address
    console.log("MyNFTCollection deployed to:", await  MyNFTCollection.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Error deploying contract:", error);
        process.exit(1);
    });