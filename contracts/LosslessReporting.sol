// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

interface ILERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function admin() external view returns (address);
}

interface ILssController {
    function isBlacklisted(address _adr) external returns (bool);
    function getReportLifetime() external returns (uint256);
    function getStakeAmount() external returns (uint256);
    function addToBlacklist(address _adr) external;
    function isWhitelisted(address _adr) external view returns (bool);
    function activateEmergency(address token) external;
}

/// @title Lossless Reporting
/// @author Lossless.cash
/// @notice The Reporting smart contract is in charge of handling all the parts related to creating new reports
contract LosslessReporting is Initializable, ContextUpgradeable, PausableUpgradeable {
    address public pauseAdmin;
    address public admin;
    address public recoveryAdmin;

    uint256 public reporterReward;
    uint256 public losslessFee;

    uint256 public reportCount;

    ILERC20 public losslessToken;
    ILssController public losslessController;
    address controllerAddress;
    address stakingAddress;

    struct TokenReports {
        mapping(address => uint256) reports;
    }

    
    mapping(address => TokenReports) private tokenReports; // Address. reported X address, on report ID

    mapping(uint256 => address) public reporter;
    mapping(uint256 => address) public reportedAddress;
    mapping(uint256 => uint256) public reportTimestamps;
    mapping(uint256 => address) public reportTokens;
    mapping(uint256 => bool) public anotherReports;
    mapping(uint256 => uint256) public amountReported;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event PauseAdminChanged(address indexed previousAdmin, address indexed newAdmin);

    event ReportSubmitted(address indexed token, address indexed account, uint256 reportId);
    event AnotherReportSubmitted(address indexed token, address indexed account, uint256 reportId);

    // --- MODIFIERS ---

    modifier onlyLosslessRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin, "LSS: Must be recoveryAdmin");
        _;
    }

    modifier onlyLosslessAdmin() {
        require(admin == _msgSender(), "LSS: Must be admin");
        _;
    }

    modifier onlyPauseAdmin() {
        require(_msgSender() == pauseAdmin, "LSS: Must be pauseAdmin");
        _;
    }

    modifier notBlacklisted() {
        require(!losslessController.isBlacklisted(_msgSender()), "LSS: You cannot operate");
        _;
    }

    function initialize(address _admin, address _recoveryAdmin, address _pauseAdmin) public initializer {
        admin = _admin;
        recoveryAdmin = _recoveryAdmin;
        pauseAdmin = _pauseAdmin;
    }
    
    // --- SETTERS ---

    function pause() public onlyPauseAdmin{
        _pause();
    }    
    
    function unpause() public onlyPauseAdmin{
        _unpause();
    }

    function setAdmin(address newAdmin) public onlyLosslessRecoveryAdmin {
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function setRecoveryAdmin(address newRecoveryAdmin) public onlyLosslessRecoveryAdmin {
        emit RecoveryAdminChanged(recoveryAdmin, newRecoveryAdmin);
        recoveryAdmin = newRecoveryAdmin;
    }

    function setPauseAdmin(address newPauseAdmin) public onlyLosslessRecoveryAdmin {
        emit PauseAdminChanged(pauseAdmin, newPauseAdmin);
        pauseAdmin = newPauseAdmin;
    }
    
    function setLosslessToken(address _losslessToken) public onlyLosslessAdmin {
        losslessToken = ILERC20(_losslessToken);
    }

    function setControllerContractAddress(address _adr) public onlyLosslessAdmin {
        losslessController = ILssController(_adr);
        controllerAddress = _adr;
    }

    function setStakingContractAddress(address _adr) public onlyLosslessAdmin {
        stakingAddress = _adr;
    }

    function setReporterReward(uint256 reward) public onlyLosslessAdmin {
        reporterReward = reward;
    }

    function setLosslessFee(uint256 fee) public onlyLosslessAdmin {
        losslessFee = fee;
    }

    // --- GETTERS ---

    function getVersion() public pure returns (uint256) {
        return 1;
    }

    function getReporter(uint256 _reportId) public view returns (address) {
        return reporter[_reportId];
    }

    function getReportTimestamps(uint256 _reportId) public view returns (uint256) {
        return reportTimestamps[_reportId];
    }

    function getTokenFromReport(uint256 _reportId) public view returns (address) {
        return reportTokens[_reportId];
    }

    function getReportedAddress(uint256 _reportId) public view returns (address) {
        return reportedAddress[_reportId];
    }

    function getReporterRewardAndLSSFee() public view returns (uint256 reward, uint256 fee) {
        return (reporterReward, losslessFee);
    }

    function getAmountReported(uint256 reportId) public view returns (uint256) {
        return amountReported[reportId];
    }

    // --- REPORTS ---

    function report(address token, address account) public notBlacklisted {

        console.log("Reported %s", token);
        
        require(!losslessController.isWhitelisted(account), "LSS: Cannot report LSS protocol");

        uint256 reportId = tokenReports[token].reports[account];
        uint256 reportLifetime;
        uint256 stakeAmount;

        reportLifetime = losslessController.getReportLifetime();
        stakeAmount = losslessController.getStakeAmount();

        require(reportId == 0 || reportTimestamps[reportId] + reportLifetime < block.timestamp, "LSS: Report already exists");

        reportCount += 1;
        reportId = reportCount;
        reporter[reportId] = _msgSender();

        // Bellow does not allow freezing more than one wallet. Do we want that?
        tokenReports[token].reports[account] = reportId;
        reportTimestamps[reportId] = block.timestamp;
        reportTokens[reportId] = token;

        losslessToken.transferFrom(_msgSender(), stakingAddress, stakeAmount);

        losslessController.addToBlacklist(account);
        reportedAddress[reportId] = account;
        amountReported[reportId] = losslessToken.balanceOf(account);

        losslessController.activateEmergency(token);
        emit ReportSubmitted(token, account, reportId);
    }

    function reportAnother(uint256 reportId, address token, address account) public notBlacklisted {
        uint256 reportLifetime;
        uint256 reportTimestamp;
        uint256 stakeAmount;

        require(!losslessController.isWhitelisted(account), "LSS: Cannot report LSS protocol");

        reportTimestamp = reportTimestamps[reportId];
        reportLifetime = losslessController.getReportLifetime();
        stakeAmount = losslessController.getStakeAmount();

        require(reportId > 0 && reportTimestamp + reportLifetime > block.timestamp, "LSS: report does not exists");
        require(anotherReports[reportId] == false, "LSS: Another already submitted");
        require(_msgSender() == reporter[reportId], "LSS: invalid reporter");

        anotherReports[reportId] = true;
        tokenReports[token].reports[account] = reportId;
        amountReported[reportId] += losslessToken.balanceOf(account);

        losslessController.addToBlacklist(account);
        reportedAddress[reportId] = account;

        losslessToken.transferFrom(_msgSender(), stakingAddress, stakeAmount);

        emit AnotherReportSubmitted(token, account, reportId);
    }
}