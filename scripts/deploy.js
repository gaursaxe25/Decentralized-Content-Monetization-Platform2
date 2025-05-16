const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Project contract...");

  // We get the contract factory
  const Project = await ethers.getContractFactory("Project");
  
  // Platform fee percentage (5%)
  const platformFeePercentage = 5;
  
  // Deploy the contract with the constructor argument
  const project = await Project.deploy(platformFeePercentage);

  // Wait for the contract to be deployed
  await project.deployed();

  console.log(
    `Project contract deployed to: ${project.address} with platform fee: ${platformFeePercentage}%`
  );
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
