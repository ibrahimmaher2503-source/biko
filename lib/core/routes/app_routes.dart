/// Route name constants for all apps (Customer, Driver, Admin)
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // ==================== Shared Routes ====================
  /// Initial splash screen
  static const String splash = '/splash';

  /// Language selection screen
  static const String languageSelection = '/language-selection';

  /// Onboarding screens
  static const String onboarding = '/onboarding';

  /// Demo screens for development/testing
  static const String demoTheme = '/demo-theme';
  static const String demoWidgets = '/demo-widgets';

  // ==================== Authentication Routes (Shared) ====================
  /// Phone number login
  static const String phoneLogin = '/auth/phone';

  /// OTP verification
  static const String otpVerification = '/auth/otp';

  /// Profile setup
  static const String profileSetup = '/auth/profile-setup';

  // ==================== Customer App Routes ====================
  /// Customer home screen
  static const String customerHome = '/customer/home';

  /// Create trip/delivery request
  static const String createTrip = '/customer/trip/create';

  /// Set pickup location
  static const String setPickup = '/customer/trip/pickup';

  /// Set dropoff location
  static const String setDropoff = '/customer/trip/dropoff';

  /// View and accept bids
  static const String viewBids = '/customer/trip/bids';

  /// Track active trip
  static const String trackTrip = '/customer/trip/track';

  /// Trip completed screen
  static const String tripCompleted = '/customer/trip/completed';

  /// Rate driver
  static const String rateDriver = '/customer/trip/rate';

  /// Customer wallet
  static const String customerWallet = '/customer/wallet';

  /// Top up wallet
  static const String topUpWallet = '/customer/wallet/top-up';

  /// Promo codes
  static const String promoCodes = '/customer/promo';

  /// Referral program
  static const String referral = '/customer/referral';

  /// Trip history
  static const String tripHistory = '/customer/history';

  /// Notifications
  static const String notifications = '/customer/notifications';

  /// Customer profile
  static const String customerProfile = '/customer/profile';

  /// Customer settings
  static const String customerSettings = '/customer/settings';

  /// Chat with driver
  static const String customerChat = '/customer/chat';

  // ==================== Driver App Routes ====================
  /// Driver home screen
  static const String driverHome = '/driver/home';

  /// Driver registration
  static const String driverRegistration = '/driver/register';

  /// Upload documents
  static const String uploadDocuments = '/driver/documents/upload';

  /// Pending approval screen
  static const String pendingApproval = '/driver/pending';

  /// Incoming trip requests
  static const String incomingRequests = '/driver/requests';

  /// Submit bid for trip
  static const String submitBid = '/driver/bid';

  /// Navigate to pickup
  static const String navigateToPickup = '/driver/navigate/pickup';

  /// Active trip screen
  static const String activeTrip = '/driver/trip/active';

  /// Trip complete screen
  static const String driverTripComplete = '/driver/trip/complete';

  /// Driver earnings
  static const String earnings = '/driver/earnings';

  /// Driver wallet
  static const String driverWallet = '/driver/wallet';

  /// Driver ratings
  static const String driverRatings = '/driver/ratings';

  /// Driver documents management
  static const String driverDocuments = '/driver/documents';

  /// Driver profile
  static const String driverProfile = '/driver/profile';

  /// Driver settings
  static const String driverSettings = '/driver/settings';

  /// Chat with customer
  static const String driverChat = '/driver/chat';

  // ==================== Admin Panel Routes ====================
  /// Admin login
  static const String adminLogin = '/admin/login';

  /// Admin dashboard
  static const String adminDashboard = '/admin/dashboard';

  /// Manage users
  static const String adminUsers = '/admin/users';

  /// User details
  static const String adminUserDetail = '/admin/users/detail';

  /// Driver document approvals
  static const String adminDriverDocuments = '/admin/drivers/documents';

  /// Manage trips
  static const String adminTrips = '/admin/trips';

  /// Trip details
  static const String adminTripDetail = '/admin/trips/detail';

  /// Financial overview
  static const String adminFinancial = '/admin/financial';

  /// Transaction ledger
  static const String adminTransactions = '/admin/transactions';

  /// App configuration
  static const String adminConfig = '/admin/config';

  /// Commission settings
  static const String adminCommission = '/admin/config/commission';

  /// Promo codes management
  static const String adminPromos = '/admin/promos';

  /// Referral configuration
  static const String adminReferralConfig = '/admin/referral';

  /// Send notifications
  static const String adminNotifications = '/admin/notifications';

  /// Analytics and reports
  static const String adminAnalytics = '/admin/analytics';

  /// Customer management list
  static const String adminCustomers = '/admin/customers';

  /// Customer detail
  static const String adminCustomerDetail = '/admin/customers/detail';

  /// Driver management list
  static const String adminDrivers = '/admin/drivers';

  /// Driver detail
  static const String adminDriverDetail = '/admin/drivers/detail';

  /// Admin not found / 404
  static const String adminNotFound = '/admin/not-found';

  // ==================== Admin Approval Queue ====================
  /// Driver approval queue
  static const String adminApprovalQueue = '/admin/approvals';

  /// Driver review (individual driver approval)
  static const String adminDriverReview = '/admin/approvals/review';

  // ==================== Admin Promo Detail ====================
  /// Promo code detail view
  static const String adminPromoDetail = '/admin/promos/detail';

  // ==================== Admin Finance Routes ====================
  /// Financial dashboard
  static const String adminFinancialDashboard = '/admin/finance/dashboard';

  /// Revenue analytics
  static const String adminRevenue = '/admin/finance/revenue';

  /// Commission management
  static const String adminCommissions = '/admin/finance/commissions';

  /// Driver earnings
  static const String adminDriverEarnings = '/admin/finance/driver-earnings';

  /// Driver earnings detail
  static const String adminDriverEarningsDetail =
      '/admin/finance/driver-earnings/detail';

  /// Wallet monitoring
  static const String adminWalletMonitoring = '/admin/finance/wallets';

  /// Payment analytics
  static const String adminPaymentAnalytics = '/admin/finance/payments';

  /// Transaction monitor
  static const String adminTransactionMonitor = '/admin/finance/transactions';

  /// Financial reports
  static const String adminReports = '/admin/finance/reports';

  /// Settlement
  static const String adminSettlement = '/admin/finance/settlement';
}
