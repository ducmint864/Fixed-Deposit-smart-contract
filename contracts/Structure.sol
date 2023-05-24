// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library ProgramLib {
    struct Program {
        uint16 uniqueID; // A program is unique in context of its hosting bank
        bytes programName; // short program name
        uint8 interestRateScaler; // which means actual interest rate is interestRateScaler * 0.1;
        uint8 durationInMonths;
        AccountLib.Account[] accounts;
    }

    function registerNewProgram (
        Program[] storage programs,
        bytes calldata _programName,
        uint8 _interestRateScaler,
        uint8 _durationInMonths
    ) external {
        Program storage newProgram = programs.push();
        newProgram.programName = _programName;
        newProgram.interestRateScaler = _interestRateScaler;
        newProgram.durationInMonths = _durationInMonths;
        newProgram.uniqueID = uint16(programs.length);
    }
}

library BankLib {
    struct Bank {
        bytes bankName; // short name, e.g: BIDV, not full name.
        uint16 uniqueID; // Unique identifier for each bank if different banks has the same name.
        address budgetAddress; // The money vault of banks
        bool activeStatus; // 1 : yes, 0 : no
        ProgramLib.Program[] programs;
    }

    function registerNewBank (
        Bank[] storage banks,
        bytes calldata _bankName
    ) external {
        Bank storage newBank = banks.push();
        newBank.bankName = _bankName;
        newBank.activeStatus = true;
        newBank.budgetAddress = msg.sender;
        newBank.uniqueID = uint16(banks.length);
    }
}

library AccountLib {
    struct Account {
        address wallet;
        uint64 startDate;
        uint64 endDate;
        uint256 amount;
    }
}

