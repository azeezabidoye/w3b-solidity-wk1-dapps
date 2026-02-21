// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.3;

// contract SchoolManagement {
//     address public owner; // Deployer/Admin address
//     uint256 public totalFees; // Total balance of the school fund

//     struct Student {
//         string studentName;
//         uint256 grade;
//         bool hasPaid;
//         uint256 paidTimestamp;
//     }

//     struct Staff {
//         string staffName;
//         bool isRegistered;
//         bool salaryPaid;
//         uint256 salaryTimestamp;
//     }

//     mapping(address => Student) public students;
//     address[] public studentList;

//     mapping(address => Staff) public staff;
//     address[] public staffList;

//     mapping(uint256 => uint256) public gradeFees;

//     constructor() {
//         owner = msg.sender;
//         gradeFees[100] = 0.1 ether; // 0.1 ETH.
//         gradeFees[200] = 0.2 ether;
//         gradeFees[300] = 0.3 ether;
//         gradeFees[400] = 0.4 ether;
//     }

//     modifier onlyOwner() {
//         require(msg.sender == owner, "Only school admin");
//         _;
//     }

//     // EVENTS
//     event StudentRegistered(
//         address indexed student,
//         string name,
//         uint256 grade
//     );
//     event FeesPaid(address indexed student, uint256 amount, uint256 timestamp);
//     event StaffRegistered(address indexed staff, string name);
//     event SalaryPaid(address indexed staff, uint256 amount, uint256 timestamp);

//     function registerStudent(
//         string memory _studentName,
//         uint256 _grade
//     ) public payable {
//         require(
//             _grade >= 100 && _grade <= 400 && _grade % 100 == 0,
//             "Grade not valid"
//         );

//         // Define school fess
//         uint256 schoolFees = gradeFees[_grade];
//         require(msg.value == schoolFees, "Exact school fee required");
//         require(
//             students[msg.sender].hasPaid == false,
//             "Student already registered"
//         );

//         // Register new student
//         students[msg.sender] = Student({
//             studentName: _studentName,
//             grade: _grade,
//             hasPaid: true,
//             paidTimestamp: block.timestamp
//         });
//         studentList.push(msg.sender);

//         // Add schools to school account
//         totalFees = totalFees + msg.value;

//         // Log registration & school fess payment events
//         emit StudentRegistered(msg.sender, _studentName, _grade);
//         emit FeesPaid(msg.sender, msg.value, block.timestamp);
//     }

//     function registerStaff(
//         address _staffAcct,
//         string memory _staffName
//     ) public onlyOwner {
//         require(staff[_staffAcct].salaryPaid == false, "Already registered");

//         // Register new Staff
//         staff[_staffAcct] = Staff({
//             staffName: _staffName,
//             isRegistered: true,
//             salaryPaid: false,
//             salaryTimestamp: 0
//         });
//         staffList.push(_staffAcct);

//         // Log registration
//         emit StaffRegistered(_staffAcct, _staffName);
//     }

//     function payStaffSalary(
//         address _staffAcct,
//         uint256 _salaryAmount
//     ) public payable onlyOwner {
//         require(staff[_staffAcct].isRegistered, "Staff not registered");
//         require(!staff[_staffAcct].salaryPaid, "Salary already paid");
//         require(msg.value >= _salaryAmount, "Insufficient school funds");

//         // Pay Staff
//         staff[_staffAcct].salaryPaid = true;
//         staff[_staffAcct].salaryTimestamp = block.timestamp;

//         totalFees = totalFees - _salaryAmount;

//         // Pay using call() method
//         (bool success, ) = _staffAcct.call{value: _salaryAmount}("");
//         require(success, "Payment failed");

//         // Log event for salary payment
//         emit SalaryPaid(_staffAcct, _salaryAmount, block.timestamp);
//     }

//     function resetStaffSalary(address _staffAcct) public onlyOwner {
//         require(staff[_staffAcct].isRegistered, "Staff not registered");

//         staff[_staffAcct].salaryPaid = false;
//     }

//     function getAllStudents() external view returns (address[] memory) {
//         return studentList;
//     }

//     function getAllStaff() external view returns (address[] memory) {
//         return staffList;
//     }
// }
