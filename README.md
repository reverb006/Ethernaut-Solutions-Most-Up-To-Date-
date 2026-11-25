# OpenZeppelin Ethernaut — Security Writeups & Solutions

![Platform](https://img.shields.io/badge/CTF-OpenZeppelin%20Ethernaut-4E5EE4?style=flat-square&logo=ethereum)
![Solidity](https://img.shields.io/badge/Solidity-0.6.x%20%E2%80%93%200.8.x-363636?style=flat-square&logo=solidity)
![Progress](https://img.shields.io/badge/Completed-21%20Levels-2ea44f?style=flat-square)

Smart contract vulnerability writeups, audit signals, mitigations, and complete challenge solutions for **[The Ethernaut](https://ethernaut.openzeppelin.com/)**.

> **Repository Scope:** Each level folder contains the challenge contract alongside my solution contract or console/storage script. This `README.md` breaks down **what the level asks**, **how to spot the flaw during a security review**, **root cause mechanics**, **my exact solution walkthrough**, and **defensive mitigations**.  
> *(Note: Incomplete/remaining levels will be added incrementally as they are solved.)*

---

## Repository Structure

```text
ethernaut-solutions/
├── README.md                  # Master audit writeups, mitigation patterns & challenge index
├── 3_Coin_Flip/               # contract.sol
├── 4_Telephone/               # contract.sol
├── 5_Token/                   # Contract.sol
├── 7_Force/                   # Contract.sol
├── 8_Vault/                   # Code.txt
├── 9_King/                    # Contract.sol
├── 10_Reentrance/             # Contract.sol
├── 11_Elevator/               # Contract.sol
├── 12_Privacy/                # Note.txt
├── 13_GateKeeper_One/         # Contract.sol
├── 15_Naught_Coin/            # Contract.sol
├── 16_Preservation/           # Contract.sol
├── 18_Magic_Number/           # Contract.sol
├── 20_Denial/                 # Contract.sol
├── 21_Shop/                   # Contract.sol
├── 22_Dex/                    # Solution.txt
├── 23_Dex2/                   # Contract.sol
├── 24_Puzzle_Wallet/          # Contract.sol + UpgradeableProxy-08.sol
├── 25_MotorBike/              # Contract.sol
├── 31_Stake/                  # Contract.sol
└── 34_Bet_House/              # Contract.sol
```

---

## Challenge Index

| Level | Challenge | Core Vulnerability | Solution File |
| :-: | :--- | :--- | :--- |
| 3 | [Coin Flip](#3-coin-flip) | Predictable On-Chain Blockhash Randomness | [contract.sol](./3_Coin_Flip/contract.sol) |
| 4 | [Telephone](#4-telephone) | `tx.origin` vs `msg.sender` Authentication | [contract.sol](./4_Telephone/contract.sol) |
| 5 | [Token](#5-token) | Solidity `<0.8.0` Arithmetic Underflow | [Contract.sol](./5_Token/Contract.sol) |
| 7 | [Force](#7-force) | Forced ETH Balance via `selfdestruct` | [Contract.sol](./7_Force/Contract.sol) |
| 8 | [Vault](#8-vault) | Reading `private` On-Chain Storage Slot | [Code.txt](./8_Vault/Code.txt) |
| 9 | [King](#9-king) | ETH Push `transfer` Denial-of-Service | [Contract.sol](./9_King/Contract.sol) |
| 10 | [Reentrance](#10-reentrance) | Classic Reentrancy (CEI Violation) | [Contract.sol](./10_Reentrance/Contract.sol) |
| 11 | [Elevator](#11-elevator) | Non-`view` External Interface Callback | [Contract.sol](./11_Elevator/Contract.sol) |
| 12 | [Privacy](#12-privacy) | Packed Storage Layout & `bytes32` Slicing | [Note.txt](./12_Privacy/Note.txt) |
| 13 | [Gatekeeper One](#13-gatekeeper-one) | `tx.origin`, Gas Modulo & Bitmasking | [Contract.sol](./13_GateKeeper_One/Contract.sol) |
| 15 | [Naught Coin](#15-naught-coin) | Overridden `transfer` Bypass via `transferFrom` | [Contract.sol](./15_Naught_Coin/Contract.sol) |
| 16 | [Preservation](#16-preservation) | `delegatecall` Storage Slot Collision | [Contract.sol](./16_Preservation/Contract.sol) |
| 18 | [MagicNumber](#18-magicnumber) | Minimal Raw EVM Bytecode (`<= 10` bytes) | [Contract.sol](./18_Magic_Number/Contract.sol) |
| 20 | [Denial](#20-denial) | Gas-Exhaustion DoS in Unchecked `.call()` | [Contract.sol](./20_Denial/Contract.sol) |
| 21 | [Shop](#21-shop) | Stateful View Manipulation (`isSold()` check) | [Contract.sol](./21_Shop/Contract.sol) |
| 22 | [Dex](#22-dex) | AMM Price Manipulation via Integer Rounding | [Solution.txt](./22_Dex/Solution.txt) |
| 23 | [Dex Two](#23-dex-two) | Unvalidated Token Address in `swap()` | [Contract.sol](./23_Dex2/Contract.sol) |
| 24 | [Puzzle Wallet](#24-puzzle-wallet) | Proxy Slot Collision + Nested `multicall` | [Contract.sol](./24_Puzzle_Wallet/Contract.sol) |
| 25 | [Motorbike](#25-motorbike) | Uninitialized UUPS Implementation Contract | [Contract.sol](./25_MotorBike/Contract.sol) |
| 31 | [Stake](#31-stake) | Unchecked `WETH.transferFrom` + ETH Accounting | [Contract.sol](./31_Stake/Contract.sol) |
| 34 | [Bet House](#34-bet-house) | Cross-Function Reentrancy Before Burn | [Contract.sol](./34_Bet_House/Contract.sol) |

---

## Detailed Challenge Writeups

### 3. Coin Flip

> **Solution:** [3_Coin_Flip/contract.sol](./3_Coin_Flip/contract.sol)

#### 📋 Description
`CoinFlip` challenges players to guess the outcome of a coin flip **10 times in a row** (`consecutiveWins == 10`).

#### 🔍 How to Find It
- Flag any randomness logic that uses global block variables (`blockhash`, `block.timestamp`, `block.prevrandao` / `block.difficulty`).
- Every transaction inside the same block shares the exact same `blockhash(block.number - 1)`.

#### ⚠️ Vulnerability (Root Cause)
`CoinFlip.flip()` computes the winning boolean deterministically from `uint256(blockhash(block.number - 1)) / FACTOR`. Because `blockhash(block.number - 1)` is publicly readable on-chain to any contract executing in the same block, a caller contract can compute the exact outcome first and pass the matching `_guess`.

#### 💡 Solution Walkthrough
In `Attack.attacker(address target)`:
1. Reads `blockhash(block.number - 1)` and divides by the exact same `FACTOR`.
2. Computes `bool side = coinFlip == 1 ? true : false;` and calls `ICoinFlip(target).flip(side)` across 10 separate blocks until `consecutiveWins` reaches 10.

#### 🛡️ Mitigation
Never generate randomness from public block attributes (`blockhash`, `timestamp`). Use a verifiable off-chain randomness oracle such as **Chainlink VRF** or commit-reveal schemes.

[↑ Back to Index](#challenge-index)

---

### 4. Telephone

> **Solution:** [4_Telephone/contract.sol](./4_Telephone/contract.sol)

#### 📋 Description
Claim ownership of the `Telephone` contract.

#### 🔍 How to Find It
- Search for `tx.origin` in authorization checks.
- Remember: `tx.origin` is always the original EOA that signed the transaction, whereas `msg.sender` is the immediate caller (contract or EOA).

#### ⚠️ Vulnerability (Root Cause)
`Telephone.changeOwner()` checks `if (tx.origin != msg.sender) { owner = _owner; }`. While intended to restrict ownership changes, calling `changeOwner` through an intermediary smart contract guarantees `tx.origin` (your EOA) differs from `msg.sender` (the intermediary contract).

#### 💡 Solution Walkthrough
In `Attack.attack(address target)`, an intermediary contract calls `i_Telephone(target).changeOwner(tx.origin)`. Inside `Telephone`, `msg.sender == address(Attack)` and `tx.origin == player`, passing the condition and transferring ownership to `player`.

#### 🛡️ Mitigation
Always use `msg.sender` (never `tx.origin`) for authorization, and enforce explicit role/owner checks (`require(msg.sender == owner)`).

[↑ Back to Index](#challenge-index)

---

### 5. Token

> **Solution:** [5_Token/Contract.sol](./5_Token/Contract.sol)

#### 📋 Description
You start with **20 tokens** on the `Token` contract (`pragma solidity ^0.6.0`). Gain a very large token balance beyond your initial 20 tokens.

#### 🔍 How to Find It
- Check the Solidity compiler version: versions **below `0.8.0`** do **not** revert on unsigned integer overflow/underflow unless `SafeMath` is used.
- Check subtraction inside `require(a - b >= 0)`: subtracting a larger `uint256` from a smaller `uint256` wraps around to a huge positive value (`>= 0` is always true for unsigned integers!).

#### ⚠️ Vulnerability (Root Cause)
In `Token.transfer()`:
```solidity
require(balances[msg.sender] - _value >= 0);
balances[msg.sender] -= _value;
balances[_to] += _value;
```
Because `balances[msg.sender] - _value` is `uint256`, transferring `21` tokens from a contract with `0` balance underflows to `2**256 - 21`, satisfying `>= 0` and overflowing/crediting tokens via wrap-around.

#### 💡 Solution Walkthrough
Deploying `attack` (which starts with `0` balance on `Token`) and calling `attack._attack(target)` executes `i_Token(target).transfer(msg.sender, 21)`, transferring `21` tokens to `msg.sender` while underflowing `attack`'s balance to near `type(uint256).max`.

#### 🛡️ Mitigation
Upgrade to **Solidity `>= 0.8.0`** (built-in checked arithmetic) or use OpenZeppelin `SafeMath`, and always check `require(balances[msg.sender] >= _value)` directly.

[↑ Back to Index](#challenge-index)

---

### 7. Force

> **Solution:** [7_Force/Contract.sol](./7_Force/Contract.sol)

#### 📋 Description
The `Force` contract contains zero code, zero functions, and no `receive()` or `fallback()`. Force its ETH balance above zero (`address(force).balance > 0`).

#### 🔍 How to Find It
- Flag any contract logic that relies on `address(this).balance == 0` or exact `address(this).balance` equality invariants.
- Remember the ways ETH can enter a contract without triggering `receive()`/`fallback()`: `selfdestruct`, block coinbase rewards, and pre-computed `CREATE2` address pre-funding.

#### ⚠️ Vulnerability (Root Cause)
Even though `Force` refuses normal ETH transfers (`receive()` and `fallback()` are absent), the EVM `SELFDESTRUCT` opcode forcibly forwards a self-destructing contract's entire ETH balance to the target address without executing any code on the recipient.

#### 💡 Solution Walkthrough
Deploy `attack` funded with ETH (`payable` constructor), then call `hack()` which invokes `selfdestruct(payable(address(force)))`, pushing all ETH into `Force`.

#### 🛡️ Mitigation
Never assume `address(this).balance` can only increase through payable functions; avoid strict `address(this).balance` equality checks and track protocol ETH deposits internally.

[↑ Back to Index](#challenge-index)

---

### 8. Vault

> **Solution:** [8_Vault/Code.txt](./8_Vault/Code.txt)

#### 📋 Description
Unlock the `Vault` contract by finding the `bytes32 private password` stored inside it.

#### 🔍 How to Find It
- Never confuse the Solidity visibility keyword `private` with encryption or secrecy: `private` only restricts other *smart contracts* from reading the variable via an auto-generated getter.
- All EVM contract storage slots are completely public on-chain.

#### ⚠️ Vulnerability (Root Cause)
`Vault` stores `bool public locked` in slot `0` and `bytes32 private password` in **slot `1`**. Anyone with an Ethereum RPC node can inspect slot `1` directly off-chain and pass the password to `unlock()`.

#### 💡 Solution Walkthrough
In [Code.txt](./8_Vault/Code.txt), query storage slot `1` using Web3:
```javascript
await web3.eth.getStorageAt("<CONTRACT_ADDRESS>", 1)
```
Then pass the returned `bytes32` hex value to `vault.unlock(password)`.

#### 🛡️ Mitigation
Never store plaintext passwords, secrets, or private keys in smart contract storage (`public` or `private`). Verify commitments (`keccak256` hashes) or off-chain signatures instead.

[↑ Back to Index](#challenge-index)

---

### 9. King

> **Solution:** [9_King/Contract.sol](./9_King/Contract.sol)

#### 📋 Description
`King` crowns whoever sends `msg.value >= prize`, refunding the previous `king` via `payable(king).transfer(msg.value)`. Take ownership of the throne and prevent anyone (even the level's owner) from reclaiming it.

#### 🔍 How to Find It
- Check every **push-based ETH transfer** (`transfer()` / `send()` / unchecked external call) inside critical state transitions.
- Ask: *"What happens if the previous recipient is a contract that always reverts when receiving ETH?"*

#### ⚠️ Vulnerability (Root Cause)
In `King.receive()`:
```solidity
require(msg.value >= prize || msg.sender == owner);
payable(king).transfer(msg.value);
king = msg.sender;
```
Because `King` pushes ETH to the old `king` *before* updating `king = msg.sender` — and uses `.transfer()` which reverts on failure — a contract without `receive()` or `fallback()` permanently blocks anyone else from becoming the new king.

#### 💡 Solution Walkthrough
Deploying `Attack` with `0.002 ether` triggers `target.call{value: 0.002 ether}("")` inside its constructor, becoming `king`. Because `Attack` defines neither `receive()` nor `fallback()`, every subsequent `payable(king).transfer(...)` call reverts, locking kingship forever.

#### 🛡️ Mitigation
Use the **Pull-over-Push** withdrawal pattern: record claimable refunds in a `mapping(address => uint256) pendingWithdrawals` and let previous kings withdraw their funds separately rather than blocking future state updates.

[↑ Back to Index](#challenge-index)

---

### 10. Reentrance

> **Solution:** [10_Reentrance/Contract.sol](./10_Reentrance/Contract.sol)

#### 📋 Description
Drain all ETH out of the `Reentrance` contract (`pragma solidity ^0.6.12`).

#### 🔍 How to Find It
- Check every external value call (`msg.sender.call{value: _amount}("")`) to verify whether internal user balances are updated **before** or **after** the external call.
- Note that Solidity `0.6.12` without `SafeMath` on `balances[msg.sender] -= _amount` also allows silent unsigned underflow after draining.

#### ⚠️ Vulnerability (Root Cause)
`Reentrance.withdraw(uint256 _amount)` sends ETH (`msg.sender.call{value: _amount}("")`) *before* decrementing `balances[msg.sender] -= _amount`. Calling `withdraw()` from a contract whose `receive()` re-enters `withdraw()` repeatedly passes `if (balances[msg.sender] >= _amount)` until the contract is drained.

#### 💡 Solution Walkthrough
In `attack`:
1. `hack()` deposits `0.001 ether` via `rent.donate{value: 0.001 ether}(address(this))` and calls `rent.withdraw(0.001 ether)`.
2. Inside `receive()`, while `address(rent).balance > 0 ether`, it re-enters `rent.withdraw(0.001 ether)` until all ETH is extracted.

#### 🛡️ Mitigation
Strictly follow the **Checks-Effects-Interactions (CEI)** pattern (decrement `balances[msg.sender]` before making the external `.call`), add OpenZeppelin's `nonReentrant` modifier, and upgrade to Solidity `>= 0.8.0`.

[↑ Back to Index](#challenge-index)

---

### 11. Elevator

> **Solution:** [11_Elevator/Contract.sol](./11_Elevator/Contract.sol)

#### 📋 Description
Reach the top floor (`top == true`) on the `Elevator` contract.

#### 🔍 How to Find It
- Check external interface calls (`Building(msg.sender).isLastFloor(...)`): is the interface function marked **`view`**?
- Flag any logic that **calls the exact same external function twice** while assuming both calls will return identical answers.

#### ⚠️ Vulnerability (Root Cause)
`Elevator.goTo()` invokes `building.isLastFloor(_floor)` twice:
```solidity
if (!building.isLastFloor(_floor)) {
    floor = _floor;
    top = building.isLastFloor(floor);
}
```
Because `Building.isLastFloor` is not `view` (and even `view` callbacks can inspect state changes like `floor` or `gasleft()`), a malicious `msg.sender` contract can mutate state between calls and return `false` first, then `true` second.

#### 💡 Solution Walkthrough
`ElevatorAttack` implements `Building`:
1. `attack(elevator)` invokes `Elevator(elevator).goTo(1)`.
2. Inside `isLastFloor(uint256)`, increments `calls++` and returns `calls > 1` (`false` on the first call, `true` on the second), setting `top = true`.

#### 🛡️ Mitigation
Mark external read interfaces as `view` when appropriate and **cache the result** in a local variable rather than querying an untrusted contract twice (while still recognizing `view` functions can observe updated local storage between calls).

[↑ Back to Index](#challenge-index)

---

### 12. Privacy

> **Solution:** [12_Privacy/Note.txt](./12_Privacy/Note.txt)

#### 📋 Description
Unlock the `Privacy` contract by recovering the key stored in its private fixed-size `bytes32[3]` array and passing the correctly truncated `bytes16` value to `unlock()`.

#### 🔍 How to Find It
- Inspect **Solidity storage packing rules**: variables smaller than 32 bytes (`bool`, `uint8`, `uint16`, addresses) pack together into shared 32-byte storage slots, whereas fixed arrays (`bytes32[3]`) occupy sequential full slots.
- Remember `private` state variables remain completely visible via `getStorageAt`.

#### ⚠️ Vulnerability (Root Cause)
All EVM storage slots are publicly readable off-chain. Reading the target `bytes32` entry from `data[2]` and casting `bytes32 -> bytes16` (taking the leftmost 16 bytes / first 32 hex characters) exposes the unlock key.

#### 💡 Solution Walkthrough
In [Note.txt](./12_Privacy/Note.txt), query storage via `web3.eth.getStorageAt`, extract the 32-byte word (`0xd244887874bace1426d766caea1fcb978fc1cef972e936f61830f7fc3217e28e`), and slice its leftmost 16 bytes (`0xd244887874bace1426d766caea1fcb97`) to call `unlock()`.

#### 🛡️ Mitigation
Never rely on `private` visibility or storage slot packing to hide sensitive data on a public blockchain.

[↑ Back to Index](#challenge-index)

---

### 13. Gatekeeper One

> **Solution:** [13_GateKeeper_One/Contract.sol](./13_GateKeeper_One/Contract.sol)

#### 📋 Description
Pass all three modifiers (`gateOne`, `gateTwo`, `gateThree`) on `GatekeeperOne.enter(bytes8 _gateKey)` so `entrant` is set to `tx.origin`.

#### 🔍 How to Find It
- Deconstruct each gate constraint individually:
  - `gateOne`: `msg.sender != tx.origin` -> call via an intermediary contract.
  - `gateTwo`: `gasleft() % 8191 == 0` -> control exact gas forwarded via `.call{gas: ...}`.
  - `gateThree`: bit-width truncation rules (`uint16`, `uint32`, `uint64`) on `bytes8 _gateKey`.

#### ⚠️ Vulnerability (Root Cause)
Access restrictions built on `tx.origin`, gas-modulo puzzles (`gasleft() % 8191`), and integer truncation checks can be systematically satisfied by a caller contract that masks `tx.origin` appropriately and sweeps exact gas offsets.

#### 💡 Solution Walkthrough
In `Attacker.attack()`:
1. **Gate 3 Key Construction:** Computes `bytes8 key = bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF);` — keeping lower 16 bits equal to `uint16(uint160(tx.origin))`, zeroing bits 16..31 so `uint32(key) == uint16(key)`, and preserving upper bits so `uint32(key) != uint64(key)`.
2. **Gate 1 & Gate 2:** Loops `i` from `0` to `8190` invoking `address(keeper).call{gas: 8191 * 10 + i}(abi.encodeWithSelector(keeper.enter.selector, key))` until the exact gas modulo hits `0` and succeeds.

#### 🛡️ Mitigation
Do not build security boundaries around `gasleft()` arithmetic, `tx.origin`, or obfuscated bit-truncation checks. Rely on standard explicit caller/signature checks.

[↑ Back to Index](#challenge-index)

---

### 15. Naught Coin

> **Solution:** [15_Naught_Coin/Contract.sol](./15_Naught_Coin/Contract.sol)

#### 📋 Description
`NaughtCoin` is an ERC-20 token minting `1,000,000` tokens to `player`, with a 10-year `timeLock` restriction on `transfer()`. Move all tokens out of the `player` account before the 10-year timelock expires.

#### 🔍 How to Find It
- Whenever a token inherits a standard interface (`ERC20`) and overrides **only `transfer()`** with a modifier (like `lockTokens`), check every other token-moving entry point: **`approve()` + `transferFrom()`** (and `_update` / `_beforeTokenTransfer` hooks).

#### ⚠️ Vulnerability (Root Cause)
`NaughtCoin` overrides `transfer()` with `lockTokens`, but forgets to restrict `transferFrom()` inherited from OpenZeppelin `ERC20`. Therefore, `player` can approve an external contract (or another address) and move the full token balance via `transferFrom()`.

#### 💡 Solution Walkthrough
1. `player` approves the deployed `hackIt` contract for `INITIAL_SUPPLY` via `approve()`.
2. Calling `hackIt.attack()` fetches `target.balanceOf(msg.sender)` and pulls the entire locked balance via `target.transferFrom(msg.sender, address(this), amount)`.

#### 🛡️ Mitigation
Place transfer restrictions inside the centralized internal token hook (`_update` in OZ v5 or `_beforeTokenTransfer` in OZ v4) so both `transfer()` and `transferFrom()` enforce identical lock rules.

[↑ Back to Index](#challenge-index)

---

### 16. Preservation

> **Solution:** [16_Preservation/Contract.sol](./16_Preservation/Contract.sol)

#### 📋 Description
`Preservation` uses `delegatecall` to forward timestamp updates to two library contracts (`timeZone1Library`, `timeZone2Library`). Claim ownership (`owner`) of `Preservation`.

#### 🔍 How to Find It
- Whenever a contract uses **`delegatecall`**, compare the **storage layouts** (slot-by-slot) of the caller and target library.
- `Preservation` has `timeZone1Library` in slot 0, `timeZone2Library` in slot 1, and `owner` in slot 2 — while `LibraryContract` puts `storedTime` in slot 0!

#### ⚠️ Vulnerability (Root Cause)
`Preservation.setFirstTime(_timeStamp)` executes `timeZone1Library.delegatecall(...)`. Because `delegatecall` modifies the **caller's storage**, `LibraryContract.setTime(_time)` writing `storedTime = _time` actually overwrites **slot 0 (`timeZone1Library`)** in `Preservation`! Once slot 0 points to a malicious contract, a second call to `setFirstTime()` runs arbitrary `delegatecall` logic and overwrites **slot 2 (`owner`)**.

#### 💡 Solution Walkthrough
In `hackit`:
1. `changeAddress()` calls `target.setFirstTime(uint256(uint160(address(this))))`, overwriting slot 0 (`timeZone1Library`) with `address(hackit)`.
2. Calling `target.setFirstTime(...)` a second time delegates execution to `hackit.setTime(uint256)`, which executes assembly `sstore(2, origin())` to overwrite slot 2 (`owner`) with `tx.origin`.

#### 🛡️ Mitigation
Never use `delegatecall` to stateful libraries with mismatched storage layouts; use stateless `library` calls (`internal` or pure/view) or strictly aligned proxy storage slots (such as EIP-1967).

[↑ Back to Index](#challenge-index)

---

### 18. MagicNumber

> **Solution:** [18_Magic_Number/Contract.sol](./18_Magic_Number/Contract.sol)

#### 📋 Description
Deploy a `solver` contract for `MagicNum` whose `whatIsTheMeaningOfLife()` returns `42` (`0x2a`), using **at most 10 bytes of runtime bytecode**.

#### 🔍 How to Find It
- Solidity compiles even minimal contracts with function dispatchers and metadata hashes that exceed 10 bytes.
- To fit within 10 bytes, craft minimal raw EVM initialization + runtime opcodes directly (`MSTORE` + `RETURN`).

#### ⚠️ Vulnerability / Puzzle Mechanic
This level tests low-level EVM creation vs runtime bytecode mechanics:
- **Runtime (10 bytes):** `602a60005260206000f3` (`PUSH1 0x2a`, `PUSH1 0x00`, `MSTORE`, `PUSH1 0x20`, `PUSH1 0x00`, `RETURN`) unconditionally returns `42` padded to 32 bytes regardless of calldata selector.
- **Init code (12 bytes):** `600a600c600039600a6000f3` (`CODECOPY` 10 bytes from offset `0x0c` into memory `0x00`, then `RETURN` those 10 bytes).

#### 💡 Solution Walkthrough
`MagicNumberDeployer.deploy()` uses inline assembly `create(0, add(creationCode, 0x20), mload(creationCode))` on `hex"600a600c600039600a6000f3602a60005260206000f3"`, returning a minimal 10-byte solver address to pass to `MagicNum.setSolver(solver)`.

#### 🛡️ Takeaway
Understanding EVM deployment (`initcode` vs `runtime bytecode`, `CODECOPY`, and `RETURN`) is essential for debugging minimal proxies, bytecode analysis, and gas optimization.

[↑ Back to Index](#challenge-index)

---

### 20. Denial

> **Solution:** [20_Denial/Contract.sol](./20_Denial/Contract.sol)

#### 📋 Description
`Denial` splits 1% withdrawals between `partner` and `owner`. Become `partner` and deny `owner` from withdrawing funds even when `withdraw()` ignores `partner.call`'s return value.

#### 🔍 How to Find It
- Check low-level `.call{value: ...}("")` calls that do **not cap forwarded gas** (`gas: ...`), especially when followed by state changes or another ETH transfer (`owner.transfer()`).
- Even if a `.call()` fails cleanly, an untrusted callee can consume all remaining gas (63/64ths via EIP-150), leaving insufficient gas for the rest of the transaction.

#### ⚠️ Vulnerability (Root Cause)
`Denial.withdraw()` calls `partner.call{value: amountToSend}("")` without specifying a gas limit or checking success. While a simple `revert` in `partner` would be ignored so `owner` still gets paid, an **Out-of-Gas** error inside `partner`'s `receive()` consumes ~63/64ths of the transaction gas, leaving too little gas for `payable(owner).transfer(amountToSend)` and reverting the whole `withdraw()` call.

#### 💡 Solution Walkthrough
Deploy `hackit` and register it via `setWithdrawPartner()`. Its `receive()` enters an infinite loop (`while (true) { i++; }`), draining gas whenever `withdraw()` executes so `owner` can never receive funds.

#### 🛡️ Mitigation
Forward a fixed gas stipend if calling untrusted recipients, or — better yet — replace push calls with a **Pull Payment** pattern so partners and owners withdraw independently.

[↑ Back to Index](#challenge-index)

---

### 21. Shop

> **Solution:** [21_Shop/Contract.sol](./21_Shop/Contract.sol)

#### 📋 Description
Buy the item from `Shop` for less than its asking price (`100`), even though `IBuyer.price()` is constrained as a `view` function.

#### 🔍 How to Find It
- Flag any external **`view` function called twice** across a state transition (`isSold = true`).
- Even though `view` prevents modifying storage inside the buyer's contract, the buyer can still *read* updated state on the target contract (`shop.isSold()`) to return two different values!

#### ⚠️ Vulnerability (Root Cause)
`Shop.buy()` queries `_buyer.price()` before updating `isSold = true` and then queries `_buyer.price()` a second time afterward to record `price`. Reading `shop.isSold()` lets a `view` implementation return `>= 100` on the first check and `1` on the second.

#### 💡 Solution Walkthrough
In `HackIt`:
1. `hackit()` calls `shop.buy()`.
2. `price() external view` checks `shop.isSold()`: returns `Price1` (`100`) when `false`, and `Price2` (`1`) once `isSold` flips to `true`.

#### 🛡️ Mitigation
Cache external `view` return values in a local variable (`uint256 buyerPrice = _buyer.price();`) rather than querying an external contract twice.

[↑ Back to Index](#challenge-index)

---

### 22. Dex

> **Solution:** [22_Dex/Solution.txt](./22_Dex/Solution.txt)

#### 📋 Description
Drain all reserves of either `token1` or `token2` from the `Dex` contract starting with 10 of each token while the DEX holds 100 of each.

#### 🔍 How to Find It
- Check AMM swap pricing formulas for **spot reserve imbalance amplification** and **integer division rounding** without `k` invariant enforcement (`x * y >= k`).
- `getSwapPrice(from, to, amount) = (amount * balance(to)) / balance(from)` lets alternating full swaps compound imbalance rapidly.

#### ⚠️ Vulnerability (Root Cause)
`Dex` calculates spot exchange rates linearly from instantaneous pool balances (`(amount * reserveOut) / reserveIn`) rather than constant-product `x * y = k` curves, allowing an attacker to repeatedly swap the maximum token balance back and forth until one reserve reaches `0`.

#### 💡 Solution Walkthrough
As documented in [Solution.txt](./22_Dex/Solution.txt), alternate swapping the full user balance between `token1` and `token2` (checking updated balances after each swap so the final trade drains an entire pool token reserve to zero), and note the included Chainlink `AggregatorV3Interface` example for external oracle pricing.

#### 🛡️ Mitigation
Use proper constant-product AMM math (`x * y = k` with fee deductions) for swaps and source external asset pricing from decentralized oracle networks (e.g., Chainlink Data Feeds) or deep-liquidity TWAPs.

[↑ Back to Index](#challenge-index)

---

### 23. Dex Two

> **Solution:** [23_Dex2/Contract.sol](./23_Dex2/Contract.sol)

#### 📋 Description
Unlike `Dex`, `DexTwo` requires draining **both `token1` and `token2`** reserves down to zero.

#### 🔍 How to Find It
- Compare `DexTwo.swap()` against `Dex.swap()`: **`DexTwo` removed the `require((from == token1 && to == token2) || ...)` token validation check!**
- Anytime a DEX lets users specify arbitrary `from`/`to` ERC-20 addresses in `getSwapAmount()`, any worthless ERC-20 token becomes swappable against real reserves.

#### ⚠️ Vulnerability (Root Cause)
`DexTwo.swap(from, to, amount)` accepts any ERC-20 address for `from` without verifying it is `token1` or `token2`. Sending `1` unit of an arbitrary token to `DexTwo` gives `IERC20(badCoin).balanceOf(dex) == 1`, so calling `swap(badCoin, token1, 1)` returns `(1 * 100) / 1 = 100 token1`!

#### 💡 Solution Walkthrough
In `23_Dex2/Contract.sol`:
1. `attacker` deploys a custom ERC-20 (`BadCoin`) with `400` initial tokens.
2. `execute()` seeds `dex` with `1` `BadCoin`, approves `dex`, swaps `1 BadCoin` -> `100 token1`, then swaps `2 BadCoin` -> `100 token2` (`(2 * 100) / 2 = 100`), and transfers all drained tokens to `msg.sender`.

#### 🛡️ Mitigation
Strictly whitelist valid pool token pairs inside `swap()` (`require((from == token1 && to == token2) || (from == token2 && to == token1))`) and enforce invariant checks across supported reserves only.

[↑ Back to Index](#challenge-index)

---

### 24. Puzzle Wallet

> **Solution:** [24_Puzzle_Wallet/Contract.sol](./24_Puzzle_Wallet/Contract.sol) & [UpgradeableProxy-08.sol](./24_Puzzle_Wallet/UpgradeableProxy-08.sol)

#### 📋 Description
Become the `admin` of `PuzzleProxy` (which delegates calls to `PuzzleWallet` and starts holding `0.001 ETH`).

#### 🔍 How to Find It
- Always align **storage layouts across Proxy and Implementation contracts**:
  - `PuzzleProxy`: slot `0` = `pendingAdmin`, slot `1` = `admin`
  - `PuzzleWallet`: slot `0` = `owner`, slot `1` = `maxBalance`
- Check batching functions (`multicall`) that loop over `delegatecall`s on `payable` calls: **does an inner `multicall` reset the `depositCalled` flag while preserving `msg.value`?**

#### ⚠️ Vulnerability (Root Cause)
1. **Storage Slot Collision:** Calling `proxy.proposeNewAdmin(attacker)` writes slot `0` (`pendingAdmin`), overwriting `PuzzleWallet.owner` so `attacker` can call `addToWhitelist()`. Similarly, calling `setMaxBalance()` writes slot `1`, overwriting `PuzzleProxy.admin`.
2. **Nested `multicall` `msg.value` Reuse:** `PuzzleWallet.multicall()` initializes `bool depositCalled = false` locally per `multicall()` call. Wrapping a `deposit()` inside a nested `multicall()` bypasses the flag and credits `msg.value` twice in `balances[]`, allowing `execute()` to drain the contract to `0` ETH so `setMaxBalance()` succeeds.

#### 💡 Solution Walkthrough
In `Attacker.execute()`:
1. Calls `proxy.proposeNewAdmin(address(this))` to become `wallet.owner()` via slot 0 collision, then whitelists `address(this)` and `msg.sender`.
2. Constructs a `multicall{value: 0.001 ether}` payload containing `[deposit(), multicall([deposit()])]`, crediting `0.002 ether` internal balance while spending only `0.001 ether`.
3. Calls `wallet.execute(msg.sender, 0.002 ether, "")` to drain the proxy's ETH balance to `0`.
4. Calls `wallet.setMaxBalance(uint256(uint160(msg.sender)))`, overwriting slot 1 (`PuzzleProxy.admin`) with `msg.sender`.

#### 🛡️ Mitigation
Never store proxy state in standard sequential slots `0`/`1` when delegating to an implementation (use **EIP-1967** randomized storage slots), and avoid mixing `payable` functions with `delegatecall` `multicall` loops (or pass value tracking explicitly rather than reusing `msg.value`).

[↑ Back to Index](#challenge-index)

---

### 25. Motorbike

> **Solution:** [25_MotorBike/Contract.sol](./25_MotorBike/Contract.sol)

#### 📋 Description
`Motorbike` is an EIP-1967 proxy delegating to an `Engine` UUPS implementation. Destroy the underlying `Engine` contract (`selfdestruct`) so `Motorbike` becomes unusable.

#### 🔍 How to Find It
- In **UUPS upgradeable contracts**, check the **implementation contract itself** (not just the proxy!):
  - Was `initialize()` only executed via `delegatecall` during proxy deployment, leaving `initialize()` uncalled on the implementation contract's own storage?
  - Does the implementation constructor call `_disableInitializers()`?

#### ⚠️ Vulnerability (Root Cause)
`Motorbike`'s constructor ran `delegatecall("initialize()")`, initializing proxy storage while leaving `Engine`'s own storage (`upgrader == address(0)`, `initialized == false`) uninitialized! Any external caller can call `Engine.initialize()` directly on the implementation contract to become `upgrader`, then upgrade `Engine` via `upgradeToAndCall()` to a contract invoking `selfdestruct`. *(Note: On Ethereum mainnet post-EIP-6780, `selfdestruct` no longer clears runtime code unless invoked in the same transaction as contract creation.)*

#### 💡 Solution Walkthrough
In `MotorbikeAttack.attack()`:
1. Calls `engine.initialize()` directly on the `Engine` contract to set `upgrader = address(this)`.
2. Deploys `Destruction` (exposing `destroy() { selfdestruct(payable(address(0))); }`).
3. Calls `engine.upgradeToAndCall(address(destruction), abi.encodeWithSignature("destroy()"))` to delegatecall into `Destruction.destroy()` and wipe `Engine`.

#### 🛡️ Mitigation
Always invoke `_disableInitializers()` in upgradeable implementation constructors (standard in OpenZeppelin `Initializable` >= v4.x), and keep `upgradeTo` / `selfdestruct` mechanics separated from proxy logic.

[↑ Back to Index](#challenge-index)

---

### 31. Stake

> **Solution:** [31_Stake/Contract.sol](./31_Stake/Contract.sol)

#### 📋 Description
Drain the `Stake` contract's ETH balance below its tracked `totalStaked` (`address(stake).balance > 0`, `totalStaked > address(stake).balance`), while `player`'s `UserStake[player] == 0` and `Stakers[player] == true`.

#### 🔍 How to Find It
- Audit low-level `.call(...)` invocations to ERC-20 `transferFrom`: **does the contract inspect both `(bool success, bytes memory data)` AND revert if `success == false` or `abi.decode(data, (bool)) == false`?**
- Check if `StakeETH` and `StakeWETH` share a single `UserStake` / `totalStaked` ledger while `Unstake` only transfers native ETH!

#### ⚠️ Vulnerability (Root Cause)
`Stake.StakeWETH(uint256 amount)` checks WETH allowance, increments `totalStaked += amount` and `UserStake[msg.sender] += amount`, and performs `(bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, ...))` **without reverting when `transferFrom` fails** (e.g., when the caller has WETH allowance set but `0` WETH balance!). Meanwhile, `Unstake()` always withdraws native ETH.

#### 💡 Solution Walkthrough
In `31_Stake/Contract.sol`:
1. `player` interacts directly with `Stake` (`StakeETH` + `Unstake`) so `Stakers[player] == true` and `UserStake[player] == 0`.
2. `Attacker.execute()` stakes `0.01 ether` via `StakeETH`, approves `stake` for max WETH spending, and calls `stake.StakeWETH(0.05 ether)` with `0` WETH balance — inflating `totalStaked` without depositing WETH, leaving `totalStaked > address(stake).balance` after ETH withdrawal.

#### 🛡️ Mitigation
Use OpenZeppelin's `SafeERC20.safeTransferFrom()` (which validates both call success and optional boolean return values), keep ETH and ERC-20 accounting separate, and update state only after verified transfers succeed.

[↑ Back to Index](#challenge-index)

---

### 34. Bet House

> **Solution:** [34_Bet_House/Contract.sol](./34_Bet_House/Contract.sol)

#### 📋 Description
Become a registered bettor (`bet.isBettor(player) == true`) on `BetHouse`, which requires holding `>= 20` wrapped tokens (`Pool(pool).balanceOf(msg.sender) >= 20`) and locking deposits (`Pool(pool).depositsLocked(msg.sender) == true`) starting with only `5` Pool Deposit Tokens (PDT) and `0.001 ether` deposit allowance.

#### 🔍 How to Find It
- Inspect `Pool.withdrawAll()`: it carries `nonReentrant`, transfers `depositedPDT` and sends `depositedEther` via `.call{value: ...}("")`, and **only burns `wrappedToken` on the very last line** (`PoolToken(wrappedToken).burn(...)`).
- Check which functions lack `nonReentrant`: `deposit()`, `lockDeposits()`, and `BetHouse.makeBet()` have **no reentrancy guard**!

#### ⚠️ Vulnerability (Root Cause)
Cross-function reentrancy in `Pool.withdrawAll()`:
```solidity
if (_depositedValue > 0) {
    depositedEther[msg.sender] = 0;
    payable(msg.sender).call{value: _depositedValue}("");
}
PoolToken(wrappedToken).burn(msg.sender, balanceOf(msg.sender));
```
When `withdrawAll()` sends back the `0.001 ether` deposit, execution transfers to `msg.sender`'s `receive()` **before** the `15` wrapped tokens (`10` from ETH + `5` from PDT) are burned — and after `depositedPDT[msg.sender]` was already reset and returned! Inside `receive()`, an attacker can re-deposit the `5` returned PDT to mint `5` *more* wrapped tokens (`20` total), call `lockDeposits()`, and call `bet.makeBet()` before `withdrawAll()` finishes and burns the balance.

#### 💡 Solution Walkthrough
In `34_Bet_House/Contract.sol`, `Attacker`:
1. `execute()` pulls `5` PDT from `msg.sender`, approves `pool`, calls `Pool(pool).deposit{value: 0.001 ether}(5)` (minting `10 + 5 = 15` wrapped tokens), and calls `Pool(pool).withdrawAll()`.
2. Inside `receive()` (triggered when `withdrawAll()` refunds `0.001 ether`), re-deposits the returned `5` PDT (`Pool(pool).deposit(5)`, raising wrapped balance to `20`), calls `Pool(pool).lockDeposits()`, and calls `bet.makeBet(owner)` to register `owner` as a bettor before `burn()` executes.

#### 🛡️ Mitigation
Burn `wrappedToken` *before* transferring PDT or ETH inside `withdrawAll()` (strict CEI), and guard all state-mutating `Pool` functions (`deposit`, `withdrawAll`, `lockDeposits`) with shared `nonReentrant` protection.

[↑ Back to Index](#challenge-index)

---

## Setup & Usage

1. Each challenge directory contains the original Ethernaut contract(s) and my corresponding solution contract or RPC/console notes.
2. You can compile and deploy any `.sol` level directly in **[Remix IDE](https://remix.ethereum.org/)** or import them into a Foundry/Hardhat environment targeting the Ethernaut testnet instance.

---

> **Disclaimer:** All contracts and notes are strictly for smart contract security education and auditing practice.
