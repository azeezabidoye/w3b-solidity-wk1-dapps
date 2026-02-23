// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "./IERC20.sol";

// ============================================================
// SCHOOL MANAGEMENT CONTRACT
// ============================================================
// This smart contract acts like a school's administrative system
// — fully automated and living on the blockchain.
//
// It handles two main groups of people:
//   1. STUDENTS  — who register and pay school fees
//   2. STAFF     — who are hired and paid their salaries
//
// Payments can be made in two ways:
//   A. ETH       — the native cryptocurrency of Ethereum
//   B. ERC20     — using CXIV, the custom token from our ERC20 contract
//
// The school's admin (the contract deployer / owner) is the only one
// who can register staff, suspend staff, and pay salaries.
// Students, on the other hand, register and pay fees themselves.
// ============================================================

contract SchoolManagement {

    // The contract address of the CXIV ERC20 token.
    // This is set once at deployment and never changes.
    // The contract uses this address to interact with the token — 
    // e.g. to receive token payments from students or send salaries to staff.
    address tokenAddress;

    // The wallet address of the school admin (whoever deployed this contract).
    // This is the "principal" — only this address can perform admin-only actions.
    address public owner;

    // A running total of all ETH fees collected from student registrations.
    // Every time a student pays in ETH, this number goes up.
    // Every time a staff member is paid in ETH, this number goes down.
    uint256 public totalFeesETH;

    // A running total of all CXIV token fees collected from student registrations.
    // Works the same way as totalFeesETH but tracks the ERC20 token balance instead.
    uint256 public totalFeesERC20;


    // -------------------------------------------------------
    // DATA STRUCTURES (Blueprints for storing info)
    // -------------------------------------------------------

    // This is a Student "template" — a structured record that holds all the
    // important information about each student in one place.
    // Think of it like a student's file card in the school's cabinet.
    struct Student {
        string studentName;       // The full name of the student (e.g. "John Doe")
        uint256 grade;            // The student's grade level: 100, 200, 300, or 400
        bool hasPaid;             // true = fees paid and registered | false = not registered yet
        uint256 paidTimestamp;    // The exact date and time (in Unix format) when fees were paid
    }

    // This is a Staff "template" — a structured record for every staff member.
    // Think of it like an employee file in the HR department.
    struct Staff {
        string staffName;         // The full name of the staff member (e.g. "Mrs. Johnson")
        bool isRegistered;        // true = staff has been officially added to the school system
        bool salaryPaid;          // true = salary has already been paid for the current cycle
        bool isSuspended;         // true = staff has been suspended and cannot receive salary
        uint256 salaryTimestamp;  // The exact date and time the last salary was paid
    }


    // -------------------------------------------------------
    // STORAGE (Where the data lives on-chain)
    // -------------------------------------------------------

    // A lookup table: given any wallet address, return that student's full record.
    // Example: students[0xAlice] returns Alice's name, grade, payment status, etc.
    mapping(address => Student) public students;

    // A simple list of all wallet addresses that have registered as students.
    // Useful for looping through all students or counting them.
    address[] public studentList;

    // A lookup table: given any wallet address, return that staff member's full record.
    // Example: staff[0xBob] returns Bob's name, suspension status, salary info, etc.
    mapping(address => Staff) public staff;

    // A simple list of all wallet addresses that have been registered as staff.
    address[] public staffList;

    // A lookup table that maps each grade level to its required school fee (in ETH/tokens).
    // These fees are set at deployment in the constructor below.
    // Example: gradeFees[100] = 0.1 ETH means Grade 100 students pay 0.1 ETH to register.
    mapping(uint256 => uint256) public gradeFees;


    // -------------------------------------------------------
    // CONSTRUCTOR — Runs ONCE when the contract is first deployed
    // -------------------------------------------------------
    // This function sets up the contract with its initial configuration.
    // It's like the school's "opening day" setup:
    //   - Records who the school admin (owner) is
    //   - Links the CXIV token so the school can accept it as payment
    //   - Sets the fee for each grade level
    //
    // Parameter:
    //   _tokenAddress = the deployed address of the CXIV ERC20 token contract
    constructor(address _tokenAddress) {
        owner = msg.sender;           // The person deploying the contract becomes the school admin
        tokenAddress = _tokenAddress; // Save the ERC20 token's contract address for future use

        // Set the school fees for each grade level (in ETH)
        // Grade 100 (Freshmen)  = 0.1 ETH
        // Grade 200 (Sophomore) = 0.2 ETH
        // Grade 300 (Junior)    = 0.3 ETH
        // Grade 400 (Senior)    = 0.4 ETH
        gradeFees[100] = 0.1 ether;
        gradeFees[200] = 0.2 ether;
        gradeFees[300] = 0.3 ether;
        gradeFees[400] = 0.4 ether;
    }


    // -------------------------------------------------------
    // ACCESS CONTROL — Admin-Only Modifier
    // -------------------------------------------------------
    // This "modifier" acts like a security guard at a restricted door.
    // Any function tagged with "onlyOwner" will first check:
    //   "Is the person calling this function the school admin?"
    // If yes, the function runs. If no, it is blocked with an error.
    //
    // Example: Only the school principal can register staff or pay salaries.
    // A student or random address calling those functions will be rejected.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only school admin");
        _;
    }


    // -------------------------------------------------------
    // EVENTS — Blockchain Receipts / Activity Log
    // -------------------------------------------------------
    // Events are like notification emails sent to the blockchain.
    // They are permanently recorded and can be read by tools like Etherscan.

    // Fired when a new student is successfully registered.
    event StudentRegistered(address indexed student, string name, uint256 grade);

    // Fired when school fees are successfully paid (either ETH or ERC20).
    event FeesPaid(address indexed student, uint256 amount, uint256 timestamp);

    // Fired when a new staff member is added to the school system.
    event StaffRegistered(address indexed staff, string name);

    // Fired when a staff member's salary is successfully paid.
    event SalaryPaid(address indexed staff, uint256 amount, uint256 timestamp);

    // Fired when a staff member is suspended by the admin.
    event StaffSuspended(address indexed staff);


    // -------------------------------------------------------
    // REGISTER STUDENT WITH ETH
    // -------------------------------------------------------
    // This function lets a student register themselves and pay their school fee in ETH.
    // The student calls this function from their own wallet, sending the exact ETH fee.
    //
    // How it works step by step:
    //   1. Student selects their grade (100, 200, 300, or 400)
    //   2. They send the exact ETH fee for their grade along with this function call
    //   3. Their details are saved on-chain and they are marked as "paid"
    //   4. The ETH goes into the school's balance
    //
    // Example: A Grade 200 student calls registerStudentETH("Jane Doe", 200)
    // and sends exactly 0.2 ETH. Jane is now registered.
    //
    // Parameters:
    //   _studentName = the student's full name as a text string
    //   _grade       = the grade level (must be 100, 200, 300, or 400)
    function registerStudentETH(string memory _studentName, uint256 _grade) public payable {

        // Only valid grade levels are accepted: 100, 200, 300, or 400.
        // The _grade % 100 == 0 check ensures values like 150 or 250 are rejected.
        require(_grade >= 100 && _grade <= 400 && _grade % 100 == 0, "Grade not valid");

        // Look up the correct school fee for the given grade from the gradeFees table.
        // Example: If grade is 300, schoolFees will be 0.3 ETH.
        uint256 schoolFees = gradeFees[_grade];

        // The student must send EXACTLY the right amount of ETH — not more, not less.
        // msg.value is the amount of ETH attached to this function call.
        // Example: A Grade 100 student must send exactly 0.1 ETH, nothing else.
        require(msg.value == schoolFees, "Exact school fee required");

        // Prevent the same wallet from registering twice.
        // If hasPaid is already true, this wallet has already been registered.
        require(students[msg.sender].hasPaid == false, "Student already registered");

        // Save the new student's information into the students mapping.
        // msg.sender is the wallet address of the student calling this function.
        // block.timestamp records the exact date and time of registration on the blockchain.
        students[msg.sender] = Student({
            studentName: _studentName,
            grade: _grade,
            hasPaid: true,
            paidTimestamp: block.timestamp
        });

        // Add this student's wallet address to the full list of students.
        studentList.push(msg.sender);

        // Add the ETH fee paid to the school's total ETH balance.
        // Example: School had 1.0 ETH. Jane paid 0.2 ETH. School now has 1.2 ETH.
        totalFeesETH = totalFeesETH + msg.value;

        // Emit two events: one for the registration and one for the fee payment.
        // These are permanently logged on the blockchain and visible on Etherscan.
        emit StudentRegistered(msg.sender, _studentName, _grade);
        emit FeesPaid(msg.sender, msg.value, block.timestamp);
    }


    // -------------------------------------------------------
    // REGISTER STAFF (Admin Only)
    // -------------------------------------------------------
    // Only the school admin (owner) can call this function to add a new staff member.
    // This is like HR onboarding a new employee into the system.
    //
    // Example: The principal calls registerStaff(0xBob, "Mr. Bob Smith")
    // to officially add Bob as a staff member.
    //
    // Parameters:
    //   _staffAcct = Bob's wallet address
    //   _staffName = Bob's full name as a text string
    function registerStaff(address _staffAcct, string memory _staffName) public onlyOwner {

        // Check if this address has already been registered.
        // We use salaryPaid == false as a proxy check here:
        // a brand-new address that was never registered will have salaryPaid as false (default).
        // If they are already in the system with salaryPaid == false, it means they are already registered.
        require(staff[_staffAcct].salaryPaid == false, "Already registered");

        // Create a new staff record and save it under their wallet address.
        // isRegistered = true marks them as an active staff member.
        // salaryPaid starts as false because they haven't been paid yet.
        // isSuspended starts as false because they aren't suspended.
        // salaryTimestamp is 0 because no salary has been paid yet.
        staff[_staffAcct] = Staff({
            staffName: _staffName,
            isRegistered: true,
            salaryPaid: false,
            isSuspended: false,
            salaryTimestamp: 0
        });

        // Add this staff member's wallet address to the full list of staff.
        staffList.push(_staffAcct);

        // Log the registration event on the blockchain.
        emit StaffRegistered(_staffAcct, _staffName);
    }


    // -------------------------------------------------------
    // SUSPEND STAFF (Admin Only)
    // -------------------------------------------------------
    // The admin can suspend a staff member, which blocks them from receiving salary.
    // Think of it like placing an employee on unpaid administrative leave.
    //
    // Once suspended, a staff member cannot receive salary payments until
    // the suspension is lifted (this contract does not currently have an unsuspend function).
    //
    // Example: Admin calls suspendStaff(0xBob) to suspend Mr. Bob Smith.
    //
    // Parameter:
    //   _staffAcct = the wallet address of the staff member to be suspended
    function suspendStaff(address _staffAcct) public onlyOwner {

        // Can only suspend someone who is already in the system.
        require(staff[_staffAcct].isRegistered, "Staff not registered");

        // Can't suspend someone who is already suspended — that would make no sense.
        require(!staff[_staffAcct].isSuspended, "Staff already suspended");

        // Flip the isSuspended flag to true to block this staff member from receiving pay.
        staff[_staffAcct].isSuspended = true;

        // Log the suspension event on the blockchain.
        emit StaffSuspended(_staffAcct);
    }


    // -------------------------------------------------------
    // PAY STAFF SALARY WITH ETH (Admin Only)
    // -------------------------------------------------------
    // The admin sends ETH salary directly to a staff member's wallet.
    // This uses Solidity's low-level call() method — the most secure way
    // to send ETH from one address to another.
    //
    // How it works:
    //   - The admin sends ETH along with this function call (msg.value).
    //   - The contract verifies all conditions (registered, not paid yet, not suspended).
    //   - The ETH is forwarded directly to the staff member's wallet.
    //
    // Example: Admin calls payStaffSalaryETH(0xBob, 0.05 ether) while
    // sending 0.05 ETH. Bob receives 0.05 ETH in his wallet.
    //
    // Parameters:
    //   _staffAcct    = the wallet address of the staff member to be paid
    //   _salaryAmount = the exact ETH amount to send as salary
    function payStaffSalaryETH(address _staffAcct, uint256 _salaryAmount) public payable onlyOwner {

        // Make sure this person is actually registered as staff in the system.
        require(staff[_staffAcct].isRegistered, "Staff not registered");

        // Prevent paying the same staff member twice in the same cycle.
        // Once salaryPaid is set to true, it blocks a second payment.
        // The admin must call resetStaffSalary() to allow payment again next cycle.
        require(!staff[_staffAcct].salaryPaid, "Salary already paid");

        // Suspended staff cannot receive their salary.
        require(!staff[_staffAcct].isSuspended, "Staff already suspended");

        // The ETH sent along with this function call must be enough to cover the salary.
        // msg.value is the ETH attached to this transaction.
        require(msg.value >= _salaryAmount, "Insufficient school funds");

        // Mark salary as paid so it can't be paid again in this cycle.
        staff[_staffAcct].salaryPaid = true;

        // Record the exact time the salary was paid.
        staff[_staffAcct].salaryTimestamp = block.timestamp;

        // Deduct the salary from the school's tracked ETH balance.
        totalFeesETH = totalFeesETH - _salaryAmount;

        // Send the ETH to the staff member's wallet using the call() method.
        // call() is the recommended way to send ETH — it's safe and gas-efficient.
        // The "" means no additional function call data is sent — just plain ETH.
        // If the transfer fails for any reason, the entire transaction is reversed.
        (bool success, ) = _staffAcct.call{value: _salaryAmount}("");
        require(success, "Payment failed");

        // Log the salary payment event on the blockchain.
        emit SalaryPaid(_staffAcct, _salaryAmount, block.timestamp);
    }


    // -------------------------------------------------------
    // RESET STAFF SALARY STATUS (Admin Only)
    // -------------------------------------------------------
    // After each pay cycle, the admin must reset a staff member's salary status
    // before they can be paid again in the next cycle.
    //
    // Think of this like starting a new month: the payroll officer "opens up"
    // the salary slot for the next period.
    //
    // Example: At the start of a new month, admin calls resetStaffSalary(0xBob)
    // so that Bob becomes eligible to receive his salary again.
    //
    // Parameter:
    //   _staffAcct = the wallet address of the staff member to reset
    function resetStaffSalary(address _staffAcct) public onlyOwner {

        // Only registered staff members can have their status reset.
        require(staff[_staffAcct].isRegistered, "Staff not registered");

        // Set salaryPaid back to false, allowing this staff member to be paid again.
        staff[_staffAcct].salaryPaid = false;
    }


    // -------------------------------------------------------
    // GET ALL STUDENTS
    // -------------------------------------------------------
    // Returns the full list of wallet addresses that have registered as students.
    // Useful for the admin to see how many students have enrolled, or to loop
    // through all students for reporting purposes.
    //
    // Example: calling getAllStudents() might return:
    // [0xAlice, 0xJane, 0xMark, 0xSarah]
    function getAllStudents() external view returns (address[] memory) {
        return studentList;
    }


    // -------------------------------------------------------
    // GET ALL STAFF
    // -------------------------------------------------------
    // Returns the full list of wallet addresses that have been registered as staff.
    // Similar to getAllStudents() but for the staff side of the school.
    //
    // Example: calling getAllStaff() might return:
    // [0xBob, 0xMrsJohnson, 0xMrSmith]
    function getAllStaff() external view returns (address[] memory) {
        return staffList;
    }


    // -------------------------------------------------------
    // REGISTER STUDENT WITH ERC20 TOKEN
    // -------------------------------------------------------
    // This function works exactly like registerStudentETH() but instead of paying
    // in ETH, the student pays in CXIV tokens (the ERC20 token).
    //
    // IMPORTANT: Before calling this function, the student must first call
    // the approve() function on the CXIV token contract, giving this school
    // contract permission to pull the tokens from their wallet.
    //
    // Flow:
    //   Step 1: Student calls CXIV.approve(schoolContractAddress, feeAmount)
    //           — This gives the school permission to take the fee from the student's wallet
    //   Step 2: Student calls registerStudentERC20("Jane Doe", 200, 0.2 ether)
    //           — The school contract pulls the tokens using transferFrom()
    //
    // Example: Jane wants to register for Grade 200 using CXIV tokens.
    //   She first approves 0.2 ether worth of CXIV, then calls this function.
    //
    // Parameters:
    //   _studentName = the student's full name
    //   _grade       = grade level (100, 200, 300, or 400)
    //   _amount      = the exact number of CXIV tokens to pay (must match the grade fee)
    function registerStudentERC20(string memory _studentName, uint256 _grade, uint256 _amount) public {

        // Only valid grade levels: 100, 200, 300, or 400.
        require(_grade >= 100 && _grade <= 400 && _grade % 100 == 0, "Grade not valid");

        // Look up the required fee for this grade level.
        uint256 schoolFees = gradeFees[_grade];

        // The token amount provided must exactly match the required fee — no more, no less.
        require(_amount == schoolFees, "Exact school fee required");

        // Prevent duplicate registrations from the same wallet address.
        require(students[msg.sender].hasPaid == false, "Student already registered");

        // Save the student's details into the students mapping.
        students[msg.sender] = Student({
            studentName: _studentName,
            grade: _grade,
            hasPaid: true,
            paidTimestamp: block.timestamp
        });

        // Add the student's wallet to the complete student list.
        studentList.push(msg.sender);

        // Update the school's total ERC20 token balance to include this payment.
        totalFeesERC20 = totalFeesERC20 + _amount;

        // Pull the CXIV tokens FROM the student's wallet INTO this school contract.
        // This only works because the student already called approve() beforehand.
        // transferFrom(student, school, amount) — "take _amount CXIV from student, give to school"
        bool regStudentFee = IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        // If for any reason the token transfer fails, reverse the entire transaction.
        require(regStudentFee, "Failed to pay school fees");

        // Log the registration and fee payment events.
        emit StudentRegistered(msg.sender, _studentName, _grade);
        emit FeesPaid(msg.sender, _amount, block.timestamp);
    }


    // -------------------------------------------------------
    // PAY STAFF SALARY WITH ERC20 TOKEN (Admin Only)
    // -------------------------------------------------------
    // This function works like payStaffSalaryETH() but pays the staff member
    // using CXIV tokens from the school's token balance instead of ETH.
    //
    // The school contract must hold enough CXIV tokens (collected from student fees)
    // to cover the salary before this function can succeed.
    //
    // Flow:
    //   1. Students paid fees in CXIV tokens → those tokens are now held by this contract
    //   2. Admin calls this function to transfer some of those tokens to a staff member
    //
    // Example: The school has 10 CXIV tokens from student registrations.
    //   Admin calls payStaffSalaryERC20(0xBob, 2 ether) to pay Bob 2 CXIV.
    //   Bob's wallet now has 2 CXIV and the school's balance drops to 8 CXIV.
    //
    // Parameters:
    //   _staffAcct    = the wallet address of the staff member to be paid
    //   _salaryAmount = the number of CXIV tokens to send as salary
    function payStaffSalaryERC20(address _staffAcct, uint256 _salaryAmount) public onlyOwner {

        // Make sure this person is registered as a staff member.
        require(staff[_staffAcct].isRegistered, "Staff not registered");

        // Prevent paying the same staff member twice in the same pay cycle.
        require(!staff[_staffAcct].salaryPaid, "Salary already paid");

        // Suspended staff members cannot receive salary payments.
        require(!staff[_staffAcct].isSuspended, "Staff already suspended");

        // Make sure the school holds enough CXIV tokens to cover the salary.
        // Note: this uses strict less-than (<) instead of <=
        // which means the salary must be STRICTLY less than the total.
        // Example: If totalFeesERC20 = 5 CXIV, salary must be at most 4.999... CXIV.
        require(_salaryAmount < totalFeesERC20, "Insufficient school funds");

        // Mark the staff member's salary as paid to prevent a duplicate payment.
        staff[_staffAcct].salaryPaid = true;

        // Record the timestamp of this salary payment.
        staff[_staffAcct].salaryTimestamp = block.timestamp;

        // Deduct the salary amount from the school's tracked ERC20 token balance.
        totalFeesERC20 = totalFeesERC20 - _salaryAmount;

        // Transfer CXIV tokens FROM this school contract TO the staff member's wallet.
        // This uses transfer() (not transferFrom()) because the school CONTRACT
        // is the one sending its own tokens — no third-party approval needed.
        bool paySalarySuccess = IERC20(tokenAddress).transfer(_staffAcct, _salaryAmount);

        // If the token transfer fails for any reason, reverse the entire transaction.
        require(paySalarySuccess, "Payment failed");

        // Log the salary payment event on the blockchain.
        emit SalaryPaid(_staffAcct, _salaryAmount, block.timestamp);
    }
}
