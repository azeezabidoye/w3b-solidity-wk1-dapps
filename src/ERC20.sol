// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract ERC20 {
    // Name of Token on DEX
    string constant NAME = "WEB3CXIV";

    // Symbol of Token on Dex
    string constant SYMBOL = "CXIV";

    // Decimal places ===> always 18 zeros
    uint8 constant DECIMAL = 18;

    // The maximum amount that was created at deployment
    uint256 total_supply;

    // Tracks the address of each user to their balances
    mapping(address => uint256) balances;

    // Tracks the address of each Spender to their allowances ==> stipulated amount that they are allowed to spend
    mapping(address => mapping(address => uint256)) allowances;

    // Event for Sending from current user to another wallet
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event for Current user to approve DEX spend on his behalf
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Function returns the Name of Token ==> WEB3CXIV
    function name() external view returns (string memory) {
        return NAME;
    }

    // Function returns the Token symbol ==> CXIV
    function symbol() external view returns (string memory) {
        return SYMBOL;
    }

    // Function returns the Decimal places of the Token ==> 1 *  10 ** 18
    function decimals() external view returns (uint8) {
        return DECIMAL;
    }

    // Function returns the maximum amount of Token available
    function totalSupply() external view returns (uint256) {
        return total_supply;
    }

    // Function returns balance of the each User
    // Returns the balance of any address passed into the function as arguement
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    // Function allows User to create new Tokens
    // Funtion adds the newly created tokens to the Total Supply
    // Function adds the newly created tokens to the Balance of the User
    function mint(address _owner, uint256 _amount) external {
        // Condition to prevent account fron being Address-zero
        require(_owner != address(0), "Can't transfer to address zero");

        // Minted (created) Token is added to the Total Supply
        total_supply = total_supply + _amount;

        // The Minted Token is added to the Balance of the User
        balances[_owner] = balances[_owner] + _amount;
    }

    //
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success) {
        // Checking if the address is valid or not Address-zero
        require(_to != address(0), "Can't transfer to address zero");

        // Checking if the amount the user wants to send is above zero
        require(_value > 0, "Can't send zero value");

        // Checking if the balance of the user is greater than the amount he intends to send
        require(balances[msg.sender] >= _value, "Insufficient funds");

        // Deducts the amount from the User's balance
        balances[msg.sender] = balances[msg.sender] - _value;

        // Adds the amount to the Recipient's wallet
        balances[_to] = balances[_to] + _value;

        // Logs the transaction event
        emit Transfer(msg.sender, _to, _value);

        // Returns success after transaction goes through
        return true;
    }

    // Function allows a Spender to spend the allocated funds approved for them
    // e.g a DEX can do some transactions on behalf of the Wallet
    // e.g DEX can subscribe for Netflix without the User opening the App...since he has scheduled it
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        // Checking if recipient address is valid and not address-zero
        require(_to != address(0), "Can't transfer to address zero");

        // Checking if the intended amount is more than zero
        require(_value > 0, "Can't send zero value");

        // Checking if the User's balance is more than the intended amount
        require(
            balances[_from] >= _value,
            "allowance is greater than your balance"
        );

        // Checking if the amount is less or equal to the allowance allocated to the Spender
        require(
            _value <= allowances[_from][msg.sender],
            "Insufficient allowance"
        );

        // Deducts amount from the User's balance
        balances[_from] = balances[_from] - _value;

        // Adds amount to Spender's balance
        balances[_to] = balances[_to] + _value;

        // Reduces the allowance of the Spender...since Spender is already spending little by little
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;

        // Logs transaction details after succesful transaction
        emit Transfer(_from, _to, _value);

        // Returns success if transaction goes well
        return true;
    }

    // Function Approves Spender to spend on User's behalf
    // Function doesn't add money to Spender's wallet but gives Spender the room to take from User
    // e.g function gives autonomy to DEX to spend from a wallet
    // e.g this function gives a DEX the right to subscribe Netflix as scheduled by the User
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success) {
        // Checks if spender is not address zero
        require(_spender != address(0), "Can't transfer to address zero");

        // Checks if value is greater than zero
        require(_value > 0, "Can't send zero value");

        // Checks if User's balance is greater than the amount he wants to allocate to a Spender
        require(
            balances[msg.sender] >= _value,
            "allowance is greater than your balance"
        );

        // Stores the amount to be allocated to a Spender
        // This logic overrides previous approval is there is a mistake
        // That is the amount is not added to Spender's account but an avenue for Spender to spend up to the amount
        // e.g if User intends to give Spender the chance to spend $10 but approves $100
        // User can quickly re-use this function to reset the amount to $10
        allowances[msg.sender][_spender] = _value;

        // Logs transaction reciept
        emit Approval(msg.sender, _spender, _value);

        // Returns success after transaction
        return true;
    }

    // Function returns the allowance allocated to a Spender e.g DEX
    // Function takes the Address of User and Address of Spender the user has approved
    // Finally Returns the amount the User approved for the Spender
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}
