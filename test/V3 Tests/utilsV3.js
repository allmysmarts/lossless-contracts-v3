/* eslint-disable no-undef */
/* eslint-disable arrow-body-style */
/* eslint-disable no-await-in-loop */
const { time } = require('@openzeppelin/test-helpers');

const setupAddresses = async () => {
  const [
    lssInitialHolder,
    lssAdmin,
    lssPauseAdmin,
    lssRecoveryAdmin,
    lssBackupAdmin,
    staker1,
    staker2,
    staker3,
    staker4,
    staker5,
    member1,
    member2,
    member3,
    member4,
    member5,
    maliciousActor1,
    maliciousActor2,
    maliciousActor3,
    reporter1,
    reporter2,
  ] = await ethers.getSigners();

  const [
    lerc20InitialHolder,
    lerc20Admin,
    lerc20PauseAdmin,
    lerc20RecoveryAdmin,
    lerc20BackupAdmin,
    regularUser1,
    regularUser2,
    regularUser3,
    regularUser4,
    regularUser5,
    dexAddress,
  ] = await ethers.getSigners();

  return {
    lssInitialHolder,
    lssAdmin,
    lssPauseAdmin,
    lssRecoveryAdmin,
    lssBackupAdmin,
    staker1,
    staker2,
    staker3,
    staker4,
    staker5,
    member1,
    member2,
    member3,
    member4,
    member5,
    maliciousActor1,
    maliciousActor2,
    maliciousActor3,
    reporter1,
    reporter2,
    lerc20InitialHolder,
    lerc20Admin,
    lerc20PauseAdmin,
    lerc20RecoveryAdmin,
    lerc20BackupAdmin,
    regularUser1,
    regularUser2,
    regularUser3,
    regularUser4,
    regularUser5,
    dexAddress,
  };
};

const setupEnvironment = async (
  lssAdmin,
  lssRecoveryAdmin,
  lssPauseAdmin,
  lssInitialHolder,
  lssBackupAdmin,
) => {
  const lssTeamVoteIndex = 0;
  const tokenOwnersVoteIndex = 1;
  const committeeVoteIndex = 2;

  const stakingAmount = 2500;
  const reportingAmount = 1000;
  const reportLifetime = time.duration.days(1);

  const lssName = 'Lossless';
  const lssSymbol = 'LSS';
  const lssInitialSupply = 1000000;

  const LosslessControllerV1 = await ethers.getContractFactory(
    'LosslessControllerV1',
  );

  const LosslessControllerV2 = await ethers.getContractFactory(
    'LosslessControllerV2',
  );

  const LosslessControllerV3 = await ethers.getContractFactory(
    'LosslessControllerV3',
  );

  const losslessControllerV1 = await upgrades.deployProxy(
    LosslessControllerV1,
    [lssAdmin.address, lssRecoveryAdmin.address, lssPauseAdmin.address],
  );

  const losslessControllerV2 = await upgrades.upgradeProxy(
    losslessControllerV1.address,
    LosslessControllerV2,
  );

  const lssController = await upgrades.upgradeProxy(
    losslessControllerV2.address,
    LosslessControllerV3,
  );

  const LosslessToken = await ethers.getContractFactory('LERC20');

  lssToken = await LosslessToken.connect(lssInitialHolder).deploy(
    lssInitialSupply,
    lssName,
    lssSymbol,
    lssAdmin.address,
    lssBackupAdmin.address,
    Number(time.duration.days(1)),
    lssController.address,
  );

  const LosslessStaking = await ethers.getContractFactory('LosslessStaking');

  const LosslessGovernance = await ethers.getContractFactory(
    'LosslessGovernance',
  );

  const LosslessReporting = await ethers.getContractFactory(
    'LosslessReporting',
  );

  lssReporting = await upgrades.deployProxy(
    LosslessReporting,
    [lssController.address],
    { initializer: 'initialize' },
  );

  lssStaking = await upgrades.deployProxy(
    LosslessStaking,
    [lssReporting.address, lssController.address],
    { initializer: 'initialize' },
  );

  lssGovernance = await upgrades.deployProxy(
    LosslessGovernance,
    [
      lssReporting.address,
      lssController.address,
      lssStaking.address,
      lssToken.address,
    ],
    { initializer: 'initialize' },
  );

  await lssController.connect(lssAdmin).setLosslessToken(lssToken.address);
  await lssController
    .connect(lssAdmin)
    .setStakingContractAddress(lssStaking.address);
  await lssController
    .connect(lssAdmin)
    .setReportingContractAddress(lssReporting.address);
  await lssController
    .connect(lssAdmin)
    .setGovernanceContractAddress(lssGovernance.address);
  await lssController.connect(lssAdmin).setControllerV3Defaults();

  await lssStaking.connect(lssAdmin).setStakingAmount(stakingAmount);
  await lssStaking.connect(lssAdmin).setLosslessToken(lssToken.address);
  await lssStaking
    .connect(lssAdmin)
    .setLosslessGovernance(lssGovernance.address);

  await lssReporting
    .connect(lssAdmin)
    .setReportLifetime(Number(reportLifetime));
  await lssReporting.connect(lssAdmin).setReportingAmount(reportingAmount);
  await lssReporting.connect(lssAdmin).setLosslessToken(lssToken.address);

  await lssReporting
    .connect(lssAdmin)
    .setLosslessGovernance(lssGovernance.address);
  await lssReporting.connect(lssAdmin).setReporterReward(2);
  await lssReporting.connect(lssAdmin).setLosslessFee(10);
  await lssReporting.connect(lssAdmin).setStakersFee(2);
  await lssReporting.connect(lssAdmin).setCommitteeReward(2);

  return {
    lssController,
    lssStaking,
    lssReporting,
    lssGovernance,
    lssTeamVoteIndex,
    tokenOwnersVoteIndex,
    committeeVoteIndex,
    stakingAmount,
    reportingAmount,
    reportLifetime,
    lssToken,
  };
};

const setupToken = async (
  supply,
  name,
  symbol,
  initialHolder,
  admin,
  backupAdmin,
  lockPeriod,
  controller,
) => {
  const token = await ethers.getContractFactory('LERC20');

  const deployedToken = await token
    .connect(initialHolder)
    .deploy(supply, name, symbol, admin, backupAdmin, lockPeriod, controller);

  return deployedToken;
};

module.exports = {
  setupAddresses,
  setupEnvironment,
  setupToken,
};
