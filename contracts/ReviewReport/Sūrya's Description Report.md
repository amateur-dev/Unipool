 Sūrya's Description Report

 Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| /Users/dipeshsukhani/Desktop/Coding/DockerMounting/Python/allFolders/docker_nodes_sc_v2/sc_dev/Unipool/contracts/zUniPool.sol | 9cc3d0865ce06e2116173e90340ef6f3e8f3ceef |


 Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **zUniPool** | Implementation | Ownable |||
| └ | allowTheAddress | Public ❗️ | 🛑  | onlyOwner |
| └ | removeTheAddress | Public ❗️ | 🛑  | onlyOwner |
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | approve_Addresses | Public ❗️ | 🛑  |NO❗️ |
| └ | howMuchHasThisContractStaked | Public ❗️ |   |NO❗️ |
| └ | howMuchHasThisContractEarned | Public ❗️ |   |NO❗️ |
| └ | howMuchIszUNIWorth | External ❗️ |   |NO❗️ |
| └ | stakeMyShare | Public ❗️ | 🛑  | allowedToStake stopInEmergency |
| └ | issueTokens | Internal 🔒 | 🛑  | |
| └ | getDetails | Internal 🔒 | 🛑  | |
| └ | reBalance | Internal 🔒 | 🛑  | |
| └ | reBalanceContractWealth | Public ❗️ | 🛑  |NO❗️ |
| └ | convertSNXtoLP | Internal 🔒 | 🛑  | |
| └ | getMaxTokens | Internal 🔒 |   | |
| └ | min_eth | Internal 🔒 |   | |
| └ | min_tokens | Internal 🔒 |   | |
| └ | getMyStakeOut | Public ❗️ | 🛑  | stopInEmergency |
| └ | mint | Internal 🔒 | 🛑  | |
| └ | burn | Internal 🔒 | 🛑  | |
| └ | transfer | Public ❗️ | 🛑  |NO❗️ |
| └ | approve | Public ❗️ | 🛑  |NO❗️ |
| └ | transferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | _transfer | Internal 🔒 | 🛑  | |
| └ | _approve | Internal 🔒 | 🛑  | |
| └ | <Fallback> | External ❗️ |  💵 |NO❗️ |
| └ | getRewardOut | Public ❗️ | 🛑  | onlyOwner |
| └ | withdrawAllStaked | Public ❗️ | 🛑  | onlyOwner |
| └ | destruct | Public ❗️ | 🛑  | onlyOwner |
| └ | withdraw | Public ❗️ | 🛑  | onlyOwner |
| └ | toggleContractActive | Public ❗️ | 🛑  | onlyOwner |
| └ | inCaseTokengetsStuck | Public ❗️ | 🛑  | onlyOwner |


 Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
