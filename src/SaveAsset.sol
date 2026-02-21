// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import {IERC20} from "./IERC20.sol";

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}

contract SaveAsset {
    address token_address;

    constructor(address _token_address) {
        token_address = _token_address;
    }

    mapping(address => uint256) public balances;

    mapping(address => uint256) erc20Savingsbalance;

    event DepositSuccessful(address indexed sender, uint256 indexed amount);

    event WithdrawalSuccessful(
        address indexed receiver,
        uint256 indexed amount,
        bytes data
    );

    function deposit() external payable {
        // require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "Can't deposit zero value");

        balances[msg.sender] = balances[msg.sender] + msg.value;

        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender != address(0), "Address zero detected");

        // the balance mapping is a key to value pair, if the key is
        // provided it retuns the value at that location.
        //
        uint256 userSavings_ = balances[msg.sender];

        require(userSavings_ > 0, "Insufficient funds");

        balances[msg.sender] = userSavings_ - _amount;

        // (bool result,) = msg.sender.call{value: msg.value}("");
        (bool result, bytes memory data) = payable(msg.sender).call{
            value: _amount
        }("");

        require(result, "transfer failed");

        emit WithdrawalSuccessful(msg.sender, _amount, data);
    }

    function getUserSavings() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function depositERC20(uint256 _amount) external {
        require(_amount > 0, "Can't send zero value");

        require(
            IERC20(token_address).balanceOf(msg.sender) >= _amount,
            "Insufficient funds"
        );

        erc20Savingsbalance[msg.sender] =
            erc20Savingsbalance[msg.sender] +
            _amount;

        require(
            IERC20(token_address).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "transfer failed"
        );

        emit DepositSuccessful(msg.sender, _amount);
    }

    function withdrawERC20(uint256 _amount) external {
        require(_amount > 0, "Can't send zero value");

        require(
            erc20Savingsbalance[msg.sender] >= _amount,
            "Not enough savings"
        );

        erc20Savingsbalance[msg.sender] =
            erc20Savingsbalance[msg.sender] -
            _amount;

        require(
            IERC20(token_address).transfer(msg.sender, _amount),
            "transfer failed"
        );

        emit WithdrawalSuccessful(msg.sender, _amount, "");
    }

    function getErc20SavingsBalance() external view returns (uint256) {
        return erc20Savingsbalance[msg.sender];
    }

    receive() external payable {}

    fallback() external {}
}
