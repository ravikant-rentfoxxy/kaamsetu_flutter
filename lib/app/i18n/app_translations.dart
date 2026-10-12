import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

// Bilingual strings — Hindi + English. Non hi/en languages fall back to Hindi
// (same as the React Native app). Use `'key'.tr`.
class AppTranslations extends Translations {
  static const hi = Locale('hi');
  static const en = Locale('en');

  @override
  Map<String, Map<String, String>> get keys => {'hi': _hi, 'en': _en};

  static final Map<String, String> _en = {for (final e in _strings.entries) e.key: e.value[1]};
  static final Map<String, String> _hi = {for (final e in _strings.entries) e.key: e.value[0]};

  // key: [hi, en]
  static const Map<String, List<String>> _strings = {
    // Common
    'continue': ['जारी रखें', 'Continue'],
    'submit': ['जमा करें', 'Submit'],
    'skip': ['छोड़ें', 'Skip'],
    'back': ['वापस', 'Back'],
    'logout': ['लॉग आउट', 'Log out'],
    'loading': ['लोड हो रहा है...', 'Loading...'],
    'error': ['कुछ गलत हुआ', 'Something went wrong'],
    'retry': ['फिर कोशिश करें', 'Try Again'],
    'cancel': ['रद्द करें', 'Cancel'],
    'save': ['सेव करें', 'Save'],
    'saveContinue': ['सेव करें और आगे बढ़ें', 'Save & Continue'],
    'next': ['आगे बढ़ें', 'Next'],
    'edit': ['बदलें', 'Edit'],
    'perMonth': ['हर महीना', 'per month'],
    'yes': ['हाँ', 'Yes'],
    'no': ['नहीं', 'No'],

    // Tabs
    'tabHome': ['होम', 'Home'],
    'tabJobs': ['काम', 'Jobs'],
    'tabOffers': ['ऑफर', 'Offers'],
    'tabProfile': ['प्रोफ़ाइल', 'Profile'],
    'tabVerify': ['जाँच', 'Verify'],
    'tabPost': ['पोस्ट करें', 'Post'],

    // OTP / login
    'enterMobile': ['मोबाइल नंबर डालें', 'Enter mobile number'],
    'loginWithMobile': ['मोबाइल नंबर से लॉगिन करें', 'Login with your mobile number'],
    'whoAreYou': ['आप कौन हैं?', 'Who are you?'],
    'worker': ['कामगार', 'Worker'],
    'employer': ['नियोक्ता', 'Employer'],
    'sendOtp': ['OTP भेजें', 'Send OTP'],
    'enterOtp': ['OTP डालें', 'Enter OTP'],
    'otpHint': ['आपके नंबर पर भेजा गया 6 अंकों का OTP', '6-digit OTP sent to your number'],
    'verifyOtp': ['OTP जाँचें', 'Verify OTP'],
    'testingOtp': ['टेस्टिंग OTP: 123456', 'Testing OTP: 123456'],

    // Dashboard
    'addYourName': ['अपना नाम जोड़ें', 'Add your name'],
    'setLocation': ['स्थान सेट करें', 'Set location'],
    'profileComplete': ['प्रोफ़ाइल पूरी', 'profile complete'],
    'complete': ['पूरी करें', 'Complete'],
    'availableForWork': ['काम के लिए उपलब्ध हूँ', 'Available for work'],
    'notAvailableNow': ['अभी उपलब्ध नहीं', 'Not available now'],
    'kycPending': ['पहचान जाँच बाकी है', 'Identity check pending'],
    'kycPendingSub': ['पूरा करें और सभी जॉब अनलॉक करें', 'Complete it to unlock all jobs'],
    'fullyVerified': ['पूरी तरह सत्यापित प्रोफ़ाइल', 'Fully verified profile'],
    'newJobOffer': ['नया जॉब ऑफर', 'new job offer'],
    'newJobOffers': ['नए जॉब ऑफर', 'new job offers'],
    'reviewAccept': ['देखें और स्वीकार करें', 'Review and accept'],
    'jobsForYou': ['आपके लिए काम', 'Jobs for you'],
    'jobsLocked': ['काम लॉक हैं', 'Jobs are locked'],
    'jobsLockedSub': ['जॉब देखने के लिए पहचान जाँच पूरी करें', 'Complete verification to see jobs'],
    'startVerification': ['जाँच शुरू करें', 'Start verification'],
    'noJobs': ['अभी कोई काम नहीं', 'No jobs yet'],
    'noJobsSub': ['नए काम आते ही हम आपको सूचित करेंगे।', "We'll notify you when new jobs arrive."],
    'myJobOffers': ['मेरे जॉब ऑफर', 'My job offers'],
    'noOffers': ['अभी कोई ऑफर नहीं', 'No offers yet'],
    'noOffersSub': ['नियोक्ता के ऑफर यहाँ दिखेंगे।', 'Offers from employers will appear here.'],
    'apply': ['आवेदन करें', 'Apply'],
    'applied': ['आवेदन किया', 'Applied'],
    'alreadyApplied': ['आपने आवेदन कर दिया है', 'You have already applied'],
    'setAvailableFirst': ['आवेदन के लिए उपलब्धता चालू करें', 'Turn on availability to apply'],
    'accept': ['स्वीकारें', 'Accept'],
    'decline': ['अस्वीकारें', 'Decline'],
    'pending': ['इंतज़ार', 'Pending'],
    'active': ['सक्रिय', 'Active'],
    'rejected': ['अस्वीकृत', 'Rejected'],
    'hired': ['आप हायर हो गए!', 'You are hired!'],
    'viewOfferLetter': ['ऑफर लेटर देखें', 'View offer letter'],
    'salary': ['वेतन', 'Salary'],
    'startDate': ['शुरू तारीख', 'Start date'],
    'location': ['स्थान', 'Location'],
    'distance': ['दूरी', 'Distance'],
    'experience': ['अनुभव', 'Experience'],
    'stayRequired': ['साथ रहना ज़रूरी', 'Live-in required'],
    'notifications': ['सूचनाएँ', 'Notifications'],
    'noNotifications': ['अभी कोई सूचना नहीं', 'No notifications yet'],
    'noNotificationsSub': ['नई सूचनाएँ यहाँ दिखेंगी।', 'New notifications will appear here.'],

    // Profile
    'myProfile': ['मेरी प्रोफ़ाइल', 'My Profile'],
    'personalDetails': ['व्यक्तिगत जानकारी', 'Personal Details'],
    'occupationSkills': ['काम और हुनर', 'Work & Skills'],
    'workHistory': ['काम का अनुभव', 'Work History'],
    'locationPrefs': ['जगह और पसंद', 'Location & Preferences'],
    'verification': ['पहचान सत्यापन', 'Verification'],
    'language': ['भाषा', 'Language'],
    'account': ['खाता', 'Account'],
    'verified': ['सत्यापित', 'Verified'],
    'notVerified': ['सत्यापित नहीं', 'Not verified'],
    'logoutConfirm': ['क्या आप लॉगआउट करना चाहते हैं?', 'Do you want to logout?'],

    // Refer & Earn
    'referEarn': ['रेफर करें और कमाएँ', 'Refer & Earn'],
    'referEarnSub': ['दोस्तों को बुलाएँ, पॉइंट कमाएँ', 'Invite friends, earn points'],
    'yourPoints': ['आपके पॉइंट', 'Your points'],
    'yourReferralCode': ['आपका रेफरल कोड', 'Your referral code'],
    'shareCode': ['कोड शेयर करें', 'Share code'],
    'copied': ['कॉपी हो गया', 'Copied'],
    'referralsJoined': ['दोस्त जुड़े', 'friends joined'],
    'haveACode': ['किसी का कोड है?', 'Have a code?'],
    'enterReferralCode': ['रेफरल कोड डालें', 'Enter referral code'],
    'redeemPoints': ['पॉइंट इस्तेमाल करें', 'Use your points'],
    'boostProfile': ['प्रोफ़ाइल बूस्ट', 'Boost Profile'],
    'boostProfileSub': ['नियोक्ता को पहले दिखें (7 दिन)', 'Show first to employers (7 days)'],
    'panIndiaJobs': ['पूरे भारत के काम', 'Pan-India Jobs'],
    'panIndiaJobsSub': ['अपने शहर के बाहर के काम देखें (30 दिन)', 'See jobs outside your city (30 days)'],
    'redeem': ['पाएँ', 'Redeem'],
    'active7': ['चालू', 'Active'],
    'notEnoughPoints': ['पर्याप्त पॉइंट नहीं', 'Not enough points'],
    'points': ['पॉइंट', 'points'],
    'howItWorks': ['हर दोस्त के जुड़ने पर 100 पॉइंट कमाएँ।', 'Earn 100 points for every friend who joins.'],

    // Onboarding — common
    'stepOf': ['चरण', 'Step'],
    'saveFailed': ['सेव नहीं हो सका। फिर कोशिश करें।', 'Could not save. Please try again.'],
    'optional': ['वैकल्पिक', 'Optional'],

    // Personal details
    'addPhoto': ['फोटो जोड़ें', 'Add photo'],
    'fullName': ['पूरा नाम', 'Full name'],
    'asPerAadhaar': ['आधार के अनुसार', 'As per Aadhaar'],
    'dateOfBirth': ['जन्म तिथि', 'Date of birth'],
    'dobHint': ['साल-महीना-दिन', 'Year-Month-Day'],
    'fatherHusbandName': ['पिता / पति का नाम', "Father's / Husband's name"],
    'gender': ['लिंग', 'Gender'],
    'male': ['पुरुष', 'Male'],
    'female': ['महिला', 'Female'],
    'other': ['अन्य', 'Other'],
    'education': ['शिक्षा', 'Education'],
    'eduNone': ['कोई नहीं', 'None'],
    'eduClass5': ['कक्षा 5', 'Class 5'],
    'edu10': ['10वीं पास', '10th pass'],
    'edu12': ['12वीं पास', '12th pass'],
    'eduGrad': ['ग्रेजुएट', 'Graduate'],
    'eduPostgrad': ['पोस्ट-ग्रेजुएट', 'Post-graduate'],
    'nameRequired': ['कृपया अपना नाम दर्ज करें', 'Please enter your name'],

    // Occupation
    'yourWorkSkills': ['आपका काम और हुनर', 'Your work & skills'],
    'whatWorkDoYouDo': ['आप कौन सा काम करते हैं?', 'What work do you do?'],
    'selectOneOrMore': ['एक या ज़्यादा चुन सकते हैं', 'Select one or more'],
    'selectAtLeastOne': ['कम से कम एक काम चुनें', 'Select at least one'],
    'vehicleType': ['वाहन का प्रकार', 'Vehicle type'],
    'drivingLicence': ['ड्राइविंग लाइसेंस नंबर', 'Driving licence number'],
    'howManyYearsExp': ['कितने साल का अनुभव?', 'How many years of experience?'],

    // Work history
    'prevEmployerInfo': ['पिछले नियोक्ता की जानकारी दें', 'Add your previous employer info'],
    'employerN': ['नियोक्ता', 'Employer'],
    'companyEmployerName': ['कंपनी / नियोक्ता का नाम', 'Company / employer name'],
    'yourRole': ['आपका पद / काम', 'Your role / job'],
    'fromYear': ['किस साल से', 'From year'],
    'toYear': ['किस साल तक (अभी काम कर रहे हैं तो खाली छोड़ें)', 'To year (leave blank if current)'],
    'refName': ['संदर्भ व्यक्ति का नाम', 'Reference name'],
    'refMobile': ['संदर्भ मोबाइल', 'Reference mobile'],
    'reasonLeaving': ['छोड़ने का कारण', 'Reason for leaving'],
    'betterPay': ['बेहतर वेतन', 'Better pay'],
    'familyReason': ['पारिवारिक कारण', 'Family reason'],
    'relocation': ['जगह बदली', 'Relocation'],
    'contractEnded': ['काम पूरा हुआ', 'Contract ended'],
    'addEmployer': ['एक और नियोक्ता जोड़ें', 'Add another employer'],
    'noExperienceSkip': ['कोई अनुभव नहीं — छोड़ें', 'No experience — skip'],

    // Location
    'locationPrefsTitle': ['जगह और पसंद', 'Location & preferences'],
    'livingAddress': ['रहने का पता', 'Living address'],
    'currentAddress': ['आपका वर्तमान पता', 'Your current address'],
    'city': ['शहर', 'City'],
    'pincode': ['पिनकोड', 'Pincode'],
    'preferredCities': ['पसंदीदा शहर (कई चुन सकते हैं)', 'Preferred cities (choose many)'],
    'willingLiveIn': ['नियोक्ता के घर रहने को तैयार', "Willing to live at employer's home"],
    'openPanIndia': ['पूरे भारत में काम के लिए तैयार', 'Open to work across India'],

    // KYC
    'identityVerification': ['पहचान सत्यापन', 'Identity verification'],
    'completeAll5': ['सभी 5 चरण पूरे करें — काम पाने के लिए ज़रूरी है', 'Complete all 5 steps — required to get work'],
    'done': ['पूरा', 'Done'],
    'takePhoto': ['फोटो लें', 'Take photo'],
    'enterAddress': ['पता दर्ज करें', 'Enter address'],
    'saveAddress': ['पता सेव करें', 'Save address'],
    'linkAadhaar': ['आधार जोड़ें', 'Link Aadhaar'],
    'verifyPanBtn': ['PAN जाँचें', 'Verify PAN'],
    'startCheck': ['जाँच शुरू करें', 'Start check'],
    'congrats': ['बधाई हो!', 'Congratulations!'],
    'fullyVerifiedBody': [
      'आपकी पहचान पूरी तरह सत्यापित हो गई है। अब आप सभी काम देख सकते हैं।',
      'Your identity is fully verified. You can now see all jobs.'
    ],
    'goToDashboard': ['डैशबोर्ड पर जाएं', 'Go to dashboard'],
    'bgcInProgress': ['जाँच चल रही है — 24-48 घंटे में पूरा होगा', 'Check in progress — done in 24-48 hours'],
    'state': ['राज्य', 'State'],
  };
}

/// Current UI language code ('en' or 'hi').
String get lang => Get.locale?.languageCode == 'en' ? 'en' : 'hi';
bool get isEn => lang == 'en';

/// Inline bilingual string for one-off copy that isn't in the dictionary.
String l(String en, String hi) => isEn ? en : hi;
