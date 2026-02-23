// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// ============================================================
// ERC20 TOKEN CONTRACT — WEB3CXIV (CXIV)
// ============================================================
// Think of this contract like a BANK that issues its own currency.
// Just like a country prints its own money (e.g. Naira, Dollar),
// this contract creates and manages a digital token called CXIV.
//
// Every person who owns CXIV has an account (wallet address),
// and this contract keeps track of everyone's balances,
// just like how a bank keeps records of every customer's account.
// ============================================================

contract ERC20 {

    // The official name of this token as it appears on exchanges like Uniswap or Binance.
    // Think of this as the full brand name of the currency — like "United States Dollar"
    string constant NAME = "WEB3CXIV";

    // The short ticker symbol used to represent the token on exchanges.
    // Just like "USD" stands for United States Dollar, "CXIV" is the short form of WEB3CXIV.
    string constant SYMBOL = "CXIV";

    // Tokens on the blockchain are stored as whole numbers (no decimals natively).
    // So to represent 1 CXIV, the contract actually stores 1,000,000,000,000,000,000 (18 zeros).
    // This means: 1 CXIV = 1 * 10^18 units. This is the same way 1 Dollar = 100 Cents,
    // except here we go much smaller — giving more precision for tiny transactions.
    uint8 constant DECIMAL = 18;

    // This keeps a running total of ALL tokens that have ever been created (minted).
    // If 1000 CXIV tokens have been minted in total across all users,
    // this variable will hold: 1000 * 10^18
    uint256 total_supply;

    // This is a ledger — like a spreadsheet — that maps every wallet address to their token balance.
    // Example: balances[0xAlice] = 500 means Alice holds 500 CXIV tokens.
    mapping(address => uint256) balances;

    // This is a two-level ledger that tracks how much one address (a spender)
    // is allowed to spend on behalf of another address (the owner).
    //
    // Real-world example: You give your accountant permission to pay up to $200 from your account.
    // allowances[yourAddress][accountantAddress] = 200
    //
    // This is how DEXes (like Uniswap) can move tokens on your behalf when you trade.
    mapping(address => mapping(address => uint256)) allowances;

    // This event is like a receipt that gets recorded on the blockchain whenever tokens move.
    // Anyone watching the blockchain (e.g. Etherscan) can see: 
    // "Alice sent 50 CXIV to Bob at block #12345"
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // This event gets recorded whenever an owner gives a spender permission to use their tokens.
    // Example: "Alice approved Uniswap to spend up to 100 CXIV on her behalf"
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    // -------------------------------------------------------
    // READ-ONLY (VIEW) FUNCTIONS
    // These functions just return information. They don't change
    // anything on the blockchain and cost no gas to call.
    // -------------------------------------------------------

    // Returns the full name of the token.
    // Calling this function will return: "WEB3CXIV"
    function name() external view returns (string memory) {
        return NAME;
    }

    // Returns the short ticker symbol of the token.
    // Calling this function will return: "CXIV"
    function symbol() external view returns (string memory) {
        return SYMBOL;
    }

    // Returns the number of decimal places used by this token.
    // Calling this function will return: 18
    // This tells wallets like MetaMask how to display balances correctly.
    // Without this, MetaMask wouldn't know that 1000000000000000000 = 1.0 CXIV
    function decimals() external view returns (uint8) {
        return DECIMAL;
    }

    // Returns the total number of tokens that currently exist across ALL wallets.
    // Example: If 5 people minted 200 CXIV each, totalSupply() returns 1000 CXIV (in 10^18 units).
    function totalSupply() external view returns (uint256) {
        return total_supply;
    }

    // Returns the token balance of any wallet address you pass in.
    // Example: balanceOf(0xAlice) returns how many CXIV tokens Alice currently holds.
    // Think of it as calling the bank to ask: "What is the balance in account #XYZ?"
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }


    // -------------------------------------------------------
    // MINT FUNCTION — Creating New Tokens
    // -------------------------------------------------------
    // This function creates brand new CXIV tokens out of thin air and assigns them
    // to a specific wallet. It's like a central bank printing new money.
    //
    // Example: mint(0xAlice, 500 * 10^18) creates 500 new CXIV tokens
    // and deposits them directly into Alice's wallet.
    //
    // Two things happen every time tokens are minted:
    //   1. The total_supply goes up (more tokens exist in the world)
    //   2. The recipient's balance goes up (they now hold those tokens)
    //
    // WARNING: In a production token, this function would normally be
    // restricted to only the contract owner. Here it is open to anyone — 
    // which means anyone can mint tokens. This is fine for learning purposes.
    function mint(address _owner, uint256 _amount) external {

        // Safety check: address(0) is the "burn address" — a black hole with no owner.
        // Sending tokens there means they're gone forever. We prevent that here.
        require(_owner != address(0), "Can't transfer to address zero");

        // Increase the global total supply to reflect the new tokens being created.
        // Example: If total_supply was 1000 and we mint 200 more, it becomes 1200.
        total_supply = total_supply + _amount;

        // Deposit the newly minted tokens directly into the recipient's balance.
        // Example: If Alice had 100 CXIV and we mint 200 for her, she now has 300.
        balances[_owner] = balances[_owner] + _amount;
    }


    // -------------------------------------------------------
    // TRANSFER FUNCTION — Sending Tokens to Someone
    // -------------------------------------------------------
    // This is the most basic token action: YOU sending YOUR tokens to someone else.
    // Example: Alice calls transfer(0xBob, 50) to send 50 CXIV directly to Bob.
    //
    // The caller of this function (msg.sender) is always the one sending the tokens.
    // No one can call this function to move tokens out of someone else's wallet.
    function transfer(address _to, uint256 _value) external returns (bool success) {

        // You can't send tokens to the "burn address" (address zero).
        // It has no owner — tokens sent there are lost forever.
        require(_to != address(0), "Can't transfer to address zero");

        // Sending zero tokens makes no sense and wastes gas. We block that here.
        require(_value > 0, "Can't send zero value");

        // Make sure the sender actually has enough tokens to cover the transfer.
        // Example: If Alice only has 30 CXIV but tries to send 50, this check stops her.
        require(balances[msg.sender] >= _value, "Insufficient funds");

        // Deduct the tokens from the sender's balance.
        // Example: Alice had 100 CXIV. After sending 50, she has 50.
        balances[msg.sender] = balances[msg.sender] - _value;

        // Add the tokens to the recipient's balance.
        // Example: Bob had 20 CXIV. After receiving 50 from Alice, he has 70.
        balances[_to] = balances[_to] + _value;

        // Record the transfer permanently on the blockchain as an event/receipt.
        emit Transfer(msg.sender, _to, _value);

        // Return true to signal to any calling contract that the transfer succeeded.
        return true;
    }


    // -------------------------------------------------------
    // TRANSFER FROM — A Spender Sending Tokens on Your Behalf
    // -------------------------------------------------------
    // This function allows a pre-approved third party (a "spender") to move tokens
    // OUT of the token owner's wallet and into another wallet.
    //
    // Real-world example:
    //   - Alice approves Uniswap to spend up to 100 CXIV on her behalf (via approve()).
    //   - When Alice places a trade on Uniswap, Uniswap calls transferFrom() to move
    //     Alice's 100 CXIV into the liquidity pool — without Alice needing to do anything else.
    //
    // Another example: Think of giving your spouse a debit card linked to your account.
    // They (the spender) can spend FROM your account (the owner) and send TO a merchant.
    //
    // Parameters:
    //   _from  = the wallet whose tokens are being moved (the owner who gave approval)
    //   _to    = the wallet receiving the tokens
    //   _value = the number of tokens to move
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {

        // The recipient address must be valid — not the dead/burn address.
        require(_to != address(0), "Can't transfer to address zero");

        // Moving zero tokens is pointless. Block it to avoid empty transactions.
        require(_value > 0, "Can't send zero value");

        // Make sure the token owner (_from) actually has enough tokens in their wallet.
        // Example: If Alice only has 30 CXIV but someone tries to move 50, this stops it.
        require(balances[_from] >= _value, "allowance is greater than your balance");

        // Make sure the spender (msg.sender) hasn't exceeded the allowance the owner gave them.
        // Example: If Alice approved Uniswap for 100 CXIV but Uniswap tries to move 150, this blocks it.
        require(_value <= allowances[_from][msg.sender], "Insufficient allowance");

        // Deduct the tokens from the owner's wallet balance.
        // Example: Alice had 200 CXIV. After Uniswap moves 100, she has 100.
        balances[_from] = balances[_from] - _value;

        // Deposit the tokens into the recipient's wallet.
        // Example: The liquidity pool receives the 100 CXIV from Alice.
        balances[_to] = balances[_to] + _value;

        // Reduce the spender's remaining allowance by the amount just used.
        // This prevents Uniswap from spending Alice's tokens more than she approved.
        // Example: Alice approved 100 CXIV. After Uniswap spends 100, the remaining allowance is 0.
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;

        // Record the transfer event on the blockchain.
        emit Transfer(_from, _to, _value);

        // Return true to confirm the transfer was successful.
        return true;
    }


    // -------------------------------------------------------
    // APPROVE — Giving a Spender Permission to Use Your Tokens
    // -------------------------------------------------------
    // Before a third party (like a DEX or another contract) can call transferFrom(),
    // the token owner must first call this function to grant them permission.
    //
    // This does NOT move any tokens. It simply sets a spending limit.
    //
    // Real-world example:
    //   You walk into a car dealership and sign a form saying:
    //   "I authorize this dealership to charge up to $5,000 from my account."
    //   The dealership now has your approval but hasn't taken any money yet.
    //   That happens later when they process the payment (transferFrom).
    //
    // Important: Calling approve() again with a new amount OVERWRITES the old allowance.
    // So if you accidentally approved $1000 but meant $100, just call approve() again with $100.
    //
    // Parameters:
    //   _spender = the address being given permission (e.g. a DEX contract)
    //   _value   = the maximum amount they are allowed to spend
    function approve(address _spender, uint256 _value) external returns (bool success) {

        // The spender must be a real address — not the dead/burn address.
        require(_spender != address(0), "Can't transfer to address zero");

        // Approving zero tokens makes no practical sense. Block it.
        require(_value > 0, "Can't send zero value");

        // Make sure you're not approving more than you actually own.
        // Example: You can't give Uniswap permission to spend 500 CXIV if you only have 200.
        require(balances[msg.sender] >= _value, "allowance is greater than your balance");

        // Record the approved spending limit for the spender in the allowances ledger.
        // This REPLACES any previous approval — it does not add to it.
        // Example: allowances[Alice][Uniswap] = 100 means Uniswap can spend up to 100 of Alice's CXIV.
        allowances[msg.sender][_spender] = _value;

        // Record the approval event on the blockchain.
        emit Approval(msg.sender, _spender, _value);

        // Return true to confirm the approval was recorded.
        return true;
    }


    // -------------------------------------------------------
    // ALLOWANCE — Checking How Much a Spender is Allowed to Use
    // -------------------------------------------------------
    // This is a read-only function that lets anyone check how much
    // a specific spender is allowed to spend from a specific owner's wallet.
    //
    // Example: allowance(0xAlice, 0xUniswap) returns how many CXIV tokens
    // Uniswap is still allowed to spend from Alice's wallet.
    // If Alice approved 100 and Uniswap has spent 60, this returns 40.
    //
    // Parameters:
    //   _owner   = the wallet that gave the approval
    //   _spender = the address that was given spending permission
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}
