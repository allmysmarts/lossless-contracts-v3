// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";

interface ILssController {
    function getLockedAmount(ILERC20 _token, address _account) external view returns (uint256);
    function getAvailableAmount(ILERC20 _token, address _account) external view returns (uint256 amount);
    function retrieveBlacklistedFunds(address[] calldata _addresses, ILERC20 _token, uint256 _reportId) external returns(uint256);
    function reportLifetime() external returns (uint256);
    function stakeAmount() external view returns (uint256);
    function reportingAmount() external returns (uint256);
    function whitelist(address _adr) external view returns (bool);
    function dexList(address _dexAddress) external returns (bool);
    function getReporterPayoutStatus(address _reporter, uint256 _reportId) external view returns (bool _payed);
    function blacklist(address _adr) external view returns (bool);
    function admin() external view returns (address);
    function pauseAdmin() external view returns (address);
    function recoveryAdmin() external view returns (address);
    function guardian() external view returns (address);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function dexTranferThreshold() external view returns (uint256);
    function settlementTimeLock() external view returns (uint256);
    
    function pause() external;
    function unpause() external;
    function setAdmin(address _newAdmin) external;
    function setRecoveryAdmin(address _newRecoveryAdmin) external;
    function setPauseAdmin(address _newPauseAdmin) external;
    function setSettlementTimeLock(uint256 _newTimelock) external;
    function setDexTrasnferThreshold(uint256 _newThreshold) external;
    function setReporterPayoutStatus(address _reporter, bool _status, uint256 _reportId) external; 
    function setDexList(address[] calldata _dexList, bool value) external;
    function setWhitelist(address[] calldata _addrList, bool value) external;
    function addToBlacklist(address _adr) external;
    function resolvedNegatively(address _adr) external;
    function setStakingContractAddress(ILssStaking _adr) external;
    function setReportingContractAddress(ILssReporting _adr) external; 
    function setGovernanceContractAddress(ILssGovernance _adr) external;
    function proposeNewSettlementPeriod(ILERC20 _token, uint256 _seconds) external;
    function executeNewSettlementPeriod(ILERC20 _token) external;
    function activateEmergency(ILERC20 _token) external;
    function deactivateEmergency(ILERC20 _token) external;
    function setGuardian(address _newGuardian) external;
    function removeProtectedAddress(ILERC20 _token, address _protectedAddresss) external;
    function beforeTransfer(address _sender, address _recipient, uint256 _amount) external;
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external;
    function beforeApprove(address _sender, address _spender, uint256 _amount) external;
    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) external;
    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) external;

    event AdminChange(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChange(address indexed previousAdmin, address indexed newAdmin);
    event PauseAdminChange(address indexed previousAdmin, address indexed newAdmin);
    event NewGuardian(address indexed oldGuardian, address indexed newGuardian);
    event NewProtectedAddress(address indexed token, address indexed protectedAddress, address indexed strategy);
    event RemovedProtectedAddress(address indexed token, address indexed protectedAddress);
    event NewSettlementPeriodProposal(address indexed token, uint256 _seconds);
    event SettlementPeriodChanged(address indexed token, uint256 proposedTokenLockTimeframe);
}