import { ethers } from "ethers"

export const provider = new ethers.providers.JsonRpcProvider(
    "http://localhost:8545"
)