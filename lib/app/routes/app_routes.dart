abstract class Routes {
  // Auth
  static const splash = '/splash';
  static const phone = '/phone';
  static const otp = '/otp';

  // Worker
  static const worker = '/worker';
  static const quickName = '/worker/quick-name';
  static const quickJob = '/worker/quick-job';
  static const quickLocation = '/worker/quick-location';
  static const quickJobType = '/worker/quick-job-type';
  static const quickSalary = '/worker/quick-salary';
  static const quickSuccess = '/worker/quick-success';
  static const personalDetails = '/worker/personal';
  static const occupationSkills = '/worker/skills';
  static const workHistory = '/worker/history';
  static const locationPrefs = '/worker/location';
  static const kyc = '/worker/kyc';
  static const blocked = '/worker/blocked';
  static const offerLetter = '/offer-letter';

  // Employer
  static const employer = '/employer';
  static const employerRegister = '/employer/register';
  static const employerVerification = '/employer/verification';
  static const postRequirement = '/employer/post';
  static const matchedProfiles = '/employer/matches';
  static const workerDetail = '/employer/worker';
  static const caseAlerts = '/employer/case-alerts';
  static const hire = '/employer/hire';
}
