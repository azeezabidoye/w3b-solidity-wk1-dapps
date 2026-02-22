// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "./IERC20.sol";

contract SchoolManagement {
    address tokenAddress;
    address public owner; // Deployer's address
    uint256 public totalFeesETH; // Total balance of the school fund in Ether
    uint256 public totalFeesERC20; // Total balance of the school fund in ERC20

    struct Student {
        string studentName;
        uint256 grade;
        bool hasPaid;
        uint256 paidTimestamp;
    }

    struct Staff {
        string staffName;
        bool isRegistered;
        bool salaryPaid;
        bool isSuspended;
        uint256 salaryTimestamp;
    }

    mapping(address => Student) public students;
    address[] public studentList;

    mapping(address => Staff) public staff;
    address[] public staffList;

    mapping(uint256 => uint256) public gradeFees;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        gradeFees[100] = 0.1 ether; // 0.1 ETH.
        gradeFees[200] = 0.2 ether;
        gradeFees[300] = 0.3 ether;
        gradeFees[400] = 0.4 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only school admin");
        _;
    }

    // EVENTS
    event StudentRegistered(
        address indexed student,
        string name,
        uint256 grade
    );
    event FeesPaid(address indexed student, uint256 amount, uint256 timestamp);
    event StaffRegistered(address indexed staff, string name);
    event SalaryPaid(address indexed staff, uint256 amount, uint256 timestamp);
    event StaffSuspended(address indexed staff);

    function registerStudentETH(
        string memory _studentName,
        uint256 _grade
    ) public payable {
        require(
            _grade >= 100 && _grade <= 400 && _grade % 100 == 0,
            "Grade not valid"
        );

        // Define school fess
        uint256 schoolFees = gradeFees[_grade];
        require(msg.value == schoolFees, "Exact school fee required");
        require(
            students[msg.sender].hasPaid == false,
            "Student already registered"
        );

        // Register new student
        students[msg.sender] = Student({
            studentName: _studentName,
            grade: _grade,
            hasPaid: true,
            paidTimestamp: block.timestamp
        });
        studentList.push(msg.sender);

        // Add schools to school account
        totalFeesETH = totalFeesETH + msg.value;

        // Log registration & school fess payment events
        emit StudentRegistered(msg.sender, _studentName, _grade);
        emit FeesPaid(msg.sender, msg.value, block.timestamp);
    }

    function registerStaff(
        address _staffAcct,
        string memory _staffName
    ) public onlyOwner {
        require(staff[_staffAcct].salaryPaid == false, "Already registered");

        // Register new Staff
        staff[_staffAcct] = Staff({
            staffName: _staffName,
            isRegistered: true,
            salaryPaid: false,
            isSuspended: false,
            salaryTimestamp: 0
        });
        staffList.push(_staffAcct);

        // Log registration
        emit StaffRegistered(_staffAcct, _staffName);
    }

    function suspendStaff(address _staffAcct) public onlyOwner {
        require(staff[_staffAcct].isRegistered, "Staff not registered");
        require(!staff[_staffAcct].isSuspended, "Staff already suspended");
        staff[_staffAcct].isSuspended = true;
        emit StaffSuspended(_staffAcct);
    }

    function payStaffSalaryETH(
        address _staffAcct,
        uint256 _salaryAmount
    ) public payable onlyOwner {
        require(staff[_staffAcct].isRegistered, "Staff not registered");
        require(!staff[_staffAcct].salaryPaid, "Salary already paid");
        require(!staff[_staffAcct].isSuspended, "Staff already suspended");
        require(msg.value >= _salaryAmount, "Insufficient school funds");

        // Pay Staff
        staff[_staffAcct].salaryPaid = true;
        staff[_staffAcct].salaryTimestamp = block.timestamp;

        totalFeesETH = totalFeesETH - _salaryAmount;

        // Pay using call() method
        (bool success, ) = _staffAcct.call{value: _salaryAmount}("");
        require(success, "Payment failed");

        // Log event for salary payment
        emit SalaryPaid(_staffAcct, _salaryAmount, block.timestamp);
    }

    function resetStaffSalary(address _staffAcct) public onlyOwner {
        require(staff[_staffAcct].isRegistered, "Staff not registered");

        staff[_staffAcct].salaryPaid = false;
    }

    function getAllStudents() external view returns (address[] memory) {
        return studentList;
    }

    function getAllStaff() external view returns (address[] memory) {
        return staffList;
    }

    function registerStudentERC20(
        string memory _studentName,
        uint256 _grade,
        uint256 _amount
    ) public {
        require(
            _grade >= 100 && _grade <= 400 && _grade % 100 == 0,
            "Grade not valid"
        );

        // Define school fess
        uint256 schoolFees = gradeFees[_grade];
        require(_amount == schoolFees, "Exact school fee required");
        require(
            students[msg.sender].hasPaid == false,
            "Student already registered"
        );

        // Register new student
        students[msg.sender] = Student({
            studentName: _studentName,
            grade: _grade,
            hasPaid: true,
            paidTimestamp: block.timestamp
        });
        studentList.push(msg.sender);

        // Add schools to school account
        totalFeesERC20 = totalFeesERC20 + _amount;

        // Students pays using ZTK (ERC20) Token
        bool regStudentFee = IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(regStudentFee, "Failed to pay school fees");

        // Log registration & school fess payment events
        emit StudentRegistered(msg.sender, _studentName, _grade);
        emit FeesPaid(msg.sender, _amount, block.timestamp);
    }

    function payStaffSalaryERC20(
        address _staffAcct,
        uint256 _salaryAmount
    ) public onlyOwner {
        require(staff[_staffAcct].isRegistered, "Staff not registered");
        require(!staff[_staffAcct].salaryPaid, "Salary already paid");
        require(!staff[_staffAcct].isSuspended, "Staff already suspended");
        require(_salaryAmount < totalFeesERC20, "Insufficient school funds");

        // Pay Staff
        staff[_staffAcct].salaryPaid = true;
        staff[_staffAcct].salaryTimestamp = block.timestamp;

        totalFeesERC20 = totalFeesERC20 - _salaryAmount;

        // Pay using call() method
        // (bool success, ) = _staffAcct.call{value: _salaryAmount}("");
        // require(success, "Payment failed");

        bool paySalarySuccess = IERC20(tokenAddress).transfer(
            _staffAcct,
            _salaryAmount
        );
        require(paySalarySuccess, "Payment failed");

        // Log event for salary payment
        emit SalaryPaid(_staffAcct, _salaryAmount, block.timestamp);
    }
}
