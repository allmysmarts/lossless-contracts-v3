// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/ILosslessGovernance.sol";

/// @dev This is tester contract, in order to check retrieve compensation from lossless governance.
contract MaliciousContractTester {
    ILssGovernance losslessGovernance;

    constructor(ILssGovernance _losslessGovernance) {
        losslessGovernance = _losslessGovernance;
    }

    function triggerRetrieveCompensation() external {
        losslessGovernance.retrieveCompensationByContract();
    }
}
