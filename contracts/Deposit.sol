// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./Structure.sol";

contract FixedDeposit {
    // state variables
    BankLib.Bank[] public banks;
    mapping(address => BankLib.Bank) public addressToBank;

    // events
    event newBankRegsitered(bytes _bankName, uint16 _uniqueID, address _budget);
    event newProgramRegistered(
        uint16 bank_uniqueID,
        uint16 program_uniqueID,
        bytes _programName,
        uint8 _interestRateInMonths,
        uint8 _durationInMonths
    );
    event customerDeposited(
        uint16 bank_uniqueID,
        uint16 program_uniqueID,
        address customer,
        uint256 amount,
        uint64 _startDate,
        uint64 _endDate
    );
    event customerWithdrawed(
        uint16 bank_uniqueID,
        uint16 program_uniqueID,
        address customer,
        uint256 amount,
        uint64 withdrawalDate
    );

    // functions
    function registerNewBank(bytes calldata _bankName) public {
        require(
            msg.sender.balance > 0,
            "You don't have enough budget to form a bank!"
        );
        require(
            addressToBank[msg.sender].activeStatus == false,
            "Bank already exists!"
        );

        BankLib.registerNewBank(banks, _bankName);
        addressToBank[msg.sender] = banks[banks.length - 1];

        emit newBankRegsitered(_bankName, uint16(banks.length), msg.sender);
    }

    function registerNewProgram(
        bytes calldata _programName,
        uint8 _interestRateScaler,
        uint8 _durationInMonths
    ) public {
        BankLib.Bank storage bank = addressToBank[msg.sender];
        require(
            bank.activeStatus == true,
            "In order to add a new program, your bank needs to be registered and already presentable!"
        );
        require(
            bank.programs.length <= 10,
            "Your bank has reached the limit for the maximum amount of fixed-deposit programs creation"
        );

        ProgramLib.registerNewProgram(
            bank.programs,
            _programName,
            _interestRateScaler,
            _durationInMonths
        );
        emit newProgramRegistered(
            bank.uniqueID,
            uint16(bank.programs.length),
            _programName,
            _interestRateScaler,
            _durationInMonths
        );
    }

    function deposit(
        uint16 bank_uniqueID,
        uint16 program_uniqueID // choose a bank, choose a program from such bank and then deposit
    ) public payable {
        require(
            bank_uniqueID >= 1 && bank_uniqueID <= banks.length,
            "No such bank exists!"
        );
        ProgramLib.Program[] storage programs = banks[bank_uniqueID - 1]
            .programs;
        require(
            program_uniqueID >= 1 &&
                program_uniqueID <= programs.length,
            "No such program exists!"
        );
        require(msg.value > 0, "Not enough money to deposit!");

        ProgramLib.Program storage chosenProgram = programs[program_uniqueID];
        AccountLib.Account storage newAccount = chosenProgram.accounts.push();
        newAccount.startDate = uint64(block.timestamp);
        newAccount.endDate = uint64(
            newAccount.startDate + chosenProgram.durationInMonths * 2592000
        ); // There are 2,592,000 seconds in a month
        newAccount.amount = msg.value;

        emit customerDeposited(
            bank_uniqueID,
            program_uniqueID,
            msg.sender,
            msg.value,
            newAccount.startDate,
            newAccount.endDate
        );
    }

    function withdraw(uint16 bank_uniqueID, uint16 program_uniqueID) public {
        bool deposited = false;
        AccountLib.Account[] storage accounts = banks[bank_uniqueID]
            .programs[program_uniqueID]
            .accounts;
        uint256 i = 0;
        for (; i < accounts.length; i++) {
            if (msg.sender == accounts[i].wallet) {
                deposited = true;
                break;
            }
        }

        require(deposited, "You haven't deposited!");
        require(
            block.timestamp >= accounts[i].endDate,
            "You have deposited but you are not allowed to withdraw until the term is due!"
        );

        ProgramLib.Program storage program = banks[bank_uniqueID].programs[
            program_uniqueID
        ];
        accounts[i].amount += ((accounts[i].amount *
            program.interestRateScaler) / 10);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: accounts[i].amount
        }("Withdrawal success!");
        require(callSuccess, "Withdrawal failed due to some errors!");
    }

    function reDeposit(uint16 bank_uniqueID, uint16 program_uniqueID) public {
        bool deposited = false;
        uint64 timestamp = uint64(block.timestamp);
        AccountLib.Account[] storage accounts = banks[bank_uniqueID]
            .programs[program_uniqueID]
            .accounts;
        uint256 i = 0;
        for (; i < accounts.length; i++) {
            if (msg.sender == accounts[i].wallet) {
                deposited = true;
                break;
            }
        }

        require(deposited, "You have not deposited!");
        require(
            timestamp >= accounts[i].endDate,
            "You have deposited but you are not allowed to re-deposit until the term is due!"
        );
        ProgramLib.Program storage program = banks[bank_uniqueID].programs[
            program_uniqueID
        ];
        accounts[i].startDate = timestamp;
        accounts[i].endDate = (timestamp + program.durationInMonths * 2592000); // There are 2,592,000 seconds in a month
        accounts[i].amount += ((accounts[i].amount *
            program.interestRateScaler) / 10);
    }

function getProgramsOfBank(uint16 bank_uniqueID) public view returns (ProgramLib.Program[] memory) {
    require(bank_uniqueID >= 1 && bank_uniqueID <= banks.length, "Bank does not exist!");

    ProgramLib.Program[] storage storagePrograms = banks[bank_uniqueID - 1].programs;
    ProgramLib.Program[] memory memoryPrograms = new ProgramLib.Program[](storagePrograms.length);

    for (uint256 i = 0; i < storagePrograms.length; i++) {
        ProgramLib.Program storage storageProgram = storagePrograms[i];
        memoryPrograms[i] = ProgramLib.Program({
            uniqueID: storageProgram.uniqueID,
            programName: storageProgram.programName,
            interestRateScaler: storageProgram.interestRateScaler,
            durationInMonths: storageProgram.durationInMonths,
            accounts: storageProgram.accounts
        });
    }

    return memoryPrograms;
}


    function getAllBanks() public view returns (BankLib.Bank[] memory) {
        return banks;
    }

    // fallback() external {}

    // receive() external payable {
    //     // send back the money to anonymous sender
    //     (bool callSuccess, ) = payable(msg.sender).call{value: msg.value}(
    //         "Hi there! This is Ethereuem Fixed-Deposit smart contract, We have refunded the money that you had accidentally sent to us! Have a great day!"
    //     );
    //     require(callSuccess, "Money couldn't be refunded due to some errors!");
    // }
}
