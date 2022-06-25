// import { provider } from "./provider"
import { network } from "hardhat";
require("dotenv").config()


export const resetFork = async (block: number) => {
    return await network.provider.request({
        method: "hardhat_reset",
        params: [{
            forking: {
                enabled: true,
                jsonRpcUrl: "https://polygon-mainnet.g.alchemy.com/v2/6SX6eDlnTOlsmd4fwfB67S8oU78jVh99",
                //you can fork from last block by commenting next line
                blockNumber: block,
            },
        },],
    });
}
