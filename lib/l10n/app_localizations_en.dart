// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Humsafar';

  @override
  String get guardianAppTitle => 'Guardian App';

  @override
  String get dependentAppTitle => 'Dependent App';

  @override
  String get devRoleSwitcherTitle => 'Humsafar — Dev Role Switcher';

  @override
  String get devRoleSwitcherBody =>
      'Temporary screen — will be replaced by real login (Task 1.11 / 2.5).';

  @override
  String get continueAsGuardian => 'Continue as Guardian';

  @override
  String get continueAsDependent => 'Continue as Dependent';

  @override
  String get guardianHomePlaceholder =>
      'Guardian home screen placeholder.\nReal dashboard content lands from Phase 2 onward.';

  @override
  String get dependentHomePlaceholder =>
      'Dependent home screen placeholder.\nThe 3 safety actions (Panic Mode, Wellness Check, Medication) land here from Task 3.10 onward.';

  @override
  String get switchModeTooltip => 'Switch mode (dev only)';

  @override
  String get switchToStandardView => 'Switch to standard view';

  @override
  String get switchToAccessibleView =>
      'Switch to large-text, high-contrast view';

  @override
  String get previewLoginLink => 'Preview: Login screen (Task 1.11)';

  @override
  String get previewRegisterLink => 'Preview: Register screen (Task 1.11)';

  @override
  String get registerScreenTitle => 'Create Account';

  @override
  String get loginScreenTitle => 'Login';

  @override
  String get guardianVerificationTitle => 'Guardian Verification';

  @override
  String get dependentKycTitle => 'Dependent Verification (KYC)';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get registeringAsLabel => 'Registering as';

  @override
  String get roleGuardianOption => 'Guardian';

  @override
  String get roleDependentOption => 'Dependent';

  @override
  String get registerButton => 'Register';

  @override
  String get loginButton => 'Login';

  @override
  String get alreadyHaveAccountPrompt => 'Already have an account? Login';

  @override
  String get dontHaveAccountPrompt => 'Don\'t have an account? Register';

  @override
  String get fieldRequiredError => 'This field is required';

  @override
  String get invalidEmailError => 'Enter a valid email address';

  @override
  String get passwordTooShortError => 'Password must be at least 8 characters';

  @override
  String get passwordTooWeakError =>
      'Password must include at least one letter and one number';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match';

  @override
  String get invalidPhoneError =>
      'Enter a valid Pakistani phone number (e.g. 03XXXXXXXXX)';

  @override
  String get invalidCnicError => 'Enter CNIC in the format XXXXX-XXXXXXX-X';

  @override
  String get cnicLabel => 'CNIC Number';

  @override
  String get cnicHint => 'XXXXX-XXXXXXX-X';

  @override
  String get sendOtpButton => 'Send OTP';

  @override
  String get otpSentDummyMessage => 'OTP sent (dummy — Task 1.11 UI only)';

  @override
  String get otpLabel => 'Enter OTP';

  @override
  String get verifyAndContinueButton => 'Verify & Continue';

  @override
  String get noLivenessRequiredNote =>
      'Guardian verification does not require a liveness photo.';

  @override
  String get captureLivenessButton => 'Capture Liveness Photo';

  @override
  String get livenessCapturedConfirmation => 'Liveness photo captured (mock)';

  @override
  String get submitForVerificationButton => 'Submit for Verification';

  @override
  String get genericValidationError => 'Please check the fields and try again.';

  @override
  String get retryButton => 'Retry';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get goToLoginButton => 'Go to login';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get yesLabel => 'Yes';

  @override
  String get notYetLabel => 'Not yet';

  @override
  String get primaryRoleLabel => 'Primary';

  @override
  String get secondaryRoleLabel => 'Secondary';

  @override
  String get primaryGuardianFullLabel => 'Primary Guardian';

  @override
  String get secondaryGuardianFullLabel => 'Secondary Guardian';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get notVerifiedLabel => 'Not verified';

  @override
  String get guardianVerifyEitherOptionNote =>
      'Either option below is enough to verify your account — you don\'t need to do both.';

  @override
  String get guardianVerifyOptionAHeader => 'Option A: verify by phone OTP';

  @override
  String get guardianVerifyOptionBHeader => 'Option B: verify by CNIC';

  @override
  String get resendOtpButton => 'Resend OTP';

  @override
  String get otpSentSnackbar => 'OTP sent to your registered phone number.';

  @override
  String get otpNotVerifiedYetSnackbar =>
      'Not verified yet — try the CNIC check below instead.';

  @override
  String get otpInvalidError =>
      'That code is wrong or expired. Try again or resend.';

  @override
  String get cnicCheckFailedSnackbar =>
      'CNIC check failed — try the phone OTP above instead.';

  @override
  String get openingCameraLabel => 'Opening camera...';

  @override
  String get lostRegistrationDetailsError =>
      'We lost track of your registration details (this happens if the app was closed). Please register again to continue.';

  @override
  String get kycInvalidCredentialsError =>
      'Something\'s wrong with your account details - please register again.';

  @override
  String get kycAlreadyVerifiedError =>
      'You\'re already verified. Try logging in once your guardian links you.';

  @override
  String get cnicAlreadyRegisteredError =>
      'This CNIC is already registered to another account.';

  @override
  String get kycValidationError =>
      'Please check the CNIC and photo and try again.';

  @override
  String get kycVerifiedWaitingDefaultMessage =>
      'Verified. Waiting for your Primary Guardian to link you.';

  @override
  String get shareIdWithGuardianLabel =>
      'Share this ID with your Guardian so they can link you:';

  @override
  String get kycVerifiedActiveDefaultMessage => 'You\'re verified and active.';

  @override
  String get kycPendingDefaultMessage => 'Still pending - please submit again.';

  @override
  String get kycFailedDefaultMessage =>
      'Verification failed - please try again.';

  @override
  String get inviteCodeOptionalLabel => 'Invite code (optional)';

  @override
  String get inviteCodeHelperText =>
      'Only if a Primary Guardian invited you as a Secondary Guardian.';

  @override
  String get roleLockedToGuardianNote =>
      'Role locked to Guardian while an invite code is entered.';

  @override
  String get inviteInvalidError => 'That invite code isn\'t valid.';

  @override
  String get inviteExpiredError =>
      'That invite code has expired - ask for a new one.';

  @override
  String get inviteNotForYouRegisterError =>
      'This invite was sent to a different phone number - use the exact number it was sent to.';

  @override
  String get guardianCapReachedError =>
      'This Dependent already has the maximum of 3 Guardians.';

  @override
  String get emailAlreadyRegisteredError =>
      'This email is already registered. Try logging in instead.';

  @override
  String get phoneAlreadyRegisteredError =>
      'This phone number is already registered.';

  @override
  String get accountAlreadyRegisteredError =>
      'This account already exists. Try logging in instead.';

  @override
  String get invalidCredentialsError => 'Incorrect email or password.';

  @override
  String get accountNotActivatedError =>
      'Your account isn\'t active yet — complete KYC and wait for your guardian to link you.';

  @override
  String get haveInviteCodeButton => 'Have an invite code?';

  @override
  String get linkADependentLabel => 'Link a Dependent';

  @override
  String get noDependentsLinkedMessage =>
      'You\'re not linked to any Dependents yet. Use \"Link a Dependent\" below with their ID to get started.';

  @override
  String get kycStatusPrefixLabel => 'KYC';

  @override
  String get accountActiveLabel => 'Active';

  @override
  String get accountNotActiveLabel => 'Not active yet';

  @override
  String get kycStatusPending => 'Pending';

  @override
  String get kycStatusVerified => 'Verified';

  @override
  String get kycStatusFailed => 'Failed';

  @override
  String get linkDependentInstructions =>
      'Ask the Dependent for the ID shown on their verification screen, then enter it below.';

  @override
  String get dependentIdLabel => 'Dependent\'s ID';

  @override
  String get linkButton => 'Link';

  @override
  String get linkedSuccessSnackbar =>
      'Linked! You can now see this Dependent on your home screen.';

  @override
  String get guardianNotVerifiedLinkError =>
      'You need to verify your own account before you can link a Dependent.';

  @override
  String get secondaryCannotLinkError =>
      'Only a Primary Guardian can link a Dependent - your account is Secondary.';

  @override
  String get dependentNotFoundError =>
      'No account found with that ID - double check it and try again.';

  @override
  String get alreadyLinkedError => 'You\'re already linked to this Dependent.';

  @override
  String get primaryAlreadyExistsError =>
      'This Dependent already has a Primary Guardian.';

  @override
  String get yourRoleLabel => 'Your role:';

  @override
  String get kycStatusColonLabel => 'KYC status:';

  @override
  String get accountActiveColonLabel => 'Account active:';

  @override
  String get linkedGuardiansHeader => 'Linked Guardians';

  @override
  String get inviteASecondaryButton => 'Invite a Secondary Guardian';

  @override
  String get managePermissionsButton => 'Manage Permissions';

  @override
  String get myAccessButton => 'My Access';

  @override
  String get invitePhoneInstructions =>
      'Enter the Secondary Guardian\'s phone number. They\'ll need the code this generates.';

  @override
  String get sendInviteButton => 'Send invite';

  @override
  String get guardianNotVerifiedGenericError =>
      'You need to verify your own account first.';

  @override
  String get notPrimaryGuardianError =>
      'You\'re not this Dependent\'s Primary Guardian.';

  @override
  String get inviteeNotEligibleError =>
      'That number can\'t be invited (it may already belong to an account, or be the Dependent\'s own number).';

  @override
  String get invitePhoneValidationError =>
      'Please check the phone number and try again.';

  @override
  String inviteCreatedMessage(int days) {
    return 'Invite created - valid for $days days. Share this code with them:';
  }

  @override
  String get copyCodeButton => 'Copy code';

  @override
  String get copiedSnackbar => 'Copied.';

  @override
  String get inviteShareFooterNote =>
      'They enter this during registration (if they\'re new) or on the \"Have an invite code?\" screen (if they already have a Secondary account).';

  @override
  String get noSecondariesYetMessage =>
      'No Secondary Guardians yet - invite one first.';

  @override
  String get secondaryNotFoundError =>
      'That Guardian is no longer linked to this Dependent.';

  @override
  String get moduleLiveLocation => 'Live Location';

  @override
  String get moduleHealthRecords => 'Health Records';

  @override
  String get moduleCommunication => 'Communication';

  @override
  String get moduleEmergencyAlerts => 'Emergency Alerts';

  @override
  String get moduleCameraViewing => 'Camera Viewing';

  @override
  String get moduleMedicationManagement => 'Medication Management';

  @override
  String get roleColonLabel => 'Role:';

  @override
  String get notLinkedToDependentError =>
      'You\'re not linked to this Dependent.';

  @override
  String get acceptAnInviteTitle => 'Accept an invite';

  @override
  String get pasteInviteCodeInstructions =>
      'Paste the invite code a Primary Guardian shared with you.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get acceptButton => 'Accept';

  @override
  String get inviteAcceptedSnackbar =>
      'Accepted! This Dependent now shows on your home screen.';

  @override
  String get primaryCannotAcceptInviteError =>
      'A Primary Guardian account can\'t accept a Secondary invite.';

  @override
  String get inviteNotForYouAcceptError =>
      'This code was sent to a different phone number than the one on your account.';

  @override
  String get liveMapButton => 'Live Map';

  @override
  String get noLocationYetMessage => 'No location received yet.';

  @override
  String get justNowLabel => 'Just now';

  @override
  String lastSeenMinutesMessage(int minutes) {
    return 'Last seen $minutes min ago';
  }

  @override
  String get locationStaleWarning => 'This location may be out of date.';

  @override
  String get zoneStatusInside => 'Inside a safe zone';

  @override
  String get zoneStatusOutside => 'Outside all safe zones';

  @override
  String get zoneStatusNoZones => 'No safe zones set up yet';

  @override
  String get zoneStatusUnknown => 'Location status unknown';

  @override
  String get moduleAccessDeniedLiveMapError =>
      'You don\'t have permission to view this Dependent\'s location.';

  @override
  String get locationSharingActiveLabel => 'Location sharing: Active';

  @override
  String get locationPermissionNeededMessage =>
      'Location permission is needed so your Guardian can see where you are.';

  @override
  String get grantLocationPermissionButton => 'Grant Permission';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'Location permission was permanently denied. Enable it from your phone\'s Settings.';

  @override
  String get locationServiceDisabledMessage =>
      'Turn on Location Services in your phone\'s Settings to share your location.';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get dependentHomeTitle => 'Home';

  @override
  String dependentHomeGreeting(String name) {
    return 'Assalam o Alaikum, $name';
  }

  @override
  String get panicButtonLabel => 'PANIC';

  @override
  String get panicButtonSubtitle => 'Press for help';

  @override
  String get iAmOkButtonLabel => 'I am OK';

  @override
  String get myMedicineButtonLabel => 'My medicine';

  @override
  String nextWellnessCheckMessage(String time) {
    return 'Next check: $time';
  }

  @override
  String get noWellnessCheckScheduledMessage => 'No wellness check scheduled';

  @override
  String nextMedicationMessage(String drug, String time) {
    return 'Next: $drug at $time';
  }

  @override
  String get noMedicationScheduledMessage => 'No medicine scheduled';

  @override
  String get moreComingSoonLabel =>
      'More: records · appointments · messages (coming soon)';

  @override
  String get panicScreenTitle => 'Panic';

  @override
  String get panicNeedHelpTitle => 'Need help?';

  @override
  String get panicHoldInstructions => 'Press and hold the button for 2 seconds';

  @override
  String get panicHoldButtonLabel => 'HOLD';

  @override
  String get panicHoldButtonSubtitle => 'to send help';

  @override
  String get panicSendingLabel => 'Sending alert...';

  @override
  String get panicAllGuardiansToldNote =>
      'All your Guardians will be told at once.';

  @override
  String get panicHoldStopsAccidentNote => 'Holding stops accidental alerts.';

  @override
  String get panicHelpIsComingTitle => 'Help is coming';

  @override
  String panicToldCountMessage(int count) {
    return 'We told $count Guardian(s)';
  }

  @override
  String panicTriggeredAtMessage(String time) {
    return 'at $time';
  }

  @override
  String panicAcknowledgedAtMessage(String time) {
    return 'Seen by a Guardian at $time';
  }

  @override
  String get panicWaitingForAckMessage => 'Waiting for a Guardian to see this';

  @override
  String get panicEscalatedMessage =>
      'This has reached your emergency contact.';

  @override
  String get panicAutoEscalateNote =>
      'If nobody answers within 5 minutes, your emergency contact is reached.';

  @override
  String get iAmSafeNowButton => 'I am safe now';

  @override
  String get panicResolvedSnackbar => 'Marked safe. Glad you\'re OK.';

  @override
  String get panicTriggerFailedSnackbar =>
      'Couldn\'t send the alert. Check your connection and try again.';

  @override
  String get panicResolveFailedSnackbar =>
      'Couldn\'t mark you safe. Try again.';

  @override
  String get wellnessCheckScreenTitle => 'Wellness check';

  @override
  String get areYouOkTitle => 'Are you OK?';

  @override
  String get familyCheckingOnYouMessage => 'Your family is checking on you';

  @override
  String answerWithinMessage(String time) {
    return 'Answer within $time';
  }

  @override
  String get yesIAmOkButton => 'Yes, I am OK';

  @override
  String get iNeedHelpButton => 'I need help';

  @override
  String get iNeedHelpOpensPanicNote => '\'I need help\' opens Panic.';

  @override
  String get noAnswerGuardianToldNote => 'No answer → your Guardian is told.';

  @override
  String get noWellnessCheckPendingMessage =>
      'There\'s no wellness check waiting for a response right now.';

  @override
  String get wellnessCheckTimeUpNote =>
      'Time\'s up — your Guardian may be notified. You can still answer below.';

  @override
  String get wellnessCheckRespondedSnackbar => 'Thanks — marked as OK.';

  @override
  String get wellnessCheckRespondFailedSnackbar =>
      'Couldn\'t send your answer. Try again.';

  @override
  String get medicationScreenTitle => 'My medicine';

  @override
  String get medicineStep1OfTwoLabel => 'I took my medicine · Step 1 of 2';

  @override
  String get noMedicineDueMessage => 'There\'s no medicine due right now.';

  @override
  String get medicineTimePromptTitle => 'It\'s time for your medicine';

  @override
  String medicineTimePromptMessage(String drug, String dosage) {
    return '$drug ($dosage) — did you take it?';
  }

  @override
  String get medicineTookItButtonLabel => 'I took it';

  @override
  String get medicineConfirmTitle => 'Confirm you took it';

  @override
  String medicineConfirmMessage(String drug, String dosage) {
    return 'Please confirm: $drug ($dosage)';
  }

  @override
  String medicineConfirmExpiresNote(String time) {
    return 'This confirmation expires in $time';
  }

  @override
  String get medicineConfirmButtonLabel => 'Yes, I took it';

  @override
  String get medicineConfirmExpiredMessage =>
      'This confirmation window expired.';

  @override
  String get medicineTryAgainButtonLabel => 'Try again';

  @override
  String get medicineTakenTitle => 'Marked as taken';

  @override
  String medicineTakenMessage(String drug) {
    return '$drug is marked as taken.';
  }

  @override
  String get medicineDoneButtonLabel => 'Done';

  @override
  String get medicineConfirmRequestFailedSnackbar =>
      'Couldn\'t start the confirmation. Try again.';

  @override
  String get medicineConfirmFailedSnackbar => 'Couldn\'t confirm. Try again.';

  @override
  String get medicationScheduleButton => 'Medication schedule';

  @override
  String get wellnessScheduleButton => 'Wellness check schedule';

  @override
  String get medicationScheduleScreenTitle => 'Medication schedule';

  @override
  String get wellnessScheduleScreenTitle => 'Wellness check schedule';

  @override
  String get noMedicationSchedulesMessage => 'No medicines scheduled yet.';

  @override
  String get noWellnessSchedulesMessage =>
      'No wellness check times scheduled yet.';

  @override
  String get useDefaultScheduleButton => 'Use default schedule (8am, 2pm, 8pm)';

  @override
  String get medicationManagementDeniedNote =>
      'You don\'t have permission to manage medicines. Ask the Primary Guardian.';

  @override
  String get wellnessManagementDeniedNote =>
      'You don\'t have permission to manage wellness checks. Ask the Primary Guardian.';

  @override
  String get drugNameFieldLabel => 'Medicine name';

  @override
  String get dosageFieldLabel => 'Dosage';

  @override
  String get timeFieldLabel => 'Time';

  @override
  String get frequencyFieldLabel => 'Frequency';

  @override
  String get dailyLabel => 'Daily';

  @override
  String get weeklyLabel => 'Weekly';

  @override
  String get gracePeriodFieldLabel => 'Grace period (minutes)';

  @override
  String gracePeriodMinutesMessage(int minutes) {
    return 'Grace period: $minutes min';
  }

  @override
  String get addMedicationScheduleTitle => 'Add medicine';

  @override
  String get editMedicationScheduleTitle => 'Edit medicine';

  @override
  String get addWellnessCheckTitle => 'Add check time';

  @override
  String get editWellnessCheckTitle => 'Edit check time';

  @override
  String get scheduleSavedSnackbar => 'Saved.';

  @override
  String get scheduleSaveFailedSnackbar => 'Couldn\'t save. Try again.';

  @override
  String get scheduleUpdateFailedSnackbar => 'Couldn\'t update. Try again.';

  @override
  String get weeklyDaysRequiredError =>
      'Pick at least one day for a weekly schedule.';

  @override
  String get wellnessLimitReachedError =>
      'You can have at most 3 wellness check times.';

  @override
  String get wellnessTimeExistsError =>
      'There\'s already a check at that time.';

  @override
  String get dayMonLabel => 'Mon';

  @override
  String get dayTueLabel => 'Tue';

  @override
  String get dayWedLabel => 'Wed';

  @override
  String get dayThuLabel => 'Thu';

  @override
  String get dayFriLabel => 'Fri';

  @override
  String get daySatLabel => 'Sat';

  @override
  String get daySunLabel => 'Sun';

  @override
  String get goBackButtonLabel => 'Go back';

  @override
  String get alertTypePanic => 'Panic alert';

  @override
  String get alertTypeMissedDose => 'Missed dose';

  @override
  String get alertTypeWellnessCheck => 'Wellness check missed';

  @override
  String get alertTypeGeofenceBreach => 'Left the safe zone';

  @override
  String get alertTypeLowBattery => 'Low battery';

  @override
  String get alertTypeDeviceOffline => 'Phone offline';

  @override
  String get alertTypeExternalContact => 'Emergency contact alert';

  @override
  String get alertTypeGeneric => 'Alert';

  @override
  String get tierLevel1PrimaryLabel => 'Level 1 · Primary';

  @override
  String get tierLevel2SecondaryLabel => 'Level 2 · Secondary';

  @override
  String get tierLevel3SmsLabel => 'Level 3 · SMS sent';

  @override
  String get alertsScreenTitle => 'Alerts';

  @override
  String alertsOpenTabLabel(int count) {
    return 'Open ($count)';
  }

  @override
  String get alertsSeenTabLabel => 'Seen';

  @override
  String get alertsEmptyOpenMessage => 'No open alerts.';

  @override
  String get alertsEmptySeenMessage => 'No seen alerts yet.';

  @override
  String get iveSeenItButton => 'I\'ve seen it';

  @override
  String get seenStopsChainTitle => 'Seen stops the chain';

  @override
  String get seenStopsChainBody => 'Primary → Secondary (5 min) → SMS (5 min)';

  @override
  String get acknowledgeFailedSnackbar => 'Couldn\'t mark as seen. Try again.';

  @override
  String get needsAttentionHeader => 'Needs attention';

  @override
  String get seeAllLabel => 'See all';

  @override
  String get panicBannerTitle => 'PANIC ALERT';

  @override
  String panicBannerBody(String name, String time) {
    return '$name pressed panic · $time';
  }

  @override
  String get openButtonLabel => 'Open';

  @override
  String get missedDoseScreenTitle => 'Missed dose';

  @override
  String missedDoseBannerTitle(String name, String drug) {
    return '$name has not taken $drug';
  }

  @override
  String get whatHappensNextHeader => 'What happens next';

  @override
  String get missedDoseStepYouToldLabel => 'You are told (Primary)';

  @override
  String get missedDoseStepSecondaryLabel => 'Secondaries told if unseen';

  @override
  String get missedDoseStepSmsLabel => 'SMS to emergency contact if unseen';

  @override
  String get giveMoreTimeButton => 'Give more time (+30 min)';

  @override
  String get tellOtherGuardiansButton => 'Tell other Guardians now';

  @override
  String callButtonLabel(String name) {
    return 'Call $name';
  }

  @override
  String get tappingCountsAsSeenNote => 'Tapping any option counts as seen.';

  @override
  String get extendSuccessSnackbar => 'Given 30 more minutes.';

  @override
  String escalateSuccessSnackbar(int count) {
    return '$count Secondary Guardian(s) notified.';
  }

  @override
  String get escalateNoSecondarySnackbar =>
      'No Secondary Guardian can see alerts yet.';

  @override
  String get doseAlreadyResolvedMessage =>
      'This alert has already been resolved.';

  @override
  String get alreadyEscalatedMessage => 'Already told the other Guardians.';

  @override
  String get callFailedSnackbar => 'Couldn\'t start the call.';

  @override
  String get emergencySettingsScreenTitle => 'Emergency settings';

  @override
  String get emergencySettingsButton => 'Emergency settings';

  @override
  String get remoteAlarmSectionTitle => 'Remote alarm';

  @override
  String get primaryOnlyBadge => 'Primary only';

  @override
  String remoteAlarmDescription(String name) {
    return 'Rings $name\'s phone loudly, even on silent. Use it to find them nearby.';
  }

  @override
  String get ringAlarmButton => 'Ring alarm (60 s)';

  @override
  String get stopAlarmButton => 'Stop alarm';

  @override
  String get alarmAlreadyActiveMessage => 'Alarm is already sounding.';

  @override
  String get alarmStartFailedSnackbar =>
      'Couldn\'t start the alarm. Try again.';

  @override
  String get alarmStopFailedSnackbar => 'Couldn\'t stop the alarm. Try again.';

  @override
  String get notPrimaryGuardianNote =>
      'Only the Primary Guardian can use the remote alarm and set the emergency contact.';

  @override
  String get emergencyContactSectionTitle => 'Emergency contact';

  @override
  String get emergencyContactDescription =>
      'Gets one SMS if no Guardian answers an alert in 10 minutes.';

  @override
  String get contactNameFieldLabel => 'Name';

  @override
  String get contactPhoneFieldLabel => 'Phone';

  @override
  String get saveContactButton => 'Save contact';

  @override
  String get contactSavedSnackbar => 'Contact saved.';

  @override
  String get contactSaveFailedSnackbar =>
      'Couldn\'t save the contact. Try again.';

  @override
  String get noEmergencyContactMessage => 'No emergency contact set yet.';

  @override
  String get removeContactButton => 'Remove contact';

  @override
  String get contactRemovedSnackbar => 'Contact removed.';

  @override
  String get contactRemoveFailedSnackbar =>
      'Couldn\'t remove the contact. Try again.';

  @override
  String get emergencyContactDeniedNote =>
      'You can view this but only the Primary Guardian can change it.';

  @override
  String get alarmScreenTitle => 'Alarm';

  @override
  String get alarmLookingForYouTitle => 'Your Guardian is looking for you';

  @override
  String alarmScreenSubtitle(String remaining) {
    return 'Alarm from your Guardian · $remaining left';
  }

  @override
  String get stopAlarmButtonLabel => 'Stop alarm';

  @override
  String get stopAlarmFailedSnackbar => 'Couldn\'t stop the alarm. Try again.';

  @override
  String get noActiveAlarmMessage => 'No alarm is sounding right now.';

  @override
  String get messagesScreenTitle => 'Messages';

  @override
  String get noConversationsYetMessage => 'No conversations yet.';

  @override
  String get noMessagesYetPreview => 'No messages yet';

  @override
  String get urgentVoiceMessageLabel => 'Urgent voice message';

  @override
  String get loadEarlierMessagesButton => 'Load earlier messages';

  @override
  String get startConversationMessage => 'No messages yet. Say hello!';

  @override
  String get messageInputHint => 'Type a message';

  @override
  String get messageSendTooltip => 'Send';

  @override
  String get sendingLabel => 'Sending…';

  @override
  String get notSentTapToRetryLabel => 'Not sent · Tap to retry';

  @override
  String get readLabel => 'Read';

  @override
  String get communicationAccessDeniedMessage =>
      'Only Guardians with Communication access can message right now.';

  @override
  String get messagesButtonLabel => 'Messages';

  @override
  String get messageButtonLabel => 'Message';

  @override
  String unreadMessagesSubtitle(int count) {
    return '$count new message(s)';
  }

  @override
  String get quickReplyIAmFine => 'I am fine';

  @override
  String get quickReplyCallMe => 'Call me';

  @override
  String get quickReplyYes => 'Yes';

  @override
  String get quickReplyNo => 'No';

  @override
  String get recordUrgentVoiceSheetTitle => 'Record an urgent voice message';

  @override
  String urgentVoiceWarningMessage(String peerName) {
    return 'This will ring as a critical alert on $peerName\'s phone, even on silent.';
  }

  @override
  String get tapToStartRecordingLabel => 'Tap to start recording';

  @override
  String recordingInProgressLabel(String time) {
    return 'Recording… $time';
  }

  @override
  String get maxLengthReachedMessage => 'Maximum length reached (2:00).';

  @override
  String get stopRecordingButtonLabel => 'Stop';

  @override
  String get discardRecordingButtonLabel => 'Discard';

  @override
  String get playPreviewButtonLabel => 'Play';

  @override
  String get sendUrgentVoiceButtonLabel => 'Send';

  @override
  String get micPermissionDeniedMessage =>
      'Microphone permission is needed to record a voice message.';

  @override
  String get voiceSendFailedGenericMessage =>
      'Couldn\'t send the voice message. Try again.';

  @override
  String get audioDownloadFailedMessage =>
      'Couldn\'t load the voice message. Try again.';
}
