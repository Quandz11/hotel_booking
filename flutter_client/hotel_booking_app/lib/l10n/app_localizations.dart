import 'package:flutter/material.dart';
// Import concrete implementations
import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

/// Abstract class containing all localized strings
abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('vi', ''),
  ];

  // Authentication strings
  String get accountNotVerified;
  String get accountSettings;
  String get addToFavorites;
  String get admin;
  String get allBookings;
  String get appName;
  String get bookNow;
  String get booking;
  String get bookingConfirmed;
  String get bookingCancelled;
  String get bookings;
  String get cancel;
  String get checkIn;
  String get checkOut;
  String get close;
  String get confirmBooking;
  String get customer;
  String get date;
  String get description;
  String get email;
  String get firstName;
  String get fullName;
  String get guests;
  String get home;
  String get hotels;
  String get language;
  String get lastName;
  String get loading;
  String get login;
  String get logout;
  String get maxGuests;
  String get name;
  String get ok;
  String get password;
  String get phoneNumber;
  String get price;
  String get profile;
  String get register;
  String get reviews;
  String get rooms;
  String get save;
  String get search;
  String get settings;
  String get status;
  String get submit;
  String get totalPrice;
  String get user;
  String get welcome;
  String get forgotPassword;
  String get resetPassword;
  String get verifyEmail;
  String get resendCode;
  String get emailAddress;
  String get confirmPassword;
  String get verificationCode;
  String get newPassword;
  String get currentPassword;
  String get loginSuccess;
  String get registerSuccess;
  String get logoutSuccess;
  String get passwordResetSuccess;
  String get emailVerified;
  String get invalidEmail;
  String get invalidPassword;

  // Hotel related strings
  String get bedType;
  String get hotelDetails;
  String get amenities;
  String get location;
  String get hotelDescription;
  String get hotelAmenities;
  String get night;
  String get available;
  String get unavailable;

  // Booking related strings
  String get bookingNumber;
  String get guestName;
  String get roomType;
  String get totalAmount;

  // Payment related strings
  String get paymentMethod;
  String get paymentStatus;
  String get creditCard;
  String get debitCard;
  String get bankTransfer;
  String get vnpay;
  String get paymentSuccess;
  String get paymentFailed;
  String get paymentPending;
  String get paymentCancelled;
  String get payNow;
  String get amountToPay;
  String get selectPaymentMethod;
  String get cardNumber;
  String get expiryDate;
  String get cvv;
  String get cardHolderName;
  String get billDetails;
  String get subtotal;
  String get taxes;
  String get total;
  String get proceedToPayment;
  String get paymentProcessing;
  String get redirectingToBank;
  String get pleaseWait;
  String get paymentCompleted;
  String get paymentDeclined;
  String get tryAgain;
  String get backToHome;

  // Error and validation messages
  String get errorOccurred;
  String get networkError;
  String get serverError;
  String get unauthorized;
  String get forbidden;
  String get notFound;
  String get validationError;
  String get fieldRequired;
  String get invalidFormat;
  String get tooShort;
  String get tooLong;
  String get passwordTooShort;
  String get passwordMismatch;
  String get invalidEmailFormat;
  String get phoneNumberRequired;
  String get phoneNumberInvalid;
  String get fieldRequiredMessage;
  String get invalidEmailMessage;
  String get fieldTooShortMessage;
  String get passwordMismatchMessage;

  // Navigation and actions
  String get back;
  String get next;
  String get done;
  String get edit;
  String get delete;
  String get add;
  String get update;
  String get create;
  String get view;
  String get details;
  String get refresh;
  String get retry;
  String get skipForNow;
  String get continueText;
  String get continue_;

  // Date and time
  String get today;
  String get tomorrow;
  String get yesterday;
  String get selectDate;
  String get selectTime;
  String get dateFormat;
  String get timeFormat;
  String get duration;
  String get nights;

  // Status messages
  String get confirmed;
  String get pending;
  String get cancelled;
  String get completed;
  String get active;
  String get inactive;
  String get approved;
  String get rejected;
  String get all;

  // UI elements
  String get noDataAvailable;
  String get noResultsFound;
  String get emptyList;
  String get searchHint;
  String get filterResults;
  String get sortBy;
  String get ascending;
  String get descending;
  String get showMore;
  String get showLess;
  String get expandAll;
  String get collapseAll;
  String get noBookingsFound;
  String get startBookingToSeeHere;

  // Notifications and alerts
  String get success;
  String get error;
  String get warning;
  String get info;
  String get confirmation;
  String get deleteConfirmation;
  String get saveChanges;
  String get discardChanges;
  String get unsavedChanges;
  String get areYouSure;

  // Hotel owner specific
  String get dashboard;
  String get manageHotels;
  String get manageRooms;
  String get manageBookings;
  String get addHotel;
  String get editHotel;
  String get deleteHotel;
  String get hotelAdded;
  String get hotelUpdated;
  String get hotelDeleted;
  String get addRoom;
  String get editRoom;
  String get deleteRoom;
  String get roomAdded;
  String get roomUpdated;
  String get roomDeleted;
  String get selectHotel;
  String get allHotels;
  String get allStatuses;
  String get overview;
  String get totalBookings;
  String get revenue;
  String get occupancyRate;
  String get totalRooms;
  String get quickActions;
  String get recentBookings;
  String get viewAll;
  String get noRecentBookings;
  String get myHotels;
  String get noHotelsYet;
  String get addHotelDescription;
  String get editHotelDescription;
  String get deleteHotelConfirmation;
  String get deleting;
  String get deletedSuccessfully;
  String get failedToDelete;
  String get noRoomsFound;
  String get addFirstRoom;
  String get welcome_;
  String get manageYourHotelBusiness;
  String get tryDifferentSearch;
  String get addYourFirstHotel;
  String get reports;

  // Reports strings
  String get week;
  String get month;
  String get year;
  String get customDate;
  String get selectDateRange;
  String get totalRevenue;
  String get averageRating;
  String get revenueOverTime;
  String get bookingsByStatus;
  String get topPerformingRooms;
  String get revenueBreakdown;
  String get monthlyComparison;
  String get roomOccupancy;
  String get roomPerformance;

  // Search and home
  String get welcomeMessage;
  String get findYourPerfectStay;
  String get nearbyHotels;
  String get seeAll;
  String get searchForHotels;
  String get destination;
  String get enterDestination;
  String get popularDestinations;

  // Profile and settings
  String get guest;
  String get comingSoon;
  String get myBookings;
  String get paymentMethods;
  String get helpSupport;
  String get privacyPolicy;
  String get selectLanguage;
  String get logoutConfirmation;

  // Chatbot
  String get chatbot;
  String get chatbotWelcome;
  String get suggestedQuestions;
  String get typeMessage;

  // Booking screens
  String get upcoming;
  String get hotelName;

  // Additional missing getters
  String get forgotPasswordPrompt;
  String get loginPrompt;
  String get rememberMe;
  String get dontHaveAccount;
  String get agreeToTerms;
  String get registerPrompt;
  String get selectRole;
  String get hotelOwner;
  String get optional;
  String get terms;
  String get privacy;
  String get alreadyHaveAccount;
  String get verificationPrompt;
  String get bookingDetails;
  String get customerName;
  String get specialRequests;
  String get viewBookings;
  String get viewReports;
  String get adults;
  String get children;
  String get guestInformation;
  String get pleaseEnterFirstName;
  String get pleaseEnterLastName;
  String get pleaseEnterEmail;
  String get pleaseEnterPhoneNumber;
  String get specialRequestsHint;
  String get stripe;
  String get paymentSummary;
  String get taxesAndFees;
  String get stripePaymentNotImplemented;
  String get payment;
  String get bookingInformation;
  String get roomName;
  String get availableRooms;
  String get selectRoom;
  String get noRoomsAvailable;
  String get searchHotels;
  String get noHotelsFound;
  String get roomDetails;
  String get favorites;
  String get featuredHotels;
  String get editProfile;
  String get notifications;
  String get createBookingFailed;

  // Edit Profile strings
  String get basicInformation;
  String get notificationPreferences;
  String get tapToChangePhoto;
  String get chooseFromGallery;
  String get takePhoto;
  String get removePhoto;
  String get address;
  String get firstNameRequired;
  String get lastNameRequired;
  String get emailRequired;
  String get invalidPhone;
  String get emailNotifications;
  String get smsNotifications;
  String get receiveEmailUpdates;
  String get receiveSmsUpdates;
  String get profileUpdatedSuccess;
  String get profileUpdateFailed;

  // Customer bookings specific strings
  String get myBookingsTitle;
  String get bookingDetailsTitle;
  String get bookingInfo;
  String get timeInfo;
  String get guestInfo;
  String get paymentInfo;
  String get bookingId;
  String get hotel;
  String get room;
  String get bookingStatus;
  String get checkInDate;
  String get checkOutDate;
  String get nightsCount;
  String get bookedAt;
  String get adultsCount;
  String get childrenCount;
  String get guestEmail;
  String get paymentStatusLabel;
  String get paymentMethodLabel;
  String get totalAmountLabel;
  String get noBookingsYet;
  String get exploreHotels;
  String get pleaseLoginToViewBookings;
  String get loginToView;
  String get errorLoadingBookings;
  String get loadingBookings;
  String get actions;
  String get continuePayment;
  String get cancelBooking;
  String get cancelBookingConfirmation;
  String get bookingCancelledSuccess;
  String get errorCancellingBooking;
  String get paymentExpiredMessage;
  String get statusCheckedIn;
  String get statusCheckedOut;
  String get paymentExpired;
  String get confirmCancelBooking;
  String get cancelBookingMessage;
  String get cancelBookingNote;
  String get no;

  // Hotel form specific strings
  String get pleaseEnterHotelName;
  String get pleaseEnterDescription;
  String get starRating;
  String get stars;
  String get streetAddress;
  String get pleaseEnterStreetAddress;
  String get city;
  String get pleaseEnterCity;
  String get state;
  String get pleaseEnterState;
  String get country;
  String get pleaseEnterCountry;
  String get zipCode;
  String get pleaseEnterZipCode;
  String get contactInformation;
  String get pleaseEnterValidEmail;
  String get website;
  String get checkInTime;
  String get checkOutTime;
  String get cancellationPolicy;
  String get flexible;
  String get moderate;
  String get strict;
  String get images;
  String get addImages;
  String get noImagesSelected;
  String get noImages;
  String get errorLoadingHotel;
  String get hotelNotFound;
  String get confirmDelete;
  String get confirmDeleteHotelMessage;
  String get hotelDeletedSuccessfully;
  String get statistics;
  String get totalReviews;
  String get noAmenities;
  String get confirmDeleteMessage;


  // Status texts
  String get statusConfirmed;
  String get statusPending;
  String get statusCancelled;

  // Room selection strings
  String get selectRoomForHotel;
  String get checkInLabel;
  String get checkOutLabel;
  String get guestsLabel;
  String get selectCheckIn;
  String get selectCheckOut;
  String get selectGuests;
  String get updateGuests;
  String get tryDifferentDates;
  String get perNight;
  String get totalFor;
  String get selectThisRoom;
  String get maxGuestsLabel;
  String get amenitiesLabel;

  // Payment screen strings  
  String get bankSelection;
  String get selectBank;
  String get skipBankSelection;
  String get paymentInstructions;
  String get paymentInstructionsText;
  String get continueToPayment;
  String get retryPayment;
  String get retryPaymentDescription;

  // Room management strings

  String get roomDescription;
  String get pleaseEnterRoomName;
  String get pleaseEnterRoomDescription;
  String get standardRoom;
  String get deluxeRoom;
  String get suiteRoom;
  String get executiveRoom;
  String get presidentialRoom;
  String get singleBed;
  String get doubleBed;
  String get queenBed;
  String get kingBed;
  String get twinBed;
  String get bedCount;
  String get pleaseEnterMaxGuests;
  String get basePrice;
  String get weekendPrice;
  String get pleaseEnterBasePrice;
  String get pleaseEnterWeekendPrice;
  String get roomSize;
  String get roomSizeHint;
  String get pleaseEnterTotalRooms;
  String get roomAmenities;
  String get discountPercentage;
  String get specialOffer;
  String get roomManagement;
  String get roomImages;
  String get wifi;
  String get airConditioning;
  String get tv;
  String get minibar;
  String get safe;
  String get balcony;
  String get cityView;
  String get oceanView;
  String get mountainView;
  String get kitchenette;
  String get bathtub;
  String get shower;
  String get hairdryer;
  String get coffeeMaker;
  String get telephone;
  String get desk;
  String get sofa;
  String get roomInfo;
  String get selectHotelFirst;
  String get activateRoom;
  String get deactivateRoom;
  String get roomStatus;
  String get toggleRoomStatus;

  // Additional method-style getters
  String formatCurrency(double amount);
  String formatDate(DateTime date);
  String formatTime(DateTime time);
  String formatDateTime(DateTime dateTime);
  String pluralNights(int count);
  String pluralGuests(int count);
  String formatDuration(int days);
  String formatPrice(double price);
  
  // Additional missing strings
  String get activate;
  String get deactivate;
  String get discount;
  String get bedInfo;
  String get manageHotelRooms;
  String get roomActivatedSuccess;
  String get roomDeactivatedSuccess;
  String get deleteRoomConfirmation;
  String get roomDeletedSuccess;
  String get deleteRoomFailed;
  String get noRoomsYet;
  String get addRoomFirst;
  String get activeRooms;
}

/// Delegate for AppLocalizations
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'vi':
        return AppLocalizationsVi();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

