import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:petvault/petvault_api.dart';
import 'package:petvault/petvault_store.dart';

void main() {
  runApp(const PetVaultApp());
}

const _cream = Color(0xFFFAF7F2);
const _ink = Color(0xFF2B1B14);
const _muted = Color(0xFF806E5D);
const _teal = Color(0xFF427C77);
const _line = Color(0xFFE2D8CC);
const _paleTeal = Color(0xFFE8F1EE);
const _sand = Color(0xFFF1ECE4);

enum AppPage {
  splash,
  welcome,
  authentication,
  registration,
  otp,
  roleSelection,
  petSetup,
  addPet,
  kycVerification,
  home,
  pets,
  petProfile,
  editPet,
  healthRecords,
  addHealthRecord,
  vaccinationSchedule,
  weightHistory,
  favorites,
  vetDirectory,
  vetAvailability,
  teleConsultation,
  marketplace,
  searchFilters,
  listingDetail,
  createListing,
  createListingDetails,
  buyerSellerMessaging,
  reportListing,
  myListings,
  editListing,
  listingPerformance,
  scheduleVisit,
  petVisitRequests,
  shop,
  productDetail,
  checkout,
  orderTracking,
  vendorDashboard,
  vendorProducts,
  addEditProduct,
  vendorOrders,
  vendorOrderDetail,
  sitters,
  bookingCalendar,
  activeSitting,
  adminDashboard,
  kycQueue,
  identityApproval,
  riskQueue,
  listingModeration,
  disputes,
  auditTrail,
  userSettings,
  dataPrivacy,
  notifications,
  aiSupport,
  triageAlert,
  chat,
}

const _ownerTabs = <AppPage>[
  AppPage.home,
  AppPage.pets,
  AppPage.marketplace,
  AppPage.sitters,
  AppPage.chat,
];

const _vendorTabs = <AppPage>[
  AppPage.vendorDashboard,
  AppPage.vendorProducts,
  AppPage.vendorOrders,
  AppPage.shop,
];

const _adminTabs = <AppPage>[
  AppPage.adminDashboard,
  AppPage.kycQueue,
  AppPage.riskQueue,
  AppPage.auditTrail,
];

const _catalogGroups = <String, List<AppPage>>{
  'Getting started': <AppPage>[
    AppPage.splash,
    AppPage.welcome,
    AppPage.authentication,
    AppPage.registration,
    AppPage.otp,
    AppPage.roleSelection,
    AppPage.petSetup,
    AppPage.addPet,
    AppPage.kycVerification,
  ],
  'Pet profiles & care': <AppPage>[
    AppPage.pets,
    AppPage.petProfile,
    AppPage.editPet,
    AppPage.healthRecords,
    AppPage.addHealthRecord,
    AppPage.vaccinationSchedule,
    AppPage.weightHistory,
    AppPage.vetDirectory,
    AppPage.vetAvailability,
    AppPage.teleConsultation,
    AppPage.notifications,
    AppPage.aiSupport,
    AppPage.triageAlert,
  ],
  'Marketplace & listings': <AppPage>[
    AppPage.marketplace,
    AppPage.favorites,
    AppPage.searchFilters,
    AppPage.listingDetail,
    AppPage.createListing,
    AppPage.createListingDetails,
    AppPage.buyerSellerMessaging,
    AppPage.reportListing,
    AppPage.myListings,
    AppPage.editListing,
    AppPage.listingPerformance,
    AppPage.scheduleVisit,
    AppPage.petVisitRequests,
  ],
  'Shop & vendor': <AppPage>[
    AppPage.shop,
    AppPage.productDetail,
    AppPage.checkout,
    AppPage.orderTracking,
    AppPage.vendorDashboard,
    AppPage.vendorProducts,
    AppPage.addEditProduct,
    AppPage.vendorOrders,
    AppPage.vendorOrderDetail,
  ],
  'Pet sitting': <AppPage>[
    AppPage.sitters,
    AppPage.bookingCalendar,
    AppPage.activeSitting,
  ],
  'Trust & administration': <AppPage>[
    AppPage.adminDashboard,
    AppPage.kycQueue,
    AppPage.identityApproval,
    AppPage.riskQueue,
    AppPage.listingModeration,
    AppPage.disputes,
    AppPage.auditTrail,
  ],
  'Account & communication': <AppPage>[
    AppPage.userSettings,
    AppPage.dataPrivacy,
    AppPage.chat,
  ],
};

String _titleFor(AppPage page) {
  switch (page) {
    case AppPage.splash:
      return '01 Splash';
    case AppPage.welcome:
      return '02 Welcome';
    case AppPage.authentication:
      return '03 Sign in';
    case AppPage.registration:
      return '04 Create account';
    case AppPage.otp:
      return '05 Verify email';
    case AppPage.roleSelection:
      return '06 Choose your role';
    case AppPage.petSetup:
      return '07 Your pets';
    case AppPage.addPet:
      return '08 Add a pet';
    case AppPage.kycVerification:
      return 'Identity verification';
    case AppPage.home:
      return 'Home';
    case AppPage.pets:
      return 'My pets';
    case AppPage.petProfile:
      return 'Pet profile';
    case AppPage.editPet:
      return 'Edit pet profile';
    case AppPage.healthRecords:
      return 'Health records';
    case AppPage.addHealthRecord:
      return 'Add health record';
    case AppPage.vaccinationSchedule:
      return 'Vaccination schedule';
    case AppPage.weightHistory:
      return 'Weight & growth';
    case AppPage.favorites:
      return 'My favorites';
    case AppPage.vetDirectory:
      return 'Verified veterinarians';
    case AppPage.vetAvailability:
      return 'Vet availability';
    case AppPage.teleConsultation:
      return 'Consultation';
    case AppPage.marketplace:
      return 'Pets Marketplace';
    case AppPage.searchFilters:
      return 'Search & filters';
    case AppPage.listingDetail:
      return 'Pet listing';
    case AppPage.createListing:
      return 'Create listing · 1 of 2';
    case AppPage.createListingDetails:
      return 'Create listing · 2 of 2';
    case AppPage.buyerSellerMessaging:
      return 'Messages';
    case AppPage.reportListing:
      return 'Report listing';
    case AppPage.myListings:
      return 'My pet listings';
    case AppPage.editListing:
      return 'Edit pet listing';
    case AppPage.listingPerformance:
      return 'Listing performance';
    case AppPage.scheduleVisit:
      return 'Schedule a pet visit';
    case AppPage.petVisitRequests:
      return 'Pet visit requests';
    case AppPage.shop:
      return 'Pet essentials';
    case AppPage.productDetail:
      return 'Product details';
    case AppPage.checkout:
      return 'Secure checkout';
    case AppPage.orderTracking:
      return 'Order tracking';
    case AppPage.vendorDashboard:
      return 'Vendor dashboard';
    case AppPage.vendorProducts:
      return 'Product catalog';
    case AppPage.addEditProduct:
      return 'Add / edit product';
    case AppPage.vendorOrders:
      return 'Vendor orders';
    case AppPage.vendorOrderDetail:
      return 'Order details';
    case AppPage.sitters:
      return 'Trusted sitters';
    case AppPage.bookingCalendar:
      return 'Booking calendar';
    case AppPage.activeSitting:
      return 'Active sitting';
    case AppPage.adminDashboard:
      return 'Admin dashboard';
    case AppPage.kycQueue:
      return 'KYC verification queue';
    case AppPage.identityApproval:
      return 'Identity approval';
    case AppPage.riskQueue:
      return 'AI risk flags';
    case AppPage.listingModeration:
      return 'Listing moderation';
    case AppPage.disputes:
      return 'Disputes & cancellations';
    case AppPage.auditTrail:
      return 'Audit trail';
    case AppPage.userSettings:
      return 'Profile & settings';
    case AppPage.dataPrivacy:
      return 'Data & privacy';
    case AppPage.notifications:
      return 'Notifications';
    case AppPage.aiSupport:
      return 'Pet care assistant';
    case AppPage.triageAlert:
      return 'Urgent care guidance';
    case AppPage.chat:
      return 'Chat';
  }
}

bool _isOnboarding(AppPage page) => const <AppPage>{
      AppPage.splash,
      AppPage.welcome,
      AppPage.authentication,
      AppPage.registration,
      AppPage.otp,
      AppPage.roleSelection,
      AppPage.petSetup,
      AppPage.addPet,
    }.contains(page);

bool _isAdmin(AppPage page) => const <AppPage>{
      AppPage.adminDashboard,
      AppPage.kycQueue,
      AppPage.identityApproval,
      AppPage.riskQueue,
      AppPage.listingModeration,
      AppPage.disputes,
      AppPage.auditTrail,
    }.contains(page);

bool _isVendor(AppPage page) => const <AppPage>{
      AppPage.vendorDashboard,
      AppPage.vendorProducts,
      AppPage.addEditProduct,
      AppPage.vendorOrders,
      AppPage.vendorOrderDetail,
    }.contains(page);

class PetVaultApp extends StatelessWidget {
  const PetVaultApp({super.key});

  static final PetVaultStore store = PetVaultStore(seedDemoData: false);
  static PetVaultApi api = PetVaultApi();
  static String selectedPetId = '';
  static String selectedListingId = '';
  static String selectedProductId = '';
  static String selectedKycUserId = '';
  static String selectedOrderId = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThePetsVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _cream,
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          primary: _teal,
          surface: _cream,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _cream,
          foregroundColor: _ink,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: _ink, fontSize: 14),
          bodySmall: TextStyle(color: _muted, fontSize: 12),
          titleLarge: TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const VaultPageView(page: AppPage.welcome),
    );
  }
}

class VaultPageView extends StatefulWidget {
  const VaultPageView({required this.page, super.key});

  final AppPage page;

  @override
  State<VaultPageView> createState() => _VaultPageViewState();
}

class _VaultPageViewState extends State<VaultPageView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _microchipController = TextEditingController();
  final _kycReferenceController = TextEditingController();
  final _shareRecipientController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _petNameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _sexController = TextEditingController();
  final _weightController = TextEditingController();
  final _recordTitleController = TextEditingController();
  final _recordTypeController = TextEditingController();
  final _providerController = TextEditingController();
  final _givenDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _listingTitleController = TextEditingController();
  final _listingSpeciesController = TextEditingController();
  final _listingBreedController = TextEditingController();
  final _cityController = TextEditingController();
  final _filterCityController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _priceController = TextEditingController();
  final _ageListingController = TextEditingController();
  final _listingNotesController = TextEditingController();
  final _listingImageController = TextEditingController();
  final _vaccinationHistoryController = TextEditingController();
  final _reportReasonController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productStockController = TextEditingController();
  final _productImageController = TextEditingController();
  final _queryController = TextEditingController();
  final _bookingInstructionsController = TextEditingController();
  final _visitMessageController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _sittingUpdateController = TextEditingController();
  final _reviewController = TextEditingController();
  final _vetNotesController = TextEditingController();
  final _supportController = TextEditingController();
  final _messageController = TextEditingController();
  final _triageController = TextEditingController();

  PetVaultStore get _store => PetVaultApp.store;
  PetVaultApi get _api => PetVaultApp.api;

  String _category = 'All';
  String _speciesFilter = '';
  bool _verifiedOnly = false;
  String _selectedRole = 'seller';
  String _selectedReportReason = 'Misleading health information';
  String _selectedPetId = PetVaultApp.selectedPetId;
  String _selectedVet = '';
  String _selectedSitter = '';
  String _selectedSitterId = '';
  String _selectedVetId = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  bool _listingConfirmed = false;
  bool _authSubmitting = false;
  bool _otpSubmitting = false;
  bool _checkoutSubmitting = false;
  bool _visitSubmitting = false;
  bool _requireShareConsent = true;
  bool _allowSitterFullRecords = false;
  bool _supportServiceAvailable = true;
  PlatformFile? _healthDocument;
  int? _healthDocumentSizeBytes;
  Uint8List? _healthDocumentBytes;
  String? _supportResponse;
  String? _triageResponse;
  List<Map<String, dynamic>> _remoteModerationListings =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteSitters = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteVets = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteVetAvailability = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteBookings = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteAppointments = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteKyc = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteNotifications = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteVisitRequests = <Map<String, dynamic>>[];
  bool _remoteModerationLoaded = false;
  int get _cartCount =>
      _store.cart.values.fold<int>(0, (sum, quantity) => sum + quantity);
  final Map<String, bool> _notificationSettings = <String, bool>{
    'Care reminders': true,
    'Messages': true,
    'Marketplace updates': true,
    'Pet essentials': false,
  };

  @override
  void initState() {
    super.initState();
    _requireShareConsent = _store.requireExplicitConsent;
    _allowSitterFullRecords = _store.allowSitterFullRecords;
    if (widget.page == AppPage.otp) {
      _otpController.text = _api.developmentVerificationCode ?? '';
    }
    final pet = _store.pets[_selectedPetId];
    if (widget.page == AppPage.addPet) {
      _petNameController.clear();
      _speciesController.clear();
      _breedController.clear();
      _ageController.clear();
      _sexController.clear();
      _weightController.clear();
      _microchipController.clear();
    } else if (pet != null) {
      _petNameController.text = pet.name;
      _speciesController.text = pet.species;
      _breedController.text = pet.breed;
      _ageController.text = pet.age;
      _sexController.text = pet.sex;
      _weightController.text = pet.weightKg.toString();
      _microchipController.text = pet.microchip;
    }
    if (widget.page == AppPage.marketplace ||
        (widget.page == AppPage.myListings &&
            _api.isAuthenticated &&
            _api.activeRole == 'seller')) {
      _loadRemoteListings();
    }
    if (widget.page == AppPage.shop) {
      _loadRemoteProducts();
    }
    if (_api.isAuthenticated &&
        (widget.page == AppPage.vendorDashboard ||
            widget.page == AppPage.vendorProducts ||
            widget.page == AppPage.vendorOrders ||
            widget.page == AppPage.vendorOrderDetail)) {
      _loadRemoteVendorData();
    }
    if (widget.page == AppPage.sitters) _loadRemoteProviders('sitter');
    if (widget.page == AppPage.vetDirectory) {
      _loadRemoteProviders('veterinarian');
    }
    if (_api.isAuthenticated && widget.page == AppPage.vetAvailability) {
      _loadRemoteVetAvailability();
    }
    if (_api.isAuthenticated && widget.page == AppPage.bookingCalendar) {
      _loadRemoteBookings();
    }
    if (_api.isAuthenticated && widget.page == AppPage.teleConsultation) {
      _loadRemoteAppointments();
    }
    if (_api.isAuthenticated && widget.page == AppPage.kycQueue) {
      _loadRemoteKycQueue();
    }
    if (_api.isAuthenticated && widget.page == AppPage.adminDashboard) {
      _loadRemoteKycQueue();
      _loadRemoteListings();
    }
    if (_api.isAuthenticated && widget.page == AppPage.kycVerification) {
      _loadRemoteMyKyc();
    }
    if (_api.isAuthenticated && widget.page == AppPage.notifications) {
      _loadRemoteNotifications();
    }
    if (widget.page == AppPage.healthRecords && _api.isAuthenticated) {
      _loadRemoteHealthRecords(_selectedPetId);
    }
    if (_api.isAuthenticated && widget.page == AppPage.orderTracking) {
      _loadRemoteOrders();
    }
    if (_api.isAuthenticated && widget.page == AppPage.petVisitRequests) {
      _loadRemoteVisitRequests();
    }
    if (_api.isAuthenticated &&
        (_isAdmin(widget.page) || widget.page == AppPage.riskQueue)) {
      _loadRemoteModerationListings();
    }
    if (widget.page == AppPage.editListing) {
      final listing = _store.listings[PetVaultApp.selectedListingId];
      if (listing != null && listing.sellerId == _store.currentUserId) {
        _listingTitleController.text = listing.title;
        _cityController.text = listing.city;
        _priceController.text = listing.price.toStringAsFixed(0);
        _listingNotesController.text = listing.healthNotes;
      }
    }
    if (widget.page == AppPage.addEditProduct) {
      final product = _store.products[PetVaultApp.selectedProductId];
      if (product != null && product.vendorId == _store.currentUserId) {
        _productNameController.text = product.name;
        _productPriceController.text = product.price.toString();
        _productStockController.text = product.stock.toString();
        _productImageController.text = product.image;
      } else {
        PetVaultApp.selectedProductId = '';
        _productNameController.clear();
        _productPriceController.clear();
        _productStockController.clear();
        _productImageController.clear();
      }
    }
  }

  Future<void> _loadSignedInData() async {
    await Future.wait(<Future<void>>[
      _loadRemotePets(),
      _loadRemoteListings(),
      _loadRemoteProducts(),
      _loadRemoteOrders(),
    ]);
  }

  Future<void> _loadRemoteProviders(String role) async {
    try {
      final providers = await _api.fetchProviders(role);
      if (!mounted) return;
      setState(() {
        if (role == 'sitter') {
          _remoteSitters = providers;
        } else {
          _remoteVets = providers;
        }
      });
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteVetAvailability() async {
    try {
      final slots = await _api.fetchVetAvailability();
      if (mounted) setState(() => _remoteVetAvailability = slots);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteBookings() async {
    try {
      final bookings = await _api.fetchBookings();
      if (mounted) setState(() => _remoteBookings = bookings);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteAppointments() async {
    try {
      final appointments = await _api.fetchAppointments();
      if (mounted) setState(() => _remoteAppointments = appointments);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteKycQueue() async {
    try {
      final submissions = await _api.fetchKycQueue();
      if (mounted) setState(() => _remoteKyc = submissions);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteNotifications() async {
    try {
      final notifications = await _api.fetchNotifications();
      if (mounted) setState(() => _remoteNotifications = notifications);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteVisitRequests() async {
    try {
      final requests = await _api.fetchVisitRequests();
      if (mounted) setState(() => _remoteVisitRequests = requests);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _updateVisitRequestStatus(
    String id,
    String status,
  ) async {
    try {
      await _api.updateVisitRequestStatus(
        visitRequestId: id,
        status: status,
      );
      await _loadRemoteVisitRequests();
      if (mounted) _toast('Visit request ${status.toLowerCase()}.');
    } on PetVaultApiException catch (error) {
      _showApiError(error);
    } on FormatException catch (error) {
      _showApiError(error);
    }
  }

  Future<void> _markRemoteNotificationRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      await _loadRemoteNotifications();
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemotePets() async {
    try {
      final remotePets = await _api.fetchPets();
      if (!mounted) return;
      _store.replaceRemotePets(remotePets);
      if (!_store.pets.containsKey(PetVaultApp.selectedPetId) &&
          remotePets.isNotEmpty &&
          remotePets.first['id'] is String) {
        PetVaultApp.selectedPetId = remotePets.first['id'] as String;
      }
      for (final pet in remotePets) {
        final petId = pet['id'];
        if (petId is! String) continue;
        final records = await _api.fetchHealthRecords(petId);
        if (!mounted) return;
        _store.replaceRemoteHealthRecords(petId, records);
      }
    } on PetVaultApiException catch (error) {
      if (mounted) _toast(error.message);
    } on FormatException catch (error) {
      if (mounted) _toast('Invalid backend data: ${error.message}');
    }
  }

  Future<void> _loadRemoteHealthRecords(String petId) async {
    try {
      final records = await _api.fetchHealthRecords(petId);
      if (mounted) _store.replaceRemoteHealthRecords(petId, records);
    } on PetVaultApiException catch (error) {
      if (mounted) _toast(error.message);
    }
  }

  Future<void> _loadRemoteListings() async {
    try {
      final listings = await _api.fetchListings();
      if (_api.isAuthenticated && _api.activeRole == 'seller') {
        final mine = await _api.fetchMyListings();
        final byId = <String, Map<String, dynamic>>{
          for (final listing in listings)
            if (listing['id'] is String) listing['id'] as String: listing,
          for (final listing in mine)
            if (listing['id'] is String) listing['id'] as String: listing,
        };
        listings
          ..clear()
          ..addAll(byId.values);
      }
      if (mounted) _store.replaceRemoteListings(listings);
      if (_api.isAuthenticated && _api.activeRole == 'owner') {
        final favorites = await _api.fetchFavorites();
        if (mounted) _store.replaceRemoteFavorites(favorites);
      }
    } on PetVaultApiException catch (error) {
      if (mounted) _toast(error.message);
    } on FormatException catch (error) {
      if (mounted) _toast('Invalid backend data: ${error.message}');
    }
  }

  Future<void> _loadRemoteModerationListings() async {
    try {
      final listings = await _api.fetchAdminListingsForModeration();
      if (!mounted) return;
      setState(() {
        _remoteModerationListings = listings;
        _remoteModerationLoaded = true;
      });
    } on PetVaultApiException catch (error) {
      if (!mounted) return;
      setState(() => _remoteModerationLoaded = true);
      _showApiError(error);
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _remoteModerationLoaded = true);
      _showApiError(error);
    }
  }

  Future<void> _loadRemoteProducts() async {
    try {
      final products = await _api.fetchProducts();
      if (mounted) _store.replaceRemoteProducts(products);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteVendorData() async {
    try {
      final products = await _api.fetchMyProducts();
      if (!mounted) return;
      _store.replaceRemoteProducts(products);
      final orders = await _api.fetchOrders();
      if (!mounted) return;
      _store.replaceRemoteOrders(orders);
      setState(() {});
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteMyKyc() async {
    try {
      final submissions = await _api.fetchKycSubmissions();
      if (mounted) setState(() => _remoteKyc = submissions);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _loadRemoteOrders() async {
    try {
      final orders = await _api.fetchOrders();
      if (mounted) _store.replaceRemoteOrders(orders);
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _updateRemoteOrderStatus(String orderId, String status) async {
    try {
      await _api.updateOrderStatus(orderId, status);
      await _loadRemoteVendorData();
      if (mounted) _toast('Order status updated.');
    } on PetVaultApiException catch (error) {
      if (mounted) _showApiError(error);
    } on FormatException catch (error) {
      if (mounted) _showApiError(error);
    }
  }

  Future<void> _moderateRemoteListing(
      Map<String, dynamic> listing, String status) async {
    final id = listing['id'];
    if (id is! String) {
      _toast('The moderation item has an invalid listing ID.');
      return;
    }
    try {
      await _api.moderateListing(id: id, status: status);
      await _loadRemoteModerationListings();
      if (mounted) {
        _toast(status == 'active'
            ? 'Listing approved and published.'
            : 'Listing rejected and the seller was notified.');
      }
    } on PetVaultApiException catch (error) {
      _showApiError(error);
    } on FormatException catch (error) {
      _showApiError(error);
    }
  }

  Future<void> _toggleRemoteFavorite(PetListing listing) async {
    final favorite = !listing.favorites.contains(_store.currentUserId);
    try {
      await _api.setFavorite(listing.id, favorite);
      final favorites = await _api.fetchFavorites();
      if (mounted) _store.replaceRemoteFavorites(favorites);
    } on PetVaultApiException catch (error) {
      _showApiError(error);
    } on FormatException catch (error) {
      _showApiError(error);
    }
  }

  void _showApiError(Object error) {
    _toast(error is PetVaultApiException
        ? error.message
        : 'The backend request failed. Please try again.');
  }

  Map<String, dynamic> _remotePetJson(PetProfile pet) => <String, dynamic>{
        'id': pet.id,
        'ownerId': pet.ownerId,
        'name': pet.name,
        'species': pet.species,
        'breed': pet.breed,
        'age': pet.age,
        'sex': pet.sex,
        'weightKg': pet.weightKg,
        'microchip': pet.microchip,
      };

  Future<void> _savePetProfile() async {
    if (_api.isAuthenticated) {
      try {
        final created = await _api.createPet(
          name: _petNameController.text,
          species: _speciesController.text,
          breed: _breedController.text,
          age: _ageController.text,
          sex: _sexController.text,
          weightKg: double.tryParse(_weightController.text.trim()) ?? 0,
          microchip: _microchipController.text,
        );
        if (!mounted) return;
        final existing = _store.ownerPets
            .where((pet) => pet.id != created['id'])
            .map(_remotePetJson);
        _store.replaceRemotePets(<Map<String, dynamic>>[
          ...existing,
          created,
        ]);
        PetVaultApp.selectedPetId = created['id'] as String;
        _switchTab(AppPage.pets);
      } on PetVaultApiException catch (error) {
        _showApiError(error);
      } on FormatException catch (error) {
        _showApiError(error);
      }
      return;
    }

    final saved = _store.addPet(
      name: _petNameController.text,
      species: _speciesController.text,
      breed: _breedController.text,
      age: _ageController.text,
      sex: _sexController.text,
      weight: _weightController.text,
      microchip: _microchipController.text,
    );
    if (saved) {
      PetVaultApp.selectedPetId = _store.ownerPets.last.id;
      _switchTab(AppPage.pets);
    } else {
      _toast(_store.lastError ?? 'Pet profile could not be saved.');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _microchipController.dispose();
    _kycReferenceController.dispose();
    _shareRecipientController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _petNameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _sexController.dispose();
    _weightController.dispose();
    _recordTitleController.dispose();
    _recordTypeController.dispose();
    _providerController.dispose();
    _givenDateController.dispose();
    _dueDateController.dispose();
    _listingTitleController.dispose();
    _listingSpeciesController.dispose();
    _listingBreedController.dispose();
    _cityController.dispose();
    _filterCityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _priceController.dispose();
    _ageListingController.dispose();
    _listingNotesController.dispose();
    _listingImageController.dispose();
    _vaccinationHistoryController.dispose();
    _reportReasonController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productStockController.dispose();
    _productImageController.dispose();
    _queryController.dispose();
    _bookingInstructionsController.dispose();
    _visitMessageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _sittingUpdateController.dispose();
    _reviewController.dispose();
    _vetNotesController.dispose();
    _supportController.dispose();
    _messageController.dispose();
    _triageController.dispose();
    super.dispose();
  }

  void _open(AppPage next) {
    if (_requiresAuthentication(next) && !_api.isAuthenticated) {
      _toast('Sign in to access your account data.');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const VaultPageView(page: AppPage.authentication),
        ),
      );
      return;
    }
    final requiredRole = _requiredRole(next);
    if (requiredRole != null &&
        !_store.authorize(requiredRole, _titleFor(next))) {
      _toast(_store.lastError ?? 'Access denied.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VaultPageView(page: next),
      ),
    );
  }

  String _navigationLabel(AppPage page) =>
      _titleFor(page).replaceFirst(RegExp(r'^\d+\s+'), '');

  Widget _imageUnavailable(double height, double? width) {
    return Container(
      width: width,
      height: height,
      color: _paleTeal,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: _muted),
    );
  }

  PetVaultRole? _requiredRole(AppPage page) {
    if (_isAdmin(page)) return PetVaultRole.admin;
    if (_isVendor(page)) return PetVaultRole.vendor;
    if (page == AppPage.listingPerformance ||
        page == AppPage.editListing ||
        page == AppPage.myListings ||
        page == AppPage.createListing ||
        page == AppPage.createListingDetails) {
      return PetVaultRole.seller;
    }
    return null;
  }

  void _switchTab(AppPage page) {
    if (_requiresAuthentication(page) && !_api.isAuthenticated) {
      _toast('Sign in to access your account data.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const VaultPageView(page: AppPage.authentication),
        ),
        (route) => false,
      );
      return;
    }
    final requiredRole = _requiredRole(page);
    if (requiredRole != null &&
        !_store.authorize(requiredRole, _titleFor(page))) {
      _toast(_store.lastError ?? 'Access denied.');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => VaultPageView(page: page),
      ),
      (route) => false,
    );
  }

  bool _requiresAuthentication(AppPage page) => !const <AppPage>{
        AppPage.splash,
        AppPage.welcome,
        AppPage.authentication,
        AppPage.registration,
        AppPage.otp,
        AppPage.marketplace,
        AppPage.listingDetail,
        AppPage.shop,
        AppPage.productDetail,
        AppPage.checkout,
        AppPage.petVisitRequests,
        AppPage.userSettings,
        AppPage.dataPrivacy,
        AppPage.notifications,
      }.contains(page);

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
        ),
      );
  }

  void _showStoreResult(bool success, {String? successMessage}) {
    _toast(success
        ? (successMessage ?? 'Saved successfully.')
        : (_store.lastError ?? 'The request could not be completed.'));
  }

  void _openDirectory() {
    var query = '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final normalizedQuery = query.trim().toLowerCase();
          final groups = _catalogGroups.entries
              .map((group) {
                final pages = group.value.where((page) {
                  if (_isOnboarding(page) || page == AppPage.splash) {
                    return false;
                  }
                  if (_requiredRole(page) case final role?) {
                    if (_store.activeRole != role || !_store.hasRole(role)) {
                      return false;
                    }
                  }
                  return normalizedQuery.isEmpty ||
                      _titleFor(page).toLowerCase().contains(normalizedQuery) ||
                      group.key.toLowerCase().contains(normalizedQuery);
                }).toList(growable: false);
                return MapEntry(group.key, pages);
              })
              .where((group) => group.value.isNotEmpty)
              .toList(growable: false);

          return SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .82,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _line,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Page navigator',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close page navigator',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Find a PetVault screen by name or category.',
                        style: TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        autofocus: true,
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Search pages',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () =>
                                      setSheetState(() => query = ''),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _line),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: groups.isEmpty
                      ? const Center(
                          child: Text(
                            'No pages match your search.',
                            style: TextStyle(color: _muted),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: <Widget>[
                            for (final group in groups)
                              ExpansionTile(
                                key: ValueKey(
                                  '${group.key}:$normalizedQuery',
                                ),
                                initiallyExpanded: normalizedQuery.isNotEmpty,
                                tilePadding: EdgeInsets.zero,
                                childrenPadding:
                                    const EdgeInsets.only(left: 8, bottom: 8),
                                title: Text(
                                  group.key,
                                  style: const TextStyle(
                                    color: _teal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                children: group.value
                                    .map(
                                      (page) => ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        selected: page == widget.page,
                                        selectedTileColor: _paleTeal,
                                        leading: Icon(
                                          _iconForPage(page),
                                          size: 19,
                                          color: page == widget.page
                                              ? _teal
                                              : _muted,
                                        ),
                                        title: Text(_navigationLabel(page)),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 13,
                                          color: _muted,
                                        ),
                                        onTap: () {
                                          Navigator.pop(sheetContext);
                                          _open(page);
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget? _appBar() {
    if (_isOnboarding(widget.page)) return null;
    final isMainTab = _tabs().contains(widget.page);
    return AppBar(
      leading: isMainTab
          ? Builder(
              builder: (context) => IconButton(
                tooltip: 'Open navigation menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              onPressed: () => Navigator.maybePop(context),
            ),
      title: Text(
        _titleFor(widget.page),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: <Widget>[
        if (!isMainTab)
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Open navigation menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
        IconButton(
          tooltip: 'Open page navigator',
          onPressed: _openDirectory,
          icon: const Icon(Icons.grid_view_rounded),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _line),
      ),
    );
  }

  Widget? _navigationDrawer() {
    if (_isOnboarding(widget.page)) return null;
    return Drawer(
      backgroundColor: _cream,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _paleTeal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.pets_rounded, color: _teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'ThePetsVault',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _api.isAuthenticated
                              ? _store.currentUserName
                              : 'Explore PetVault',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close navigation menu',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Text(
                      'MAIN MENU',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  for (final page in _tabs())
                    _drawerItem(page, _iconForPage(page)),
                  if (_api.isAuthenticated) ...<Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 22, 12, 8),
                      child: Text(
                        'YOUR ACCOUNT',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _drawerItem(
                      AppPage.notifications,
                      Icons.notifications_none_rounded,
                    ),
                    _drawerItem(AppPage.userSettings, Icons.settings_outlined),
                    _drawerItem(
                      AppPage.dataPrivacy,
                      Icons.shield_outlined,
                    ),
                  ],
                  for (final group in _catalogGroups.entries) ...<Widget>[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        group.key.toUpperCase(),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    for (final page in group.value)
                      if (!_isOnboarding(page) &&
                          page != AppPage.splash &&
                          !_tabs().contains(page) &&
                          page != AppPage.notifications &&
                          page != AppPage.userSettings &&
                          page != AppPage.dataPrivacy &&
                          _isPageAvailable(page))
                        _drawerItem(page, _iconForPage(page)),
                  ],
                ],
              ),
            ),
            if (_api.isAuthenticated)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _api.signOut();
                      _store.signOut();
                      _switchTab(AppPage.welcome);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isPageAvailable(AppPage page) {
    final requiredRole = _requiredRole(page);
    return requiredRole == null ||
        (_store.activeRole == requiredRole && _store.hasRole(requiredRole));
  }

  Widget _drawerItem(AppPage page, IconData icon) {
    final selected = widget.page == page;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      selected: selected,
      selectedColor: _teal,
      selectedTileColor: _paleTeal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, size: 20),
      title: Text(
        _navigationLabel(page),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.pop(context);
        if (_tabs().contains(page)) {
          _switchTab(page);
        } else {
          _open(page);
        }
      },
    );
  }

  IconData _iconForPage(AppPage page) {
    return switch (page) {
      AppPage.home ||
      AppPage.adminDashboard ||
      AppPage.vendorDashboard =>
        Icons.home_outlined,
      AppPage.pets ||
      AppPage.petProfile ||
      AppPage.addPet =>
        Icons.pets_outlined,
      AppPage.marketplace || AppPage.createListing => Icons.storefront_outlined,
      AppPage.sitters || AppPage.bookingCalendar => Icons.home_work_outlined,
      AppPage.chat ||
      AppPage.buyerSellerMessaging =>
        Icons.chat_bubble_outline_rounded,
      AppPage.shop ||
      AppPage.productDetail ||
      AppPage.vendorProducts =>
        Icons.shopping_bag_outlined,
      AppPage.notifications => Icons.notifications_none_rounded,
      AppPage.userSettings => Icons.settings_outlined,
      AppPage.dataPrivacy => Icons.shield_outlined,
      AppPage.healthRecords ||
      AppPage.addHealthRecord ||
      AppPage.vaccinationSchedule =>
        Icons.favorite_border_rounded,
      AppPage.vetDirectory ||
      AppPage.vetAvailability ||
      AppPage.teleConsultation =>
        Icons.medical_services_outlined,
      AppPage.kycQueue ||
      AppPage.identityApproval =>
        Icons.verified_user_outlined,
      AppPage.riskQueue ||
      AppPage.listingModeration ||
      AppPage.disputes =>
        Icons.warning_amber_rounded,
      AppPage.auditTrail ||
      AppPage.listingPerformance =>
        Icons.analytics_outlined,
      AppPage.favorites => Icons.favorite_border_rounded,
      _ => Icons.arrow_forward_rounded,
    };
  }

  List<AppPage> _tabs() {
    if (_isAdmin(widget.page)) return _adminTabs;
    if (_isVendor(widget.page)) return _vendorTabs;
    return _ownerTabs;
  }

  int _selectedTab(List<AppPage> tabs) {
    if (tabs.contains(widget.page)) return tabs.indexOf(widget.page);
    if (_isAdmin(widget.page)) return 0;
    if (_isVendor(widget.page)) return 0;
    if (widget.page == AppPage.petProfile ||
        widget.page == AppPage.editPet ||
        widget.page == AppPage.healthRecords ||
        widget.page == AppPage.addHealthRecord ||
        widget.page == AppPage.vaccinationSchedule ||
        widget.page == AppPage.weightHistory) {
      return 1;
    }
    if (widget.page == AppPage.productDetail ||
        widget.page == AppPage.checkout ||
        widget.page == AppPage.orderTracking ||
        widget.page == AppPage.searchFilters ||
        widget.page == AppPage.listingDetail ||
        widget.page == AppPage.createListing ||
        widget.page == AppPage.createListingDetails ||
        widget.page == AppPage.myListings ||
        widget.page == AppPage.editListing ||
        widget.page == AppPage.listingPerformance ||
        widget.page == AppPage.scheduleVisit) {
      return 2;
    }
    if (widget.page == AppPage.buyerSellerMessaging ||
        widget.page == AppPage.reportListing) {
      return 4;
    }
    return 0;
  }

  Widget? _bottomBar() {
    if (_isOnboarding(widget.page)) return null;

    final tabs = _tabs();
    final selected = _selectedTab(tabs);
    final labels = _isAdmin(widget.page)
        ? const <String>['Overview', 'KYC', 'Risk', 'Audit']
        : _isVendor(widget.page)
            ? const <String>['Overview', 'Products', 'Orders', 'Store']
            : const <String>['Home', 'Pets', 'Market', 'Sitters', 'Chat'];
    final icons = _isAdmin(widget.page)
        ? const <IconData>[
            Icons.dashboard_outlined,
            Icons.verified_user_outlined,
            Icons.warning_amber_rounded,
            Icons.history_rounded,
          ]
        : _isVendor(widget.page)
            ? const <IconData>[
                Icons.dashboard_outlined,
                Icons.inventory_2_outlined,
                Icons.receipt_long_outlined,
                Icons.storefront_outlined,
              ]
            : const <IconData>[
                Icons.home_outlined,
                Icons.pets_outlined,
                Icons.shopping_cart_outlined,
                Icons.home_work_outlined,
                Icons.chat_bubble_outline_rounded,
              ];

    return Container(
      decoration: const BoxDecoration(
        color: _cream,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List<Widget>.generate(tabs.length, (index) {
              final active = index == selected;
              return Expanded(
                child: InkWell(
                  onTap: () => _switchTab(tabs[index]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        icons[index],
                        size: 21,
                        color: active ? _teal : _muted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? _teal : _muted,
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (active)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 15,
                          height: 2,
                          decoration: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _screenBody() {
    switch (widget.page) {
      case AppPage.splash:
        return _splash();
      case AppPage.welcome:
        return _welcome();
      case AppPage.authentication:
        return _authentication();
      case AppPage.registration:
        return _registration();
      case AppPage.otp:
        return _otp();
      case AppPage.roleSelection:
        return _roleSelection();
      case AppPage.petSetup:
        return _petSetup();
      case AppPage.addPet:
        return _addPet();
      case AppPage.kycVerification:
        return _kycVerification();
      case AppPage.home:
        return _home();
      case AppPage.pets:
        return _pets();
      case AppPage.petProfile:
        return _petProfile();
      case AppPage.editPet:
        return _editPet();
      case AppPage.healthRecords:
        return _healthRecords();
      case AppPage.addHealthRecord:
        return _addHealthRecord();
      case AppPage.vaccinationSchedule:
        return _vaccinations();
      case AppPage.weightHistory:
        return _weightHistory();
      case AppPage.favorites:
        return _favorites();
      case AppPage.vetDirectory:
        return _vetDirectory();
      case AppPage.vetAvailability:
        return _vetAvailability();
      case AppPage.teleConsultation:
        return _teleConsultation();
      case AppPage.marketplace:
        return _marketplace();
      case AppPage.searchFilters:
        return _filters();
      case AppPage.listingDetail:
        return _listingDetail();
      case AppPage.createListing:
        return _createListing();
      case AppPage.createListingDetails:
        return _createListingDetails();
      case AppPage.buyerSellerMessaging:
      case AppPage.chat:
        return _chat();
      case AppPage.reportListing:
        return _reportListing();
      case AppPage.myListings:
        return _myListings();
      case AppPage.editListing:
        return _editListing();
      case AppPage.listingPerformance:
        return _listingPerformance();
      case AppPage.scheduleVisit:
        return _scheduleVisit();
      case AppPage.petVisitRequests:
        return _petVisitRequests();
      case AppPage.shop:
        return _shop();
      case AppPage.productDetail:
        return _productDetail();
      case AppPage.checkout:
        return _checkout();
      case AppPage.orderTracking:
        return _orderTracking();
      case AppPage.vendorDashboard:
        return _vendorDashboard();
      case AppPage.vendorProducts:
        return _vendorProducts();
      case AppPage.addEditProduct:
        return _addEditProduct();
      case AppPage.vendorOrders:
        return _vendorOrders();
      case AppPage.vendorOrderDetail:
        return _vendorOrderDetail();
      case AppPage.sitters:
        return _sitters();
      case AppPage.bookingCalendar:
        return _bookingCalendar();
      case AppPage.activeSitting:
        return _activeSitting();
      case AppPage.adminDashboard:
        return _adminDashboard();
      case AppPage.kycQueue:
        return _kycQueue();
      case AppPage.identityApproval:
        return _identityApproval();
      case AppPage.riskQueue:
        return _riskQueue();
      case AppPage.listingModeration:
        return _listingModeration();
      case AppPage.disputes:
        return _disputes();
      case AppPage.auditTrail:
        return _auditTrail();
      case AppPage.userSettings:
        return _userSettings();
      case AppPage.dataPrivacy:
        return _dataPrivacy();
      case AppPage.notifications:
        return _notifications();
      case AppPage.aiSupport:
        return _aiSupport();
      case AppPage.triageAlert:
        return _triageAlert();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => Scaffold(
        backgroundColor: _cream,
        appBar: _appBar(),
        drawer: _navigationDrawer(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isAuthPage = const <AppPage>{
                AppPage.welcome,
                AppPage.authentication,
                AppPage.registration,
                AppPage.otp,
              }.contains(widget.page);
              final maxWidth = isAuthPage ? 560.0 : 1120.0;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth > maxWidth
                      ? maxWidth
                      : constraints.maxWidth,
                  child: _screenBody(),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

  Widget _scroll(List<Widget> children,
      {EdgeInsets padding = const EdgeInsets.all(16)}) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _title(String text, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          text,
          style: const TextStyle(
            color: _ink,
            fontSize: 23,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _section(String text, {String? action, VoidCallback? onAction}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _teal,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(action),
          ),
      ],
    );
  }

  Widget _card(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(14),
    Color color = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _pill(String label,
      {Color color = _paleTeal, Color textColor = _teal}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _button(
    String label,
    VoidCallback? onPressed, {
    bool primary = true,
    IconData? icon,
    bool isLoading = false,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading)
          const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else if (icon != null) ...<Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: primary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: child,
            ),
    );
  }

  Widget _field(
    String label, {
    String? hint,
    TextInputType? keyboardType,
    TextEditingController? controller,
    bool obscureText = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: const TextStyle(color: _muted, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _line),
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _teal, width: 1.4),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photo(
    String asset, {
    double height = 125,
    double? width,
    double radius = 15,
  }) {
    final uri = Uri.tryParse(asset);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          asset,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageUnavailable(height, width),
        ),
      );
    }
    if (asset.isEmpty) return _imageUnavailable(height, width);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _petCard(String name, String meta, String asset,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _open(AppPage.petProfile),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _photo(asset, height: 118, width: 94, radius: 12),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            const Text(
              'Health records',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _splash() {
    return _scroll(
      <Widget>[
        const SizedBox(height: 120),
        Center(child: Image.asset('assets/images/brand.png', width: 230)),
        const SizedBox(height: 180),
        const Center(
          child: Text(
            'TRUSTED PET ECOSYSTEM',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 40),
        _button('Get started', () => _open(AppPage.welcome)),
        const SizedBox(height: 12),
        _button(
          'Open the app',
          () => _switchTab(AppPage.home),
          primary: false,
        ),
      ],
    );
  }

  Widget _welcome() {
    return _scroll(
      <Widget>[
        const SizedBox(height: 20),
        Center(child: Image.asset('assets/images/brand.png', width: 112)),
        const SizedBox(height: 22),
        _photo('assets/images/welcome_pet.png',
            height: 245, width: double.infinity),
        const SizedBox(height: 24),
        _title(
          'Care for every part of their life.',
          subtitle:
              'Health records, trusted care, and a safer pet marketplace in one place.',
        ),
        const SizedBox(height: 18),
        _card(
          const Row(
            children: <Widget>[
              Icon(Icons.verified_user_outlined, color: _teal),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verified people. Owner-controlled records. Care that travels with your pet.',
                  style: TextStyle(color: _ink, height: 1.35),
                ),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 20),
        _button('Continue', () => _open(AppPage.authentication)),
        const SizedBox(height: 10),
        _button(
          'Browse pets and products',
          () => _open(AppPage.marketplace),
          primary: false,
        ),
      ],
    );
  }

  Widget _authentication() {
    return _scroll(
      <Widget>[
        const SizedBox(height: 38),
        Center(child: Image.asset('assets/images/brand.png', width: 146)),
        const SizedBox(height: 36),
        _title('Welcome back',
            subtitle: 'Sign in to your trusted pet ecosystem.'),
        const SizedBox(height: 24),
        _field('Email address',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field('Password',
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: true),
        const SizedBox(height: 14),
        _button(_authSubmitting ? 'Signing in...' : 'Sign in', () async {
          if (_authSubmitting) return;
          if (_emailController.text.trim().isEmpty ||
              _passwordController.text.isEmpty) {
            _toast('Enter your email address and password.');
            return;
          }
          if (_api.isAuthenticated) {
            _api.signOut();
          }
          setState(() => _authSubmitting = true);
          try {
            final user = await _api.signIn(
                _emailController.text.trim(), _passwordController.text);
            _store.activateRemoteSession(user);
            await _loadSignedInData();
            if (!mounted) return;
            final page = switch (_store.activeRole) {
              PetVaultRole.admin => AppPage.adminDashboard,
              PetVaultRole.vendor => AppPage.vendorDashboard,
              PetVaultRole.veterinarian => AppPage.vetAvailability,
              PetVaultRole.sitter => AppPage.bookingCalendar,
              _ => AppPage.home,
            };
            _switchTab(page);
          } on PetVaultApiException catch (error) {
            _showApiError(error);
          } on FormatException catch (error) {
            _showApiError(error);
          } finally {
            if (mounted) setState(() => _authSubmitting = false);
          }
        }, icon: Icons.lock_open_rounded, isLoading: _authSubmitting),
        const SizedBox(height: 8),
        _button('Create an account', () => _open(AppPage.registration),
            primary: false, icon: Icons.person_add_alt_1_rounded),
        Center(
          child: TextButton(
            onPressed: () async {
              try {
                final response = await _api.requestPasswordReset(
                  _emailController.text,
                );
                if (!mounted) return;
                final code = response['devCode'];
                _toast(code is String
                    ? 'Development reset code: $code.'
                    : (response['message'] as String? ??
                        'If the account exists, a reset code was issued.'));
              } on PetVaultApiException catch (error) {
                _showApiError(error);
              }
            },
            child: const Text('Forgot password?'),
          ),
        ),
      ],
    );
  }

  Widget _registration() {
    return _scroll(
      <Widget>[
        _title('Create your account',
            subtitle: 'A few details to keep your pet community safe.'),
        const SizedBox(height: 20),
        _field('Full name',
            hint: 'e.g. Your name', controller: _nameController),
        const SizedBox(height: 13),
        _field('Email address',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 13),
        _field('Mobile number',
            hint: '+92 300 000 0000',
            keyboardType: TextInputType.phone,
            controller: _phoneController),
        const SizedBox(height: 13),
        _field('Password',
            hint: 'At least 8 characters',
            controller: _passwordController,
            obscureText: true),
        const SizedBox(height: 15),
        _card(
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.verified_user_outlined, color: _teal, size: 19),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'We’ll verify your email with a one-time code. In development, the code may be shown here; configured email delivery sends it to your inbox.',
                  style: TextStyle(color: _muted, height: 1.35),
                ),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 18),
        _button(
          _authSubmitting ? 'Creating account...' : 'Create account',
          () async {
            if (_authSubmitting) return;
            final name = _nameController.text.trim();
            final email = _emailController.text.trim();
            final phone = _phoneController.text.trim();
            final password = _passwordController.text;
            if (name.isEmpty) {
              _toast('Enter your full name.');
              return;
            }
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
              _toast('Enter a valid email address.');
              return;
            }
            if (phone.replaceAll(RegExp(r'\D'), '').length < 7) {
              _toast('Enter a valid mobile number.');
              return;
            }
            if (password.length < 8) {
              _toast('Choose a password with at least 8 characters.');
              return;
            }

            setState(() => _authSubmitting = true);
            try {
              await _api.register(
                displayName: name,
                email: email,
                phone: phone,
                password: password,
              );
              if (!mounted) return;
              _toast('Account created. Verify your email to continue.');
              _open(AppPage.otp);
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            } finally {
              if (mounted) setState(() => _authSubmitting = false);
            }
          },
          isLoading: _authSubmitting,
        ),
      ],
    );
  }

  Widget _otp() {
    final email = _api.pendingEmail;
    final developmentCode = _api.developmentVerificationCode;
    return _scroll(
      <Widget>[
        const SizedBox(height: 20),
        _title(
          'Verify your email',
          subtitle: email == null
              ? 'Enter the 6-digit verification code for your account.'
              : 'Enter the 6-digit verification code for $email.',
        ),
        if (developmentCode != null) ...<Widget>[
          const SizedBox(height: 18),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, color: _teal, size: 19),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Local development verification code',
                        style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  developmentCode,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This code is for local development only.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
            color: _paleTeal,
          ),
        ],
        const SizedBox(height: 22),
        _field('Verification code',
            hint: 'Enter your 6-digit code',
            keyboardType: TextInputType.number,
            controller: _otpController),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            try {
              await _api.resendVerificationCode();
              if (!mounted) return;
              setState(() {
                _otpController.text =
                    _api.developmentVerificationCode ?? _otpController.text;
              });
              _toast('A new verification code was issued.');
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            }
          },
          child: const Text('Resend code'),
        ),
        const SizedBox(height: 14),
        _button(
          _otpSubmitting ? 'Verifying...' : 'Verify & continue',
          () async {
            if (_otpSubmitting) return;
            if (!RegExp(r'^\d{6}$').hasMatch(_otpController.text.trim())) {
              _toast('Enter the 6-digit verification code.');
              return;
            }
            setState(() => _otpSubmitting = true);
            try {
              final user = await _api.verifyAccount(_otpController.text.trim());
              _store.activateRemoteSession(user);
              await _loadSignedInData();
              if (!mounted) return;
              _open(AppPage.roleSelection);
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            } on FormatException catch (error) {
              _showApiError(error);
            } finally {
              if (mounted) setState(() => _otpSubmitting = false);
            }
          },
          isLoading: _otpSubmitting,
        ),
      ],
    );
  }

  Widget _roleSelection() {
    final roles = <(String, String, IconData)>[
      ('Pet parent', 'Manage profiles and care records', Icons.pets_outlined),
      (
        'Breeder / seller',
        'Create a trusted pet listing',
        Icons.storefront_outlined
      ),
      ('Pet sitter', 'Manage bookings and visits', Icons.home_work_outlined),
      (
        'Veterinarian',
        'Consult and update shared records',
        Icons.medical_services_outlined
      ),
      ('Vendor', 'Sell pet essentials', Icons.shopping_bag_outlined),
    ];
    return _scroll(
      <Widget>[
        _title('How will you use PetVault?',
            subtitle: 'You can add more roles to your account later.'),
        const SizedBox(height: 16),
        ...roles.map(
          (role) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async {
                try {
                  if (role.$1 == 'Pet parent') {
                    if (_api.canSelectRole('owner')) {
                      await _api.selectRole('owner');
                    }
                    if (_store.switchRole(PetVaultRole.owner)) {
                      _open(AppPage.petSetup);
                    } else {
                      _toast(_store.lastError ?? 'Owner role is unavailable.');
                    }
                    return;
                  }
                  if (role.$1 == 'Breeder / seller') {
                    final activated = _store.activateSellerRole();
                    if (!activated) {
                      _toast(_store.lastError ?? 'Seller role is unavailable.');
                      return;
                    }
                    if (_api.canSelectRole('seller')) {
                      await _api.selectRole('seller');
                    }
                    _selectedRole = 'seller';
                    _open(AppPage.kycVerification);
                    return;
                  }
                  final selectedRole = role.$1 == 'Vendor'
                      ? PetVaultRole.vendor
                      : role.$1 == 'Pet sitter'
                          ? PetVaultRole.sitter
                          : PetVaultRole.veterinarian;
                  if (!_store.selectInitialSupplyRole(selectedRole)) {
                    _toast(_store.lastError ??
                        'Use a separate account for this role.');
                    return;
                  }
                  if (_api.canSelectRole(selectedRole.name)) {
                    await _api.selectRole(selectedRole.name);
                  }
                  _selectedRole = selectedRole.name;
                  _open(AppPage.kycVerification);
                } on PetVaultApiException catch (error) {
                  _showApiError(error);
                }
              },
              borderRadius: BorderRadius.circular(17),
              child: _card(
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: _paleTeal,
                      foregroundColor: _teal,
                      child: Icon(role.$3),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(role.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(role.$2,
                              style:
                                  const TextStyle(color: _muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _petSetup() {
    return _scroll(
      <Widget>[
        _title('Your pet profiles',
            subtitle: 'Keep the essentials together in one private vault.'),
        const SizedBox(height: 18),
        _card(
          Column(
            children: <Widget>[
              const Icon(Icons.pets_rounded, color: _teal, size: 42),
              const SizedBox(height: 9),
              const Text('Your pet family starts here',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              const Text(
                'Add a profile to organize health records, reminders, and care.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 14),
              _button('Add your first pet', () => _open(AppPage.addPet)),
            ],
          ),
          color: Colors.white,
        ),
        const SizedBox(height: 12),
        _button(
          'Do this later',
          () => _switchTab(AppPage.home),
          primary: false,
        ),
      ],
    );
  }

  Widget _addPet() {
    return _scroll(
      <Widget>[
        _title('Add a pet',
            subtitle: 'Create a profile for their care journey.'),
        const SizedBox(height: 18),
        _field('Pet name', hint: 'e.g. Rosco', controller: _petNameController),
        const SizedBox(height: 13),
        _field('Species',
            hint: 'Dog, cat, rabbit…', controller: _speciesController),
        const SizedBox(height: 13),
        _field('Breed', hint: 'Breed or mix', controller: _breedController),
        const SizedBox(height: 13),
        _field('Age', hint: 'e.g. 2 years', controller: _ageController),
        const SizedBox(height: 13),
        _field('Sex', hint: 'Male or female', controller: _sexController),
        const SizedBox(height: 13),
        _field('Weight in kg',
            hint: 'e.g. 12.5',
            controller: _weightController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 13),
        _field('Microchip number',
            hint: 'Optional', controller: _microchipController),
        const SizedBox(height: 18),
        _button('Save pet profile', _savePetProfile),
      ],
    );
  }

  Widget _kycVerification() {
    final submissions = _remoteKyc
        .where((submission) => submission['role'] == _selectedRole)
        .toList();
    final status = submissions.isEmpty
        ? 'Not submitted'
        : submissions.first['status'] as String? ?? 'Unknown';
    return _scroll(
      <Widget>[
        _title('Verify your identity',
            subtitle: 'Supply-side profiles are published only after review.'),
        const SizedBox(height: 14),
        _card(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('KYC status', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 5),
              Text(
                'This form stores a reference only. Do not enter sensitive identity numbers or upload documents; document storage and identity verification are not configured.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 12),
        _card(Text('Selected role: $_selectedRole')),
        const SizedBox(height: 12),
        _field('Document reference',
            hint: 'Enter a non-sensitive reference',
            controller: _kycReferenceController),
        const SizedBox(height: 13),
        if (!_api.isAuthenticated)
          _button('Sign in to continue', () => _open(AppPage.authentication))
        else
          _button('Submit for review', () async {
            try {
              await _api.submitKyc(
                role: _selectedRole,
                documentReference: _kycReferenceController.text,
              );
              await _loadRemoteMyKyc();
              if (mounted) _toast('KYC submission saved for review.');
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            }
          }),
        if (_api.isAuthenticated) ...<Widget>[
          const SizedBox(height: 10),
          Text('Current status: $status',
              style: const TextStyle(color: _muted)),
        ],
        if (!_api.isAuthenticated) ...<Widget>[
          const SizedBox(height: 8),
          const Text('Sign in to submit a verification request.',
              style: TextStyle(color: _muted)),
        ],
      ],
    );
  }

  Widget _home() {
    final pets = _store.ownerPets;
    final recommendations = _store.recommendations();
    final appointments = _store.visibleAppointments.toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    return _scroll(
      <Widget>[
        Row(
          children: <Widget>[
            const Spacer(),
            Image.asset('assets/images/brand.png', width: 76),
            const Spacer(),
            IconButton(
              tooltip: 'Explore screens',
              onPressed: _openDirectory,
              icon: const Icon(Icons.grid_view_rounded, color: _teal),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Good morning,',
            style: TextStyle(color: _muted, fontSize: 14)),
        const SizedBox(height: 3),
        Text(
          '${_store.currentUserName} 👋',
          style: const TextStyle(
            color: _ink,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        _section('My pets',
            action: 'Profiles →', onAction: () => _open(AppPage.pets)),
        const SizedBox(height: 9),
        SizedBox(
          height: 218,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              if (pets.isEmpty)
                _card(
                  _button('Add your first pet', () => _open(AppPage.addPet)),
                )
              else
                for (final pet in pets) ...<Widget>[
                  _petCard(
                    pet.name,
                    '${pet.species} · ${pet.age}',
                    pet.species.toLowerCase() == 'cat'
                        ? 'assets/images/pet_cat.png'
                        : pet.species.toLowerCase() == 'rabbit'
                            ? 'assets/images/pet_rabbit.png'
                            : 'assets/images/pet_golden.png',
                    onTap: () {
                      PetVaultApp.selectedPetId = pet.id;
                      _open(AppPage.petProfile);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child:
                  _metricCard('My pets', '${pets.length}', 'Active profiles'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                'Vet visits',
                '${appointments.length}',
                appointments.isEmpty ? 'No appointments' : 'Scheduled',
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        _section('Upcoming care',
            action: 'Vaccinations →',
            onAction: () => _open(AppPage.vaccinationSchedule)),
        const SizedBox(height: 8),
        _card(
          Column(
            children: <Widget>[
              if (appointments.isEmpty)
                ListTile(
                  leading:
                      const Icon(Icons.medical_services_outlined, color: _teal),
                  title: const Text('No upcoming vet appointments'),
                  subtitle: const Text('Find a verified veterinarian.'),
                  onTap: () => _open(AppPage.vetDirectory),
                )
              else
                for (final appointment in appointments.take(2))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available, color: _teal),
                    title: Text(
                        '${_store.pets[appointment.petId]?.name ?? 'Pet'} · ${appointment.type}'),
                    subtitle: Text(
                        '${appointment.vet} · ${appointment.slot.toLocal()}'),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _section('Quick access'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _quickLink('Health records', Icons.folder_open_outlined,
                () => _open(AppPage.healthRecords)),
            _quickLink('Marketplace', Icons.storefront_outlined,
                () => _switchTab(AppPage.marketplace)),
            _quickLink('Pet care help', Icons.support_agent_rounded,
                () => _open(AppPage.aiSupport)),
            _quickLink('Vet directory', Icons.medical_services_outlined,
                () => _open(AppPage.vetDirectory)),
          ],
        ),
        if (recommendations.isNotEmpty) ...<Widget>[
          const SizedBox(height: 17),
          _section('Recommended listings',
              action: 'Browse all →',
              onAction: () => _switchTab(AppPage.marketplace)),
          const SizedBox(height: 8),
          for (final listing in recommendations.take(2))
            _card(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    _photo(listing.image, height: 48, width: 48, radius: 8),
                title: Text(listing.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    '${listing.city} · Rs ${listing.price.toStringAsFixed(0)}'),
                onTap: () {
                  PetVaultApp.selectedListingId = listing.id;
                  _open(AppPage.listingDetail);
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _metricCard(String title, String value, String footer) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _pill(title, color: _sand, textColor: _teal),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: _ink)),
          Text(footer, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _quickLink(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, color: _teal, size: 18),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: _line),
      onPressed: onTap,
    );
  }

  Widget _pets() {
    final pets = _store.ownerPets;
    return _scroll(
      <Widget>[
        _title('Your pets',
            subtitle: 'One trusted profile for every companion.'),
        const SizedBox(height: 16),
        if (pets.isEmpty)
          _card(const Text('No pet profiles yet. Add a pet to get started.'))
        else
          for (final pet in pets) ...<Widget>[
            _profilePetRow(
              pet,
              '${pet.breed} · ${pet.species} · ${pet.age}',
              pet.species.toLowerCase() == 'cat'
                  ? 'assets/images/pet_cat.png'
                  : pet.species.toLowerCase() == 'rabbit'
                      ? 'assets/images/pet_rabbit.png'
                      : 'assets/images/pet_golden.png',
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 16),
        _button('Add another pet', () => _open(AppPage.addPet),
            icon: Icons.add_rounded),
      ],
    );
  }

  Widget _profilePetRow(PetProfile pet, String detail, String asset) {
    return InkWell(
      onTap: () {
        PetVaultApp.selectedPetId = pet.id;
        _selectedPetId = pet.id;
        _open(AppPage.petProfile);
      },
      borderRadius: BorderRadius.circular(18),
      child: _card(
        Row(
          children: <Widget>[
            _photo(asset, height: 76, width: 76, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(pet.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                  Text(detail,
                      style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 5),
                  _pill('${pet.records.length} health records'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _petProfile() {
    final pet = _store.pets[PetVaultApp.selectedPetId];
    if (pet == null) {
      return _scroll(<Widget>[
        _title('Pet profile'),
        const Text('The selected pet profile could not be found.'),
        _button('Back to pets', () => _switchTab(AppPage.pets)),
      ]);
    }
    if (!_store.canViewPetProfile(pet.id)) {
      return _scroll(<Widget>[
        _title('Private pet profile'),
        const Text(
          'The owner has not shared this profile with your account.',
          style: TextStyle(color: _muted),
        ),
        _button('Back to my pets', () => _switchTab(AppPage.pets)),
      ]);
    }
    final petAppointments = _store.visibleAppointments
        .where((appointment) => appointment.petId == pet.id)
        .toList();
    return _scroll(
      <Widget>[
        _card(
          Row(
            children: <Widget>[
              _photo(
                  pet.species.toLowerCase() == 'cat'
                      ? 'assets/images/pet_cat.png'
                      : pet.species.toLowerCase() == 'rabbit'
                          ? 'assets/images/pet_rabbit.png'
                          : 'assets/images/pet_golden.png',
                  height: 82,
                  width: 82,
                  radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(pet.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 20)),
                    Text('${pet.breed} · ${pet.species}',
                        style: const TextStyle(color: _muted)),
                    Text('${pet.age} · ${pet.sex} · ${pet.weightKg} kg',
                        style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
              _pill('${pet.records.length} records',
                  color: _sand, textColor: _muted),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KeyValueRow(label: 'Owner', value: _store.currentUserName),
              const SizedBox(height: 8),
              Text(
                  '${_store.currentEmail} · ${_store.currentPhone.isEmpty ? 'Phone not provided' : _store.currentPhone}',
                  style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 12),
              _KeyValueRow(
                  label: 'Microchip number',
                  value:
                      pet.microchip.isEmpty ? 'Not provided' : pet.microchip),
              const SizedBox(height: 7),
              Text(
                  pet.microchip.isEmpty
                      ? 'Add it by editing this profile if it applies.'
                      : 'Keep this identifier private unless needed for care.',
                  style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _button(
                  'Care reminders', () => _open(AppPage.vaccinationSchedule),
                  primary: false),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _button(
                  'Share profile',
                  () => _toast(
                      'Profile sharing links are not supported by the backend.')),
            ),
          ],
        ),
        const SizedBox(height: 17),
        _section('Health at a glance',
            action: 'View records →',
            onAction: () => _open(AppPage.healthRecords)),
        const SizedBox(height: 8),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KeyValueRow(
                  label: 'Saved medical records',
                  value: '${pet.records.length} records'),
              const SizedBox(height: 8),
              _KeyValueRow(
                  label: 'Latest owner weight',
                  value: '${pet.weightKg} kg · current'),
              const SizedBox(height: 8),
              Text(
                pet.records.take(2).map((record) => record.title).join('\n'),
                style:
                    const TextStyle(color: _muted, fontSize: 11, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _section('Upcoming care',
            action: 'Schedule →', onAction: () => _open(AppPage.vetDirectory)),
        const SizedBox(height: 8),
        if (petAppointments.isEmpty)
          _card(const Text('No scheduled veterinary appointments.'))
        else
          for (final appointment in petAppointments)
            _recordCard(
              '${appointment.vet} · ${appointment.type}',
              appointment.slot.toLocal().toString(),
              appointment.status,
            ),
        const SizedBox(height: 14),
        _button('Edit pet profile', () => _open(AppPage.editPet),
            primary: false),
      ],
    );
  }

  Widget _editPet() {
    final pet = _store.pets[PetVaultApp.selectedPetId];
    if (pet == null) {
      return _scroll(<Widget>[
        _title('Edit pet profile'),
        const Text('Select an existing pet profile first.'),
      ]);
    }
    return _scroll(
      <Widget>[
        _title('Edit ${pet.name}’s profile',
            subtitle: 'Only you control who can see these details.'),
        const SizedBox(height: 17),
        _field('Pet name', hint: pet.name, controller: _petNameController),
        const SizedBox(height: 12),
        _field('Species', hint: pet.species, controller: _speciesController),
        const SizedBox(height: 12),
        _field('Breed', hint: pet.breed, controller: _breedController),
        const SizedBox(height: 12),
        _field('Age', hint: pet.age, controller: _ageController),
        const SizedBox(height: 12),
        _field('Sex', hint: pet.sex, controller: _sexController),
        const SizedBox(height: 12),
        _field('Weight in kg',
            hint: '${pet.weightKg}',
            controller: _weightController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _field('Microchip number',
            hint: 'Optional', controller: _microchipController),
        const SizedBox(height: 14),
        _card(
          const Text(
            'Profile data is private by default. You choose what to share with a clinic, sitter, or buyer.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 15),
        _button('Save changes', () async {
          if (_api.isAuthenticated) {
            try {
              final updated = await _api.updatePet(
                id: pet.id,
                name: _petNameController.text,
                species: _speciesController.text,
                breed: _breedController.text,
                age: _ageController.text,
                sex: _sexController.text,
                weightKg: double.tryParse(_weightController.text.trim()) ?? 0,
                microchip: _microchipController.text,
              );
              if (!mounted) return;
              final otherPets = _store.ownerPets
                  .where((item) => item.id != pet.id)
                  .map(_remotePetJson);
              _store.replaceRemotePets(<Map<String, dynamic>>[
                ...otherPets,
                updated,
              ]);
              _toast('Pet profile updated.');
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            } on FormatException catch (error) {
              _showApiError(error);
            }
            return;
          }
          _showStoreResult(
            _store.updatePet(
              pet.id,
              name: _petNameController.text,
              species: _speciesController.text,
              breed: _breedController.text,
              age: _ageController.text,
              sex: _sexController.text,
              weight: _weightController.text,
              microchip: _microchipController.text,
            ),
            successMessage: 'Pet profile updated.',
          );
        }),
      ],
    );
  }

  Widget _healthRecords() {
    final pet = _store.pets[PetVaultApp.selectedPetId];
    if (pet == null) {
      return _scroll(<Widget>[
        _title('Health records'),
        const Text('Select a pet profile to view health records.'),
        _button('Back to pets', () => _switchTab(AppPage.pets)),
      ]);
    }
    final grants = _store.activeGrantsForPet(pet.id);
    final records = _store.accessibleHealthRecords(pet.id);
    return _scroll(
      <Widget>[
        _title('${pet.name}’s health library',
            subtitle:
                '${records.length} accessible record(s) · Private by default'),
        const SizedBox(height: 15),
        _field('Search records', hint: 'Search title, provider or date'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          children: <Widget>[
            _pill('All (${records.length})'),
            for (final type in records.map((record) => record.type).toSet())
              _pill(type, color: _sand, textColor: _muted),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Owner-controlled access',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                grants.isEmpty
                    ? 'No one currently has access. You can share selected sections for a limited time below.'
                    : grants
                        .map((grant) =>
                            '${grant.recipient}: ${grant.sections.join(', ')}')
                        .join('\n'),
                style:
                    const TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 15),
        _section('Saved records', action: 'Newest first ▾'),
        const SizedBox(height: 8),
        if (records.isEmpty)
          _card(Text(
            pet.records.isEmpty
                ? 'No health records saved yet.'
                : 'No health records are shared with ${_store.currentUserName}. Ask the owner for access.',
          ))
        else
          for (final record in records) ...<Widget>[
            _healthRecordCard(record),
            const SizedBox(height: 9),
          ],
        _section('People with access'),
        const SizedBox(height: 8),
        _field('Recipient name',
            hint: 'Name used by the care provider',
            controller: _shareRecipientController),
        const SizedBox(height: 8),
        _button('Share health essentials for 7 days', () {
          final ok = _store.grantPetAccess(
            petId: pet.id,
            recipient: _shareRecipientController.text,
            sections: <String>{'care essentials'},
            consentGiven: true,
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          );
          _showStoreResult(ok, successMessage: 'Limited access granted.');
        }),
        for (final grant in grants) ...<Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(grant.recipient),
            subtitle: Text(grant.sections.join(', ')),
            trailing: TextButton(
              onPressed: () => _showStoreResult(
                _store.revokePetAccess(pet.id, grant.recipient),
                successMessage: 'Access revoked.',
              ),
              child: const Text('Revoke'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _button('Export ${records.length} records',
                  () => _toast('A private export is prepared.'),
                  primary: false),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _button(
                  'Upload record', () => _open(AppPage.addHealthRecord)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _recordCard(String title, String date, String detail) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _pill(
              title == 'Vaccination document' ? 'Vaccination' : 'Health record',
              color: _sand,
              textColor: _muted),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _KeyValueRow(label: 'Record date', value: date),
          const SizedBox(height: 5),
          Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _healthRecordCard(HealthRecord record) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _pill(record.type, color: _sand, textColor: _muted),
          const SizedBox(height: 8),
          Text(record.title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _KeyValueRow(
              label: 'Record date',
              value: record.date.toLocal().toString().split(' ').first),
          const SizedBox(height: 5),
          Text(record.provider,
              style: const TextStyle(color: _muted, fontSize: 12)),
          if (record.attachmentName != null) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              'Local attachment · ${record.attachmentName} · ${record.attachmentSizeBytes} bytes',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(record.attachmentName!),
                  content: record.attachmentBytes != null &&
                          !record.attachmentName!.toLowerCase().endsWith('.pdf')
                      ? Image.memory(record.attachmentBytes!,
                          fit: BoxFit.contain)
                      : const Text(
                          'PDF preview is not available in this prototype. The selected file is held in memory for this app session only.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              child: const Text('View local attachment'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addHealthRecord() {
    final pet = _store.pets[PetVaultApp.selectedPetId];
    return _scroll(
      <Widget>[
        _title('Add a health record',
            subtitle: 'Save a document and choose who can access it.'),
        const SizedBox(height: 17),
        InkWell(
          onTap: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
            );
            if (result.isEmpty || !mounted) return;
            final file = result.first;
            final size = await file.length();
            if (size == null || size > 10 * 1024 * 1024) {
              _toast('Choose a readable PDF or image no larger than 10 MB.');
              return;
            }
            final bytes = await file.readAsBytes();
            if (bytes.length > 10 * 1024 * 1024 || !mounted) {
              if (mounted) {
                _toast('Choose a readable PDF or image no larger than 10 MB.');
              }
              return;
            }
            setState(() {
              _healthDocument = file;
              _healthDocumentSizeBytes = bytes.length;
              _healthDocumentBytes = bytes;
            });
          },
          child: _card(
            Column(
              children: <Widget>[
                const Icon(Icons.cloud_upload_outlined, color: _teal, size: 34),
                const SizedBox(height: 7),
                Text(_healthDocument?.name ?? 'Select a health document',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Text(
                    'PDF or image · up to 10 MB · file bytes are not uploaded',
                    style: TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
            color: _paleTeal,
          ),
        ),
        const SizedBox(height: 14),
        _field('Record title',
            hint: 'Vaccination document', controller: _recordTitleController),
        const SizedBox(height: 12),
        _field('Record type',
            hint: 'Vaccination, visit, weight…',
            controller: _recordTypeController),
        const SizedBox(height: 12),
        _field('Date', hint: 'YYYY-MM-DD', controller: _givenDateController),
        const SizedBox(height: 12),
        _field('Next due date (vaccinations)',
            hint: 'YYYY-MM-DD', controller: _dueDateController),
        const SizedBox(height: 12),
        _field('Clinic or provider',
            hint: 'Provider name', controller: _providerController),
        const SizedBox(height: 13),
        _card(
          const Text(
            'Documents describe their source; an upload is not veterinary certification.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 14),
        _button('Save private record', () async {
          final healthDocument = _healthDocument;
          final attachmentSizeBytes = _healthDocumentSizeBytes;
          final attachmentBytes = _healthDocumentBytes;
          if (healthDocument == null ||
              attachmentSizeBytes == null ||
              attachmentBytes == null) {
            _toast('Select a health document before saving.');
            return;
          }
          final date = DateTime.tryParse(_givenDateController.text.trim());
          final due = _dueDateController.text.trim().isEmpty
              ? null
              : DateTime.tryParse(_dueDateController.text.trim());
          if (date == null ||
              (_dueDateController.text.trim().isNotEmpty && due == null)) {
            _toast('Enter dates using YYYY-MM-DD.');
            return;
          }
          if (pet == null) {
            _toast('Select a pet profile before saving a health record.');
            return;
          }
          if (_api.isAuthenticated) {
            try {
              await _api.createHealthRecord(
                petId: pet.id,
                title: _recordTitleController.text.trim(),
                type: _recordTypeController.text.trim(),
                provider: _providerController.text.trim(),
                date: date,
                nextDueAt: due,
                attachmentName: healthDocument.name,
              );
              await _loadRemoteHealthRecords(pet.id);
              if (!mounted) return;
              _toast(
                'Health record saved. The backend stores its name and metadata, not the selected file bytes.',
              );
              _switchTab(AppPage.healthRecords);
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            } on FormatException catch (error) {
              _showApiError(error);
            }
            return;
          }
          final saved = _store.addHealthRecord(
            petId: pet.id,
            title: _recordTitleController.text,
            type: _recordTypeController.text,
            date: date,
            provider: _providerController.text,
            nextDueAt: due,
            attachmentName: healthDocument.name,
            attachmentSizeBytes: attachmentSizeBytes,
            attachmentBytes: attachmentBytes,
          );
          _showStoreResult(saved, successMessage: 'Private record saved.');
          if (saved) _switchTab(AppPage.healthRecords);
        }),
      ],
    );
  }

  Widget _vaccinations() {
    final pet = _store.pets[PetVaultApp.selectedPetId];
    final entries = pet?.vaccinations ?? <VaccinationEntry>[];
    final upcoming = entries
        .where((entry) =>
            entry.nextDueAt != null && entry.nextDueAt!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.nextDueAt!.compareTo(b.nextDueAt!));
    return _scroll(
      <Widget>[
        _title('Vaccination & reminders',
            subtitle: '${pet?.name ?? 'Pet'} · due dates from saved records'),
        const SizedBox(height: 14),
        if (upcoming.isNotEmpty)
          _card(
            Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: _paleTeal,
                  foregroundColor: _teal,
                  child: Icon(Icons.event_available_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Next reminder',
                          style: TextStyle(color: _muted, fontSize: 12)),
                      Text(upcoming.first.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(
                          'Due ${upcoming.first.nextDueAt!.toLocal().toString().split(' ').first}',
                          style: const TextStyle(color: _muted)),
                    ],
                  ),
                ),
                _pill(upcoming.first.statusAt(DateTime.now())),
              ],
            ),
          )
        else
          _card(const Text('No upcoming vaccination due dates are recorded.')),
        const SizedBox(height: 15),
        _section('Upcoming'),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          const Text(
              'Add a vaccination record with a next due date to see reminders.')
        else
          for (final entry in upcoming) ...<Widget>[
            _recordCard(
              entry.name,
              entry.nextDueAt!.toLocal().toString().split(' ').first,
              '${entry.statusAt(DateTime.now())} · ${entry.provider}',
            ),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 15),
        _section('Completed'),
        const SizedBox(height: 8),
        for (final entry in entries) ...<Widget>[
          _recordCard(
            entry.name,
            entry.givenAt.toLocal().toString().split(' ').first,
            'Recorded · ${entry.provider}',
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 14),
        _button('Add vaccination record', () => _open(AppPage.addHealthRecord)),
      ],
    );
  }

  Widget _weightHistory() {
    final pet = _store.pets[PetVaultApp.selectedPetId];
    if (pet == null) {
      return _scroll(<Widget>[
        _title('Weight & growth history'),
        const Text('Select a pet profile first.'),
      ]);
    }
    final records = pet.records
        .where((record) => record.type.toLowerCase().contains('weight'))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return _scroll(
      <Widget>[
        _title('Weight & growth history',
            subtitle: '${pet.name} · Measurements added by the owner'),
        const SizedBox(height: 15),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KeyValueRow(
                  label: 'Current weight', value: '${pet.weightKg} kg'),
              const SizedBox(height: 5),
              Text(records.isEmpty
                  ? 'No weight history recorded'
                  : 'Latest entry · ${records.first.date.toLocal()}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          const Text('No historical weight entries yet.')
        else
          for (final record in records) ...<Widget>[
            _recordCard(
                record.title,
                record.date.toLocal().toString().split(' ').first,
                '${record.type} · ${record.provider}'),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 14),
        const Text(
          'Historical weight entries are not supported by the backend. Update the current measurement in the pet profile instead.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _button('Health records', () => _open(AppPage.healthRecords)),
        const SizedBox(height: 8),
        _button('Edit profile', () => _open(AppPage.editPet), primary: false),
        const SizedBox(height: 8),
        const Text(
          'Measurements are owner-provided and are not veterinary advice.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _favorites() {
    final listings = _store.favoriteListings;
    return _scroll(
      <Widget>[
        _title('My favorites',
            subtitle: 'Listings you saved for a closer look.'),
        const SizedBox(height: 14),
        if (listings.isEmpty)
          _card(
            const Text(
              'No saved listings yet. Tap the heart on an active listing to save it here.',
              style: TextStyle(color: _muted, height: 1.4),
            ),
          )
        else
          for (final listing in listings) ...<Widget>[
            _card(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    _photo(listing.image, height: 56, width: 56, radius: 10),
                title: Text(listing.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    '${listing.city} · Rs ${listing.price.toStringAsFixed(0)}'),
                trailing: IconButton(
                  tooltip: 'Remove favorite',
                  onPressed: () => _toggleRemoteFavorite(listing),
                  icon: const Icon(Icons.favorite, color: _teal),
                ),
                onTap: () {
                  PetVaultApp.selectedListingId = listing.id;
                  _open(AppPage.listingDetail);
                },
              ),
            ),
            const SizedBox(height: 9),
          ],
        _button('Browse marketplace', () => _open(AppPage.marketplace),
            primary: false),
      ],
    );
  }

  Widget _vetDirectory() {
    return _scroll(
      <Widget>[
        _title('Verified veterinarians',
            subtitle:
                'Providers with an approved PetVault verification review.'),
        const SizedBox(height: 13),
        if (_remoteVets.isEmpty)
          _card(const Text('No verified veterinarians are currently listed.'))
        else
          for (final vet in _remoteVets) ...<Widget>[
            _card(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: _paleTeal,
                  foregroundColor: _teal,
                  child: Icon(Icons.medical_services_outlined),
                ),
                title: Text(vet['displayName'] as String? ?? 'Veterinarian',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('PetVault role verification approved'),
                trailing: const Icon(Icons.chevron_right_rounded, color: _teal),
                onTap: () {
                  _selectedVet =
                      vet['displayName'] as String? ?? 'Veterinarian';
                  _selectedVetId = vet['id'] as String? ?? '';
                  _open(AppPage.vetAvailability);
                },
              ),
            ),
            const SizedBox(height: 9),
          ],
      ],
    );
  }

  Widget _vetAvailability() {
    final managing = _store.activeRole == PetVaultRole.veterinarian;
    final vet = managing ? _store.currentUserName : _selectedVet;
    return _scroll(
      <Widget>[
        _title(
          managing ? 'Manage availability' : 'Book a vet appointment',
          subtitle:
              '$vet · ${managing ? 'Publish future slots' : 'Choose an open slot'}',
        ),
        const SizedBox(height: 14),
        if (managing)
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Add a 10:00 AM appointment slot',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(
                    'Date: ${_selectedDate.toLocal().toString().split(' ').first}',
                    style: const TextStyle(color: _muted)),
                const SizedBox(height: 10),
                _button('Choose date', () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && mounted) {
                    setState(() => _selectedDate = picked);
                  }
                }, primary: false),
                const SizedBox(height: 8),
                _button('Publish slot', () async {
                  final startsAt = DateTime(_selectedDate.year,
                      _selectedDate.month, _selectedDate.day, 10);
                  try {
                    await _api.publishVetAvailability(
                      startsAt: startsAt,
                      endsAt: startsAt.add(const Duration(hours: 1)),
                    );
                    await _loadRemoteVetAvailability();
                    if (mounted) _toast('Appointment slot published.');
                  } on PetVaultApiException catch (error) {
                    _showApiError(error);
                  }
                }),
              ],
            ),
          )
        else if (_selectedVetId.isEmpty)
          _card(const Text(
              'Choose a veterinarian from the directory to view their available times.'))
        else if (_remoteVetAvailability
            .where((slot) => slot['veterinarianId'] == _selectedVetId)
            .isEmpty)
          _card(
            const Text(
              'No open appointment times are published. Please check again later.',
              style: TextStyle(color: _muted),
            ),
          )
        else
          for (final slot in _remoteVetAvailability.where(
              (slot) => slot['veterinarianId'] == _selectedVetId)) ...<Widget>[
            _card(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available, color: _teal),
                title: Text(
                    '${DateTime.parse(slot['startsAt'] as String).toLocal()}'),
                subtitle: Text(slot['veterinarian'] as String? ?? vet),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  try {
                    await _api.bookVetAppointment(
                      availabilityId: slot['id'] as String,
                      petId: PetVaultApp.selectedPetId,
                      type: 'Consultation',
                    );
                    await _loadRemoteAppointments();
                    if (mounted) {
                      _toast('Vet appointment booked.');
                      _open(AppPage.teleConsultation);
                    }
                  } on PetVaultApiException catch (error) {
                    _showApiError(error);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        if (!managing)
          _button('Back to veterinarian directory',
              () => _open(AppPage.vetDirectory),
              primary: false),
      ],
    );
  }

  Widget _teleConsultation() {
    final pendingAppointments = _remoteAppointments
        .where((appointment) => appointment['status'] != 'Complete')
        .toList();
    final pendingAppointment =
        pendingAppointments.isEmpty ? null : pendingAppointments.first;
    final isVet = _store.activeRole == PetVaultRole.veterinarian;
    return _scroll(
      <Widget>[
        _title(isVet ? 'Consultation workspace' : 'Consultation request',
            subtitle: isVet
                ? 'Record notes for a scheduled consultation.'
                : 'Appointment details and notes are stored with PetVault.'),
        const SizedBox(height: 13),
        _card(
          const Text(
            'Video consultations are not available. Contact the clinic directly for urgent care.',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 12),
        if (isVet && pendingAppointment != null) ...<Widget>[
          _card(
            Text(
              '${pendingAppointment['petName']} · ${pendingAppointment['startsAt']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          _field('Consultation notes',
              hint: 'Source-based notes; no diagnosis by this prototype',
              controller: _vetNotesController,
              maxLines: 4),
          const SizedBox(height: 12),
          _button('Save consultation notes', () async {
            try {
              await _api.completeVetAppointment(
                appointmentId: pendingAppointment['id'] as String,
                notes: _vetNotesController.text,
              );
              await _loadRemoteAppointments();
              if (mounted) _toast('Consultation notes saved.');
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            }
          }),
        ] else if (!isVet && _remoteAppointments.isNotEmpty)
          for (final appointment in _remoteAppointments.reversed) ...<Widget>[
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Appointment · ${appointment['petName']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${appointment['startsAt']} · ${appointment['status']}'),
                  if (appointment['consultationNotes'] is String &&
                      (appointment['consultationNotes'] as String).isNotEmpty)
                    Text(appointment['consultationNotes'] as String),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ]
        else
          _button('Find a veterinarian', () => _open(AppPage.vetDirectory)),
      ],
    );
  }

  Widget _marketplace() {
    final cards = _store.searchListings(
      species: _speciesFilter,
      city: _filterCityController.text,
      minPrice: double.tryParse(_minPriceController.text),
      maxPrice: double.tryParse(_maxPriceController.text),
      verifiedOnly: _verifiedOnly,
      query: _queryController.text,
    );
    return _scroll(
      <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => _toast('Marketplace'),
              icon: const Icon(Icons.chevron_left_rounded, color: _muted),
            ),
            const Expanded(
              child: Text('Pets Marketplace',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            TextButton(
              onPressed: () => _open(AppPage.myListings),
              child: const Text('+ List'),
            ),
            IconButton(
              onPressed: _openDirectory,
              icon: const Icon(Icons.grid_view_rounded, color: _teal, size: 19),
            ),
          ],
        ),
        _field('Search',
            hint: 'Search breeds, pets…',
            controller: _queryController,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (final label in <String>['All', 'Dog', 'Cat', 'Rabbit'])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _category == label,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _category = label;
                      _speciesFilter = label == 'All' ? '' : label;
                    }),
                    selectedColor: _teal,
                    backgroundColor: _sand,
                    labelStyle: TextStyle(
                      color: _category == label ? Colors.white : _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                  ),
                ),
              ActionChip(
                label: const Text('Filters →'),
                backgroundColor: _cream,
                side: BorderSide.none,
                onPressed: () => _open(AppPage.searchFilters),
              ),
              ActionChip(
                label: const Text('Favorites'),
                backgroundColor: _cream,
                side: BorderSide.none,
                onPressed: () => _open(AppPage.favorites),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 263,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];
            return InkWell(
              onTap: () {
                PetVaultApp.selectedListingId = item.id;
                _open(AppPage.listingDetail);
              },
              borderRadius: BorderRadius.circular(17),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _photo(item.image,
                        height: 116, width: double.infinity, radius: 12),
                    const SizedBox(height: 7),
                    _pill(item.verifiedSeller
                        ? '✓ Verified seller'
                        : 'Seller not verified'),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${item.age} · ${item.city}',
                        maxLines: 1,
                        style: const TextStyle(color: _muted, fontSize: 10)),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text('Rs ${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                        Flexible(
                          child: _pill(
                              item.healthNotes.isEmpty
                                  ? 'Health info'
                                  : 'Health notes',
                              color: _sand,
                              textColor: _muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (cards.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No listings match these filters.',
                textAlign: TextAlign.center),
          ),
      ],
    );
  }

  Widget _filters() {
    return _scroll(
      <Widget>[
        _title('Find a pet',
            subtitle: 'Filter listings by the details that matter.'),
        const SizedBox(height: 17),
        _field('Location', hint: 'Karachi', controller: _filterCityController),
        const SizedBox(height: 13),
        _section('Species'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final species in <String>['Dog', 'Cat', 'Rabbit'])
              ChoiceChip(
                label: Text(species),
                selected: _speciesFilter == species,
                onSelected: (selected) =>
                    setState(() => _speciesFilter = selected ? species : ''),
              ),
          ],
        ),
        const SizedBox(height: 15),
        _section('Age range'),
        const SizedBox(height: 8),
        _card(const Text('Puppy / kitten             0 – 12 months')),
        const SizedBox(height: 15),
        _section('Price range'),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
                child: _field('Minimum',
                    hint: 'Rs 0',
                    controller: _minPriceController,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(
                child: _field('Maximum',
                    hint: 'Rs 100,000',
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 15),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: _teal,
          title: const Text('Verified sellers only',
              style: TextStyle(fontWeight: FontWeight.w600)),
          value: _verifiedOnly,
          onChanged: (value) => setState(() => _verifiedOnly = value),
        ),
        const SizedBox(height: 12),
        _button('Show matching listings', () => Navigator.maybePop(context)),
        const SizedBox(height: 8),
        _button('Clear filters', () {
          setState(() {
            _speciesFilter = '';
            _verifiedOnly = false;
            _filterCityController.clear();
            _minPriceController.clear();
            _maxPriceController.clear();
          });
        }, primary: false),
      ],
    );
  }

  Widget _listingDetail() {
    final listing = _store.listings[PetVaultApp.selectedListingId];
    if (listing == null) {
      return _scroll(<Widget>[
        _title('Pet listing'),
        const Text('This listing could not be found.'),
        _button('Back to marketplace', () => _open(AppPage.marketplace)),
      ]);
    }
    return _scroll(
      <Widget>[
        _photo(listing.image, height: 235, width: double.infinity, radius: 18),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const Spacer(),
            TextButton(
              onPressed: () => _open(AppPage.reportListing),
              child: const Text('Report'),
            ),
            IconButton(
              onPressed: () => _toggleRemoteFavorite(listing),
              icon: Icon(
                listing.favorites.contains(_store.currentUserId)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _teal,
              ),
            ),
          ],
        ),
        _title(listing.title),
        const SizedBox(height: 5),
        Text('${listing.breed} · ${listing.age} · ${listing.city}',
            style: const TextStyle(color: _muted)),
        const SizedBox(height: 8),
        _KeyValueRow(
            label: 'Listing ${listing.id}',
            value: 'Rs ${listing.price.toStringAsFixed(0)}'),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: _sand,
                    child: Icon(Icons.person_outline_rounded, color: _muted),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            listing.sellerName.isEmpty
                                ? 'Seller'
                                : listing.sellerName,
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                            listing.verifiedSeller
                                ? 'Seller verification approved'
                                : 'Seller verification not shown',
                            style: TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _section('Seller-provided health notes'),
              const SizedBox(height: 6),
              Text(
                listing.healthNotes.isEmpty
                    ? 'The seller has not provided health notes.'
                    : listing.healthNotes,
                style:
                    const TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
                child: _button('Contact seller', () {
              _toast(
                  'In-app messaging is not configured. Do not send payment outside verified channels.');
            })),
            const SizedBox(width: 10),
            Expanded(
              child: _button('Arrange a visit', () {
                _toast(
                    'Visit scheduling is not available yet. Contact the seller directly.');
              }, primary: false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _createListing() {
    return _scroll(
      <Widget>[
        _title('Create a pet listing',
            subtitle: 'Step 1 of 2 · Pet and listing details'),
        const SizedBox(height: 17),
        _card(
          const Row(
            children: <Widget>[
              Icon(Icons.info_outline_rounded, color: _teal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A clear, honest listing helps families make informed decisions.',
                  style: TextStyle(color: _muted, height: 1.35),
                ),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 15),
        _field('Listing title',
            hint: 'e.g. Golden Retriever puppy',
            controller: _listingTitleController),
        const SizedBox(height: 12),
        _field('Species',
            hint: 'Dog, cat, rabbit…', controller: _listingSpeciesController),
        const SizedBox(height: 12),
        _field('Breed',
            hint: 'Golden Retriever', controller: _listingBreedController),
        const SizedBox(height: 12),
        _field('Age', hint: '8 weeks', controller: _ageListingController),
        const SizedBox(height: 12),
        _field('Location', hint: 'City / area', controller: _cityController),
        const SizedBox(height: 12),
        _field('Price (PKR)',
            hint: '45000',
            controller: _priceController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _button('Continue to health & photos', () {
          if (_listingTitleController.text.trim().isEmpty ||
              _listingSpeciesController.text.trim().isEmpty ||
              _listingBreedController.text.trim().isEmpty ||
              _ageListingController.text.trim().isEmpty ||
              _cityController.text.trim().isEmpty ||
              double.tryParse(_priceController.text.trim()) == null) {
            _toast('Complete the required pet and listing details first.');
            return;
          }
          _open(AppPage.createListingDetails);
        }),
      ],
    );
  }

  Widget _createListingDetails() {
    return _scroll(
      <Widget>[
        _title('Health & photos',
            subtitle: 'Step 2 of 2 · Keep information transparent.'),
        const SizedBox(height: 16),
        _card(
          const Column(
            children: <Widget>[
              Icon(Icons.add_photo_alternate_outlined, color: _teal, size: 32),
              SizedBox(height: 7),
              Text('Listing photo URL',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Use an image URL you are authorized to publish.',
                  style: TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 13),
        _field('Photo URL (optional)',
            hint: 'https://example.com/pet-photo.jpg',
            controller: _listingImageController,
            keyboardType: TextInputType.url),
        const SizedBox(height: 12),
        _field('Vaccination history',
            hint: 'Describe records available',
            controller: _vaccinationHistoryController),
        const SizedBox(height: 12),
        _field('Health notes',
            hint: 'Known conditions, care, or none reported',
            controller: _listingNotesController),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I confirm details are accurate'),
          activeThumbColor: _teal,
          value: _listingConfirmed,
          onChanged: (value) => setState(() => _listingConfirmed = value),
        ),
        _button('Submit listing for review', () async {
          if (!_listingConfirmed) {
            _toast('Confirm listing accuracy before submitting.');
            return;
          }
          final species = _listingSpeciesController.text.trim();
          final image = _listingImageController.text.trim();
          if (image.isNotEmpty &&
              !const <String>['http', 'https']
                  .contains(Uri.tryParse(image)?.scheme)) {
            _toast('Enter a valid HTTPS photo URL or leave it blank.');
            return;
          }
          final healthNotes = <String>[
            _vaccinationHistoryController.text.trim(),
            _listingNotesController.text.trim(),
          ].where((value) => value.isNotEmpty).join(' · ');
          if (_api.isAuthenticated) {
            try {
              final listing = await _api.createListing(
                title: _listingTitleController.text.trim(),
                species: species,
                breed: _listingBreedController.text.trim(),
                city: _cityController.text.trim(),
                price: double.parse(_priceController.text.trim()),
                age: _ageListingController.text.trim(),
                imageUrl: image,
                healthNotes: healthNotes,
              );
              if (!mounted) return;
              _store.addRemoteListing(listing);
              PetVaultApp.selectedListingId = listing['id'] as String;
              _toast('Listing submitted for trust and safety review.');
              _open(AppPage.myListings);
            } on PetVaultApiException catch (error) {
              _showApiError(error);
            } on FormatException catch (error) {
              _showApiError(error);
            }
            return;
          }
          _toast('Sign in with a verified seller account to submit listings.');
        }),
      ],
    );
  }

  Widget _chat() {
    final listing = _store.listings[PetVaultApp.selectedListingId];
    return _scroll(
      <Widget>[
        _card(
          Row(
            children: <Widget>[
              const CircleAvatar(
                backgroundColor: _paleTeal,
                foregroundColor: _teal,
                child: Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                        listing?.sellerName.isNotEmpty == true
                            ? listing!.sellerName
                            : 'Seller',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(listing?.title ?? 'PetVault conversation',
                        style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
              if (listing?.verifiedSeller == true) _pill('Verified'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          const Text(
            'In-app messaging is not available yet. No message has been sent. Contact the seller using a verified channel and never share verification codes.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
          color: _paleTeal,
        ),
      ],
    );
  }

  Widget _reportListing() {
    return _scroll(
      <Widget>[
        _title('Report this listing',
            subtitle: 'Help the trust team review a potential issue.'),
        const SizedBox(height: 16),
        _card(
          Text(
            _store.listings[PetVaultApp.selectedListingId]?.title ??
                'Selected listing',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Why are you reporting this?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        RadioGroup<String>(
          groupValue: _selectedReportReason,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedReportReason = value);
            }
          },
          child: Column(
            children: <Widget>[
              for (final reason in <String>[
                'Misleading health information',
                'Suspicious seller or payment request',
                'Animal welfare concern',
                'Duplicate or inaccurate listing',
                'Something else',
              ])
                RadioListTile<String>(
                  value: reason,
                  activeColor: _teal,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),
        _field('Additional details',
            hint: 'Share context with the review team'),
        const SizedBox(height: 14),
        _button('Submit report', () async {
          try {
            await _api.reportListing(
                PetVaultApp.selectedListingId, _selectedReportReason);
            if (mounted) _toast('Report submitted for review.');
          } on PetVaultApiException catch (error) {
            _showApiError(error);
          }
        }),
      ],
    );
  }

  Widget _myListings() {
    final listings = _store.currentSellerListings;
    return _scroll(
      <Widget>[
        _section('Your listings',
            action: '+ Add listing',
            onAction: () => _open(AppPage.createListing)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _open(AppPage.petVisitRequests),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Manage visit requests'),
        ),
        const SizedBox(height: 11),
        if (listings.isEmpty)
          _card(const Text(
            'You have not submitted a listing yet. New listings appear here after submission.',
            style: TextStyle(color: _muted),
          ))
        else
          for (final listing in listings) ...<Widget>[
            _listingOwnerCard(listing),
            if (listing != listings.last) const SizedBox(height: 9),
          ],
        const SizedBox(height: 13),
        _button('Create a new listing', () => _open(AppPage.createListing)),
      ],
    );
  }

  Widget _listingOwnerCard(PetListing listing) {
    final status = switch (listing.status) {
      ListingStatus.draft => 'Draft',
      ListingStatus.pendingReview => 'Under review',
      ListingStatus.active => 'Active',
      ListingStatus.rejected => 'Not approved',
      ListingStatus.sold => 'Sold',
    };
    return _card(
      Row(
        children: <Widget>[
          _photo(listing.image, height: 64, width: 66, radius: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(listing.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('$status · ${listing.city}',
                    style: const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              PetVaultApp.selectedListingId = listing.id;
              if (value == 'edit') _open(AppPage.editListing);
              if (value == 'stats') _open(AppPage.listingPerformance);
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'edit', child: Text('Edit listing')),
              PopupMenuItem(value: 'stats', child: Text('View performance')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editListing() {
    final listing = _store.listings[PetVaultApp.selectedListingId];
    return _scroll(
      <Widget>[
        _title('Edit pet listing',
            subtitle: 'Update your listing details and health notes.'),
        const SizedBox(height: 15),
        if (listing == null || listing.sellerId != _store.currentUserId)
          _card(const Text(
              'This listing is unavailable or does not belong to your account.'))
        else ...<Widget>[
          _field('Listing title',
              hint: 'Pet listing title', controller: _listingTitleController),
          const SizedBox(height: 12),
          _field('Price',
              hint: '45000',
              controller: _priceController,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _field('City', hint: 'City', controller: _cityController),
          const SizedBox(height: 12),
          _field('Health information',
              hint: 'Add transparent health notes',
              controller: _listingNotesController),
          const SizedBox(height: 12),
          _card(
            const Text(
              'Important health changes may require review before the listing is updated.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            color: _paleTeal,
          ),
          const SizedBox(height: 14),
          _button('Save listing changes', () async {
            if (_api.isAuthenticated) {
              final price = double.tryParse(_priceController.text.trim());
              if (price == null) {
                _toast('Enter a valid listing price.');
                return;
              }
              try {
                final updated = await _api.updateListing(
                  id: listing.id,
                  title: _listingTitleController.text.trim(),
                  species: listing.species,
                  breed: listing.breed,
                  city: _cityController.text.trim(),
                  price: price,
                  age: listing.age,
                  imageUrl: listing.image,
                  healthNotes: _listingNotesController.text.trim(),
                );
                if (!mounted) return;
                _store.addRemoteListing(updated);
                _toast('Changes saved and queued for listing review.');
                Navigator.maybePop(context);
              } on PetVaultApiException catch (error) {
                _showApiError(error);
              } on FormatException catch (error) {
                _showApiError(error);
              }
              return;
            }
            final saved = _store.updateListing(
              listing.id,
              title: _listingTitleController.text,
              city: _cityController.text,
              price: _priceController.text,
              healthNotes: _listingNotesController.text,
            );
            _showStoreResult(
              saved,
              successMessage: 'Changes saved and queued for listing review.',
            );
            if (saved) Navigator.maybePop(context);
          }),
        ],
      ],
    );
  }

  Widget _listingPerformance() {
    final listing = _store.listings[PetVaultApp.selectedListingId];
    if (listing == null || listing.sellerId != _store.currentUserId) {
      return _scroll(<Widget>[
        _title('Listing performance'),
        const SizedBox(height: 12),
        _card(const Text(
            'This listing is unavailable or does not belong to your account.')),
      ]);
    }
    return _scroll(
      <Widget>[
        _title(listing.title, subtitle: 'Listing performance · Last 30 days'),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
                child: _metricCard(
                    'Views', 'Not tracked', 'Analytics unavailable')),
            const SizedBox(width: 9),
            Expanded(
                child: _metricCard(
                    'Messages', 'Not tracked', 'Messaging unavailable')),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KeyValueRow(label: 'Listing status', value: listing.status.name),
              const SizedBox(height: 10),
              const _KeyValueRow(label: 'Visit requests', value: 'Not tracked'),
              const SizedBox(height: 10),
              _KeyValueRow(
                  label: 'Trust review',
                  value: listing.verifiedSeller
                      ? 'Verified seller'
                      : 'Pending verification'),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _section('Recent inquiries'),
        const SizedBox(height: 8),
        _card(const Text(
          'Inquiry analytics and message delivery are not connected in this local prototype.',
          style: TextStyle(color: _muted),
        )),
        const SizedBox(height: 12),
        _button(
            'Open listing messages', () => _open(AppPage.buyerSellerMessaging)),
      ],
    );
  }

  Widget _scheduleVisit() {
    final listing = _store.listings[PetVaultApp.selectedListingId];
    return _scroll(
      <Widget>[
        _title('Schedule a pet visit',
            subtitle: 'Choose a time to meet the seller and pet.'),
        const SizedBox(height: 15),
        if (listing == null)
          _card(
              const Text('Select an active listing before requesting a visit.'))
        else
          _card(
            Row(
              children: <Widget>[
                _photo(listing.image, height: 70, width: 76, radius: 12),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(listing.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${listing.city} · ${listing.sellerId}',
                          style: const TextStyle(color: _muted, fontSize: 12)),
                      Text(
                          listing.verifiedSeller
                              ? 'Seller identity verified'
                              : 'Seller verification pending',
                          style: const TextStyle(color: _teal, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
        _section('Available dates'),
        const SizedBox(height: 8),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                  'Selected: ${_selectedDate.toLocal().toString().split(' ').first}'),
              const SizedBox(height: 8),
              _button('Choose visit date', () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                );
                if (date != null && mounted) {
                  setState(() => _selectedDate = date);
                }
              }, primary: false),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _field('Message to seller',
            hint: 'Introduce yourself or ask a question',
            controller: _visitMessageController),
        const SizedBox(height: 12),
        _card(
          const Text(
            'Meet in a safe public place. A visit request does not reserve or guarantee a pet.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 14),
        _button(
          _visitSubmitting ? 'Sending request...' : 'Request visit',
          listing == null || _visitSubmitting
              ? null
              : () async {
                  if (!_api.isAuthenticated) {
                    _toast('Sign in as a pet owner to request a visit.');
                    _open(AppPage.authentication);
                    return;
                  }
                  setState(() => _visitSubmitting = true);
                  try {
                    final selectedDate = _selectedDate;
                    final scheduledAt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      12,
                    );
                    await _api.createVisitRequest(
                      listingId: listing.id,
                      scheduledAt: scheduledAt,
                      message: _visitMessageController.text.trim(),
                    );
                    if (!mounted) return;
                    _toast('Visit request sent to the seller.');
                    _open(AppPage.petVisitRequests);
                  } on PetVaultApiException catch (error) {
                    _showApiError(error);
                  } on FormatException catch (error) {
                    _showApiError(error);
                  } finally {
                    if (mounted) setState(() => _visitSubmitting = false);
                  }
                },
          isLoading: _visitSubmitting,
        ),
      ],
    );
  }

  Widget _petVisitRequests() {
    if (!_api.isAuthenticated) {
      return _scroll(<Widget>[
        _title('Pet visit requests'),
        const SizedBox(height: 12),
        _card(const Text('Sign in to view your visit requests.')),
        const SizedBox(height: 12),
        _button('Sign in', () => _open(AppPage.authentication)),
      ]);
    }
    if (!<String>{'owner', 'seller'}.contains(_api.activeRole)) {
      return _scroll(<Widget>[
        _title('Pet visit requests'),
        const SizedBox(height: 12),
        _card(const Text(
          'Visit requests are available to pet owners and verified sellers.',
          style: TextStyle(color: _muted),
        )),
      ]);
    }
    return _scroll(<Widget>[
      _section('Pet visit requests',
          action: 'Refresh', onAction: _loadRemoteVisitRequests),
      const SizedBox(height: 10),
      if (_remoteVisitRequests.isEmpty)
        _card(const Text(
          'No visit requests yet. New requests will appear here.',
          style: TextStyle(color: _muted),
        ))
      else
        for (final request in _remoteVisitRequests) ...<Widget>[
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  request['listingTitle'] as String? ?? 'Pet listing',
                  style:
                      const TextStyle(color: _ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${request['city'] ?? ''} · ${_api.activeRole == 'seller' ? 'Buyer: ${request['buyerName'] ?? 'Pet owner'}' : 'Seller: ${request['sellerName'] ?? 'Listing owner'}'}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested time: ${request['scheduledAt'] ?? 'Not available'}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                if ((request['message'] as String? ?? '')
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(request['message'] as String),
                ],
                const SizedBox(height: 7),
                _pill(
                  (request['status'] as String? ?? 'unknown').toUpperCase(),
                  color: _sand,
                  textColor: _ink,
                ),
                if (request['id'] is String &&
                    request['status'] == 'requested' &&
                    _api.activeRole == 'seller') ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => _updateVisitRequestStatus(
                            request['id'] as String, 'confirmed'),
                        child: const Text('Confirm'),
                      ),
                      TextButton(
                        onPressed: () => _updateVisitRequestStatus(
                            request['id'] as String, 'declined'),
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
                ] else if (request['id'] is String &&
                    <String>{'requested', 'confirmed'}
                        .contains(request['status']) &&
                    _api.activeRole == 'owner')
                  TextButton(
                    onPressed: () => _updateVisitRequestStatus(
                        request['id'] as String, 'cancelled'),
                    child: const Text('Cancel request'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
    ]);
  }

  Widget _shop() {
    final query = _queryController.text.trim().toLowerCase();
    final products = _store.publishedProducts
        .where((product) =>
            query.isEmpty || product.name.toLowerCase().contains(query))
        .toList();
    return _scroll(
      <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text('Pet essentials',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Cart',
              onPressed: () => _open(AppPage.checkout),
              icon: Badge(
                label: Text('$_cartCount'),
                isLabelVisible: _cartCount > 0,
                child: const Icon(Icons.shopping_cart_outlined, color: _teal),
              ),
            ),
            IconButton(
              onPressed: _openDirectory,
              icon: const Icon(Icons.grid_view_rounded, color: _teal),
            ),
          ],
        ),
        _field('Search products',
            hint: 'Search available products',
            controller: _queryController,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 15),
        _section('Available products'),
        const SizedBox(height: 10),
        if (products.isEmpty)
          _card(const Text('No products match your search.'))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 230,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return InkWell(
                onTap: () {
                  PetVaultApp.selectedProductId = product.id;
                  _open(AppPage.productDetail);
                },
                borderRadius: BorderRadius.circular(17),
                child: _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _photo(product.image,
                          height: 124, width: double.infinity, radius: 12),
                      const SizedBox(height: 7),
                      Text(product.name,
                          maxLines: 2,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                                'Rs ${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Add to cart',
                            onPressed: () {
                              if (!_api.isAuthenticated) {
                                _open(AppPage.authentication);
                                return;
                              }
                              _showStoreResult(
                                _store.addToCart(product.id),
                                successMessage: 'Added to your cart.',
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline,
                                color: _teal, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _productDetail() {
    final product = _store.products[PetVaultApp.selectedProductId];
    if (product == null) {
      return _scroll(<Widget>[
        _title('Product details'),
        const Text('The selected product is unavailable.'),
        _button('Back to shop', () => _open(AppPage.shop)),
      ]);
    }
    return _scroll(
      <Widget>[
        _photo(product.image, height: 250, width: double.infinity, radius: 18),
        const SizedBox(height: 14),
        if (product.vendorName.isNotEmpty) _pill('Verified vendor'),
        const SizedBox(height: 8),
        _title(product.name),
        const SizedBox(height: 5),
        Text(
            '${product.vendorName.isEmpty ? 'Vendor' : product.vendorName} · ${product.stock} in stock',
            style: const TextStyle(color: _muted)),
        const SizedBox(height: 8),
        Text('Rs ${product.price.toStringAsFixed(0)}',
            style: const TextStyle(
                color: _ink, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 13),
        if (product.stock == 0)
          _card(const Text('This product is currently out of stock.')),
        const SizedBox(height: 14),
        _button('Add to cart', () {
          if (!_api.isAuthenticated) {
            _open(AppPage.authentication);
            return;
          }
          _showStoreResult(
            _store.addToCart(product.id),
            successMessage: 'Added to your cart.',
          );
        }),
        const SizedBox(height: 8),
        _button('View cart · $_cartCount items', () => _open(AppPage.checkout),
            primary: false),
      ],
    );
  }

  Widget _checkout() {
    final cartItems = _store.cart.entries.toList();
    if (!_api.isAuthenticated) {
      return _scroll(<Widget>[
        _title('Your cart'),
        _card(const Text('Sign in to review your cart.')),
        const SizedBox(height: 12),
        _button('Sign in', () => _open(AppPage.authentication)),
      ]);
    }
    return _scroll(
      <Widget>[
        _title('Cart & project checkout',
            subtitle:
                'Demo checkout uses a mock payment and does not charge money.'),
        const SizedBox(height: 14),
        if (cartItems.isEmpty)
          _card(const Text(
              'Your cart is empty. Browse pet essentials to add products.'))
        else
          for (final entry in cartItems) ...<Widget>[
            if (_store.products[entry.key] case final product?)
              _card(
                Row(
                  children: <Widget>[
                    _photo(product.image, height: 70, width: 72, radius: 12),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              '${product.vendorName.isEmpty ? 'Vendor' : product.vendorName} · Qty ${entry.value}',
                              style:
                                  const TextStyle(color: _muted, fontSize: 12)),
                          Text(
                              'Rs ${(product.price * entry.value).toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove one',
                      onPressed: () {
                        if (entry.value == 1) {
                          _store.removeFromCart(product.id);
                        } else {
                          _store.removeFromCart(product.id);
                          _store.addToCart(product.id,
                              quantity: entry.value - 1);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline,
                          color: _muted),
                    ),
                    IconButton(
                      tooltip: 'Add one',
                      onPressed: () => _showStoreResult(
                        _store.addToCart(product.id),
                        successMessage: 'Cart quantity updated.',
                      ),
                      icon: const Icon(Icons.add_circle_outline, color: _teal),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        if (cartItems.isNotEmpty) ...<Widget>[
          _card(const Text(
              'This project checkout records an order and simulates payment approval. It does not collect a delivery address or charge a real payment method.')),
          const SizedBox(height: 15),
          _card(
            Column(
              children: <Widget>[
                _KeyValueRow(
                    label: 'Subtotal',
                    value: 'Rs ${_store.cartSubtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _button(
            _checkoutSubmitting
                ? 'Processing demo order...'
                : 'Place demo order',
            () async {
              if (_checkoutSubmitting) return;
              setState(() => _checkoutSubmitting = true);
              try {
                final order = await _api.createOrder(_store.cart);
                await _api.payOrder(order['id'] as String);
                await Future.wait<void>(<Future<void>>[
                  _loadRemoteOrders(),
                  _loadRemoteProducts(),
                ]);
                if (!mounted) return;
                _store.clearCart();
                _toast('Demo order placed. No real payment was taken.');
              } on PetVaultApiException catch (error) {
                _showApiError(error);
              } on FormatException catch (error) {
                _showApiError(error);
              } finally {
                if (mounted) setState(() => _checkoutSubmitting = false);
              }
            },
            isLoading: _checkoutSubmitting,
          ),
        ],
      ],
    );
  }

  Widget _orderTracking() {
    final orders = _store.visibleOrders.reversed.toList();
    final order = orders.isEmpty ? null : orders.first;
    if (order == null) {
      return _scroll(<Widget>[
        _title('Order tracking'),
        const Text('No orders to track yet.'),
        _button('Browse shop', () => _open(AppPage.shop)),
      ]);
    }
    const statuses = <String>['Processing', 'Shipped', 'Delivered'];
    final step = statuses.indexOf(order.status);
    return _scroll(
      <Widget>[
        _title('Order tracking', subtitle: 'Order ${order.id}'),
        const SizedBox(height: 14),
        _card(
          Row(
            children: <Widget>[
              const Icon(Icons.local_shipping_outlined, color: _teal, size: 30),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(order.status,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Text(
                        'Order status from PetVault · no carrier tracking',
                        style: TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < statuses.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  index <= step
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: index <= step ? _teal : _line,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(statuses[index],
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(index <= step ? 'Status confirmed' : 'Not reached',
                          style: const TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _vendorDashboard() {
    final products = _store.products.values
        .where((product) => product.vendorId == _store.currentUserId)
        .toList();
    final orders = _store.visibleOrders;
    final paidSales = orders
        .where((order) => order.paymentStatus == PaymentStatus.paid)
        .fold<double>(0, (total, order) => total + order.total);
    final lowStockCount =
        products.where((product) => product.stock <= 5).length;
    return _scroll(
      <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_store.currentUserName,
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w700)),
                  Text(
                      'Store overview · ${DateTime.now().toLocal().toString().split(' ').first}',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _open(AppPage.vendorOrders),
              child: const Text('Recent orders'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
                child: _metricCard('Paid sales',
                    'Rs ${paidSales.toStringAsFixed(0)}', 'From your orders')),
            const SizedBox(width: 9),
            Expanded(
                child: _metricCard('Products', '${products.length}',
                    '${products.where((product) => product.stock > 0).length} in stock')),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KeyValueRow(label: 'Orders', value: '${orders.length}'),
              const SizedBox(height: 9),
              _KeyValueRow(
                  label: 'Low stock (5 units or fewer)',
                  value: '$lowStockCount'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Needs your attention',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 11),
              _actionRow(
                  Icons.inventory_2_outlined,
                  '${orders.where((order) => order.status == 'Processing').length} processing orders',
                  'Based on your current order list',
                  'View →',
                  () => _open(AppPage.vendorOrders)),
              if (lowStockCount > 0) ...<Widget>[
                const SizedBox(height: 8),
                _actionRow(
                    Icons.warning_amber_rounded,
                    '$lowStockCount low-stock products',
                    'Five units or fewer in stock',
                    'Manage →',
                    () => _open(AppPage.vendorProducts)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _button('+ Add a product', () => _open(AppPage.addEditProduct)),
      ],
    );
  }

  Widget _actionRow(IconData icon, String title, String subtitle, String action,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: _sand,
            foregroundColor: _muted,
            child: Icon(icon, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(color: _muted, fontSize: 11)),
              ],
            ),
          ),
          Text(action,
              style: const TextStyle(
                  color: _teal, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _vendorProducts() {
    final products = _store.products.values
        .where((product) => product.vendorId == _store.currentUserId)
        .toList();
    return _scroll(
      <Widget>[
        _section('Product catalog',
            action: '+ Add product',
            onAction: () => _open(AppPage.addEditProduct)),
        const SizedBox(height: 10),
        if (products.isEmpty)
          _card(const Text('No products in your catalog yet.'))
        else
          for (final product in products) ...<Widget>[
            _productRow(
              product.name,
              !product.published
                  ? 'Not published'
                  : product.stock == 0
                      ? 'Out of stock'
                      : '${product.stock} units in stock',
              'Rs ${product.price.toStringAsFixed(0)}',
              product: product,
            ),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 12),
        _button('Add a product', () => _open(AppPage.addEditProduct)),
      ],
    );
  }

  Widget _productRow(String title, String status, String price,
      {VaultProduct? product}) {
    return _card(
      Row(
        children: <Widget>[
          const CircleAvatar(
            backgroundColor: _paleTeal,
            foregroundColor: _teal,
            child: Icon(Icons.inventory_2_outlined),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(status,
                    style: const TextStyle(color: _muted, fontSize: 12)),
                Text(price,
                    style: const TextStyle(
                        color: _ink, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (product != null) {
                PetVaultApp.selectedProductId = product.id;
              }
              _open(AppPage.addEditProduct);
            },
            icon: const Icon(Icons.edit_outlined, color: _teal),
          ),
        ],
      ),
    );
  }

  Widget _addEditProduct() {
    final editingProduct = _store.products[PetVaultApp.selectedProductId];
    return _scroll(
      <Widget>[
        _title(editingProduct == null ? 'Add a product' : 'Edit product',
            subtitle: 'Keep your store details up to date.'),
        const SizedBox(height: 15),
        _card(
          const Row(
            children: <Widget>[
              Icon(Icons.add_photo_alternate_outlined, color: _teal, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text('Add a product image URL',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
        const SizedBox(height: 13),
        _field('Product name',
            hint: 'Product name', controller: _productNameController),
        const SizedBox(height: 12),
        _field('Price (PKR)',
            hint: 'Price in PKR',
            controller: _productPriceController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _field('Inventory',
            hint: 'Available units',
            controller: _productStockController,
            keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _field('Image URL (optional)',
            hint: 'https://example.com/product.jpg',
            controller: _productImageController,
            keyboardType: TextInputType.url),
        const SizedBox(height: 14),
        _button('Save product', () async {
          final price = double.tryParse(_productPriceController.text.trim());
          final stock = int.tryParse(_productStockController.text.trim());
          final imageUrl = _productImageController.text.trim();
          if (price == null ||
              stock == null ||
              (imageUrl.isNotEmpty &&
                  !const <String>['http', 'https']
                      .contains(Uri.tryParse(imageUrl)?.scheme))) {
            _toast('Enter a valid price, stock quantity, and HTTPS image URL.');
            return;
          }
          try {
            await _api.saveProduct(
              id: editingProduct?.id,
              name: _productNameController.text.trim(),
              price: price,
              stock: stock,
              imageUrl: imageUrl,
            );
            await _loadRemoteProducts();
            if (mounted) {
              _toast('Product saved to your catalog.');
              _switchTab(AppPage.vendorProducts);
            }
          } on PetVaultApiException catch (error) {
            _showApiError(error);
          }
        }),
      ],
    );
  }

  Widget _vendorOrders() {
    final orders = _store.visibleOrders.reversed.toList();
    return _scroll(
      <Widget>[
        _title('Order management', subtitle: '${orders.length} order(s)'),
        const SizedBox(height: 13),
        Wrap(
          spacing: 7,
          children: <Widget>[
            _pill('All'),
            _pill('To ship', color: _sand, textColor: _muted),
            _pill('In transit', color: _sand, textColor: _muted),
            _pill('Complete', color: _sand, textColor: _muted),
          ],
        ),
        const SizedBox(height: 13),
        if (orders.isEmpty)
          _card(const Text(
              'No customer orders are assigned to your vendor account yet.'))
        else
          for (final order in orders) ...<Widget>[
            _orderCard(
              order.id,
              order.productIds
                  .map((id) => _store.products[id]?.name ?? id)
                  .join(', '),
              order.status,
              'Rs ${order.total.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 9),
          ],
      ],
    );
  }

  Widget _orderCard(String id, String item, String status, String total) {
    return InkWell(
      onTap: () {
        PetVaultApp.selectedOrderId = id;
        _open(AppPage.vendorOrderDetail);
      },
      borderRadius: BorderRadius.circular(18),
      child: _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(id,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text(total,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 5),
            Text(item, style: const TextStyle(color: _muted)),
            const SizedBox(height: 8),
            _pill(status),
          ],
        ),
      ),
    );
  }

  Widget _vendorOrderDetail() {
    final matches = _store.visibleOrders
        .where((item) => item.id == PetVaultApp.selectedOrderId)
        .toList();
    final order = matches.isEmpty ? null : matches.first;
    if (order == null) {
      return _scroll(<Widget>[
        _title('Order details'),
        const Text('The selected order could not be found.'),
      ]);
    }
    return _scroll(
      <Widget>[
        _title('Order ${order.id}',
            subtitle: 'Placed ${order.createdAt.toLocal()}'),
        const SizedBox(height: 14),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KeyValueRow(label: 'Status', value: order.status),
              const SizedBox(height: 9),
              _KeyValueRow(
                  label: 'Payment status', value: order.paymentStatus.name),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0;
            index < order.productIds.length;
            index++) ...<Widget>[
          _productRow(
            _store.products[order.productIds[index]]?.name ??
                order.productIds[index],
            'Quantity · ${order.quantities[index]}',
            'Rs ${((_store.products[order.productIds[index]]?.price ?? 0) * order.quantities[index]).toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        _card(const Text(
            'Delivery address is not collected by this application.')),
        const SizedBox(height: 14),
        if (order.status == 'Processing')
          _button('Mark shipped',
              () => _updateRemoteOrderStatus(order.id, 'Shipped')),
        if (order.status == 'Shipped')
          _button('Mark delivered',
              () => _updateRemoteOrderStatus(order.id, 'Delivered')),
        const SizedBox(height: 8),
        _button(
            'Buyer messaging unavailable',
            () => _toast(
                'Buyer messaging is not connected to a messaging service.'),
            primary: false),
      ],
    );
  }

  Widget _sitters() {
    return _scroll(
      <Widget>[
        _title('Trusted pet sitters',
            subtitle: 'Browse sitters approved by PetVault verification.'),
        const SizedBox(height: 14),
        if (_remoteSitters.isEmpty)
          _card(const Text('No verified sitters are currently listed.'))
        else
          for (final sitter in _remoteSitters) ...<Widget>[
            _sitterCard(sitter),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        _button('View my bookings', () => _open(AppPage.bookingCalendar),
            primary: false),
      ],
    );
  }

  Widget _sitterCard(Map<String, dynamic> sitter) {
    final name = sitter['displayName'] as String? ?? 'Pet sitter';
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                backgroundColor: _paleTeal,
                foregroundColor: _teal,
                child: Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Text('PetVault role verification approved',
                        style: TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
              _pill('Verified'),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Care services and pricing are arranged directly with the sitter.',
            style: TextStyle(color: _muted),
          ),
          Row(
            children: <Widget>[
              const Spacer(),
              TextButton(
                onPressed: () {
                  _selectedSitter = name;
                  _selectedSitterId = sitter['id'] as String? ?? '';
                  _open(AppPage.bookingCalendar);
                },
                child: const Text('Book →'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookingCalendar() {
    return _scroll(
      <Widget>[
        _title('Bookings & calendar',
            subtitle: 'Select a date and send a care request.'),
        const SizedBox(height: 14),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                  _selectedSitter.isEmpty
                      ? 'Select a sitter from the directory'
                      : 'Sitter: $_selectedSitter',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (_store.activeRole == PetVaultRole.owner &&
                  _store.ownerPets.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _store.pets.containsKey(_selectedPetId)
                      ? _selectedPetId
                      : _store.ownerPets.first.id,
                  decoration: const InputDecoration(labelText: 'Pet'),
                  items: _store.ownerPets
                      .map((pet) => DropdownMenuItem<String>(
                            value: pet.id,
                            child: Text(pet.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPetId = value);
                  },
                ),
              ],
              const SizedBox(height: 8),
              Text(
                  'Selected date: ${_selectedDate.toLocal().toString().split(' ').first}'),
              const SizedBox(height: 8),
              _button('Choose date', () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null && mounted) {
                  setState(() => _selectedDate = date);
                }
              }, primary: false),
              const SizedBox(height: 8),
              _field('Care instructions',
                  hint: 'Food, medication, routine, and access notes',
                  controller: _bookingInstructionsController),
              const SizedBox(height: 8),
              _field('Emergency contact name',
                  controller: _emergencyNameController),
              const SizedBox(height: 8),
              _field('Emergency contact phone',
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _button('Request sitting', () async {
                final petId = _store.pets.containsKey(_selectedPetId)
                    ? _selectedPetId
                    : _store.ownerPets.firstOrNull?.id;
                if (petId == null || _selectedSitterId.isEmpty) {
                  _toast('Choose a pet and a verified sitter first.');
                  return;
                }
                final startsAt = DateTime(_selectedDate.year,
                    _selectedDate.month, _selectedDate.day, 9);
                try {
                  await _api.createBooking(
                    sitterId: _selectedSitterId,
                    petId: petId,
                    startsAt: startsAt,
                    endsAt: startsAt.add(const Duration(hours: 1)),
                    arrangement: 'In-home visit',
                    instructions: _bookingInstructionsController.text,
                    emergencyName: _emergencyNameController.text,
                    emergencyPhone: _emergencyPhoneController.text,
                  );
                  await _loadRemoteBookings();
                  if (mounted) {
                    _toast('Booking request sent to $_selectedSitter.');
                  }
                } on PetVaultApiException catch (error) {
                  _showApiError(error);
                }
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _section('Upcoming bookings'),
        const SizedBox(height: 8),
        if (_remoteBookings.isEmpty)
          const Text('No sitting requests or bookings yet.')
        else
          for (final booking in _remoteBookings.reversed) ...<Widget>[
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${booking['petName']} · ${booking['status']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${booking['startsAt']} · ${booking['arrangement']}'),
                  Text('Emergency: ${booking['emergencyName']}',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                  if (_store.activeRole == PetVaultRole.sitter &&
                      booking['status'] == 'requested') ...<Widget>[
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _button('Accept', () async {
                            try {
                              await _api.updateBookingStatus(
                                  booking['id'] as String, 'confirmed');
                              await _loadRemoteBookings();
                            } on PetVaultApiException catch (error) {
                              _showApiError(error);
                            }
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _button('Decline', () async {
                            try {
                              await _api.updateBookingStatus(
                                  booking['id'] as String, 'declined');
                              await _loadRemoteBookings();
                            } on PetVaultApiException catch (error) {
                              _showApiError(error);
                            }
                          }, primary: false),
                        ),
                      ],
                    ),
                  ],
                  if (_store.activeRole == PetVaultRole.owner &&
                      booking['status'] == 'confirmed')
                    _button('Cancel booking', () async {
                      try {
                        await _api.updateBookingStatus(
                            booking['id'] as String, 'cancelled');
                        await _loadRemoteBookings();
                      } on PetVaultApiException catch (error) {
                        _showApiError(error);
                      }
                    }, primary: false),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 13),
        if (_remoteBookings.any((booking) => booking['status'] == 'confirmed'))
          _button('View active sitting', () => _open(AppPage.activeSitting)),
      ],
    );
  }

  Widget _activeSitting() {
    final active = _remoteBookings
        .where((booking) => booking['status'] == 'confirmed')
        .toList();
    return _scroll(
      <Widget>[
        _title('Active sitting',
            subtitle: 'Confirmed bookings and booking status.'),
        if (active.isEmpty)
          _card(const Text('No confirmed sitting bookings.'))
        else
          for (final booking in active) ...<Widget>[
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${booking['petName']} · ${booking['arrangement']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text('${booking['startsAt']} · ${booking['status']}'),
                  if (_store.activeRole == PetVaultRole.sitter)
                    Text(
                        'Emergency contact: ${booking['emergencyName']} · ${booking['emergencyPhone']}'),
                  Text('Care instructions: ${booking['instructions']}'),
                  if (_store.activeRole == PetVaultRole.sitter) ...<Widget>[
                    _button('Complete booking', () async {
                      try {
                        await _api.updateBookingStatus(
                            booking['id'] as String, 'complete');
                        await _loadRemoteBookings();
                      } on PetVaultApiException catch (error) {
                        _showApiError(error);
                      }
                    }, primary: false),
                  ] else
                    _button('Cancel booking', () async {
                      try {
                        await _api.updateBookingStatus(
                            booking['id'] as String, 'cancelled');
                        await _loadRemoteBookings();
                      } on PetVaultApiException catch (error) {
                        _showApiError(error);
                      }
                    }, primary: false),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _adminDashboard() {
    final riskFlagCount = _remoteModerationListings.where((listing) {
      final score = num.tryParse(listing['riskScore']?.toString() ?? '') ?? 0;
      final reportCount =
          num.tryParse(listing['openReportCount']?.toString() ?? '') ?? 0;
      return score >= 35 || reportCount > 0;
    }).length;
    return _scroll(
      <Widget>[
        _title(
          'Trust & safety',
          subtitle:
              'Admin dashboard · ${DateTime.now().toLocal().toString().split(' ').first}',
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
                child: _metricCard(
                    'KYC queue', '${_remoteKyc.length}', 'Awaiting review')),
            const SizedBox(width: 9),
            Expanded(
                child: _metricCard('Risk flags', '$riskFlagCount', 'Listings')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
                child: _metricCard('Published listings',
                    '${_store.activeListings.length}', 'Current catalog')),
            const SizedBox(width: 9),
            Expanded(
                child: _metricCard(
                    'Open moderation',
                    '${_remoteModerationListings.length}',
                    'Listings and reports')),
          ],
        ),
        const SizedBox(height: 15),
        _section('Needs attention'),
        const SizedBox(height: 8),
        _actionRow(
            Icons.verified_user_outlined,
            'Identity review queue',
            '${_remoteKyc.length} submissions waiting',
            'Open →',
            () => _open(AppPage.kycQueue)),
        const SizedBox(height: 9),
        _actionRow(
            Icons.warning_amber_rounded,
            'Listing risk signals',
            '$riskFlagCount listing(s) flagged for human review',
            'Review →',
            () => _open(AppPage.riskQueue)),
        const SizedBox(height: 14),
        _button('Open audit trail', () => _open(AppPage.auditTrail),
            primary: false),
      ],
    );
  }

  Widget _kycQueue() {
    return _scroll(
      <Widget>[
        _title('KYC verification queue',
            subtitle: '${_remoteKyc.length} item(s) waiting for review'),
        const SizedBox(height: 12),
        if (_remoteKyc.isEmpty)
          _card(const Text('No identity submissions need review.'))
        else
          for (final entry in _remoteKyc) ...<Widget>[
            _card(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: _paleTeal,
                  foregroundColor: _teal,
                  child: Icon(Icons.person_outline_rounded),
                ),
                title: Text(entry['displayName'] as String? ?? 'Applicant'),
                subtitle: Text(
                    '${entry['email']} · ${entry['role']} · ${entry['documentReference']}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  PetVaultApp.selectedKycUserId = entry['id'] as String;
                  _open(AppPage.identityApproval);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _identityApproval() {
    final submission = _remoteKyc
        .where((entry) => entry['id'] == PetVaultApp.selectedKycUserId)
        .firstOrNull;
    if (submission == null) {
      return _scroll(<Widget>[
        _title('Identity review'),
        const Text('Select a pending submission from the review queue.'),
        _button('Back to queue', () => _open(AppPage.kycQueue)),
      ]);
    }
    return _scroll(
      <Widget>[
        _pill('Identity review · ${submission['role']}'),
        const SizedBox(height: 11),
        _title(submission['displayName'] as String? ?? 'Applicant',
            subtitle: submission['email'] as String? ?? ''),
        const SizedBox(height: 13),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _KeyValueRow(
                  label: 'Account email',
                  value: submission['email'] as String? ?? ''),
              const SizedBox(height: 9),
              _KeyValueRow(
                  label: 'Requested role',
                  value: submission['role'] as String? ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Submitted verification reference',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              _KeyValueRow(
                  label: 'Reference',
                  value: submission['documentReference'] as String? ?? ''),
              SizedBox(height: 6),
              Text(
                  'Identity files are not uploaded or verified by this service. Confirm documents outside the app before approving.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _field('Review note', controller: _reviewController),
        const SizedBox(height: 10),
        _button('Approve role verification', () async {
          try {
            await _api.reviewKyc(
              submissionId: submission['id'] as String,
              status: 'verified',
              reviewNote: _reviewController.text,
            );
            await _loadRemoteKycQueue();
            if (mounted) _toast('Role verification approved.');
          } on PetVaultApiException catch (error) {
            _showApiError(error);
          }
        }),
        const SizedBox(height: 8),
        _button('Reject submission', () async {
          try {
            await _api.reviewKyc(
              submissionId: submission['id'] as String,
              status: 'rejected',
              reviewNote: _reviewController.text,
            );
            await _loadRemoteKycQueue();
            if (mounted) _toast('Verification submission rejected.');
          } on PetVaultApiException catch (error) {
            _showApiError(error);
          }
        }, primary: false),
      ],
    );
  }

  Widget _riskQueue() {
    final reports = _store.reportsPendingReview;
    final remoteFlags = _remoteModerationListings.where((listing) {
      final score = num.tryParse(listing['riskScore']?.toString() ?? '') ?? 0;
      final reportCount =
          num.tryParse(listing['openReportCount']?.toString() ?? '') ?? 0;
      return score >= 35 || reportCount > 0;
    }).toList();
    return _scroll(
      <Widget>[
        _title('Trust & safety reports',
            subtitle:
                '${remoteFlags.length} risk flag(s) · ${reports.length} local report(s)'),
        const SizedBox(height: 12),
        if (_api.isAuthenticated && !_remoteModerationLoaded)
          const Center(child: CircularProgressIndicator(color: _teal)),
        if (reports.isEmpty && remoteFlags.isEmpty)
          _card(const Text(
              'No high-priority signals or user reports are awaiting review. Risk scores support human review and are not proof of fraud.'))
        else ...<Widget>[
          for (final listing in remoteFlags) ...<Widget>[
            _remoteModerationCard(listing),
            const SizedBox(height: 9),
          ],
          for (final report in reports) ...<Widget>[
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      _store.listings[report.listingId]?.title ??
                          report.listingId,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(report.reason),
                  Text('Submitted ${report.createdAt.toLocal()}',
                      style: const TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 8),
                  _button('Mark reviewed', () {
                    _showStoreResult(
                      _store.resolveListingReport(report.id),
                      successMessage: 'Report marked reviewed.',
                    );
                  }),
                  const SizedBox(height: 7),
                  _button('Open listing moderation',
                      () => _open(AppPage.listingModeration),
                      primary: false),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
        ],
      ],
    );
  }

  Widget _remoteModerationCard(Map<String, dynamic> listing) {
    final title = listing['title']?.toString() ?? 'Untitled listing';
    final score = num.tryParse(listing['riskScore']?.toString() ?? '') ?? 0;
    final factors = listing['riskFactors'];
    final List<Widget> factorWidgets = factors is List
        ? factors
            .map<Widget>((factor) => Text(
                  '• ${factor.toString()}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ))
            .toList()
        : <Widget>[];
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              _pill(
                'Risk ${score.toInt()}/100 · ${listing['riskLevel'] ?? 'low'}',
                color: score >= 60 ? const Color(0xFFFFE6E0) : _sand,
                textColor: score >= 60 ? const Color(0xFF9A3525) : _muted,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${listing['species'] ?? ''} · ${listing['breed'] ?? ''} · ${listing['city'] ?? ''} · ${listing['sellerName'] ?? listing['sellerId'] ?? ''}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          if (factorWidgets.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            ...factorWidgets,
          ],
          const SizedBox(height: 8),
          const Text(
            'Automated decision-support only. Review the listing and evidence before acting.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 9),
          _button(
              'Open listing moderation', () => _open(AppPage.listingModeration),
              primary: false),
        ],
      ),
    );
  }

  Widget _listingModeration() {
    final queue = _store.listingsPendingReview;
    final remotePending = _remoteModerationListings.where((listing) {
      final reportCount =
          num.tryParse(listing['openReportCount']?.toString() ?? '') ?? 0;
      return listing['status'] == 'pending_review' || reportCount > 0;
    }).toList();
    return _scroll(
      <Widget>[
        _title('Listing moderation',
            subtitle:
                '${queue.length + remotePending.length} listing(s) awaiting a decision'),
        const SizedBox(height: 13),
        if (_api.isAuthenticated && !_remoteModerationLoaded)
          const Center(child: CircularProgressIndicator(color: _teal)),
        if (queue.isEmpty && remotePending.isEmpty)
          _card(const Text('No listings are waiting for moderation.'))
        else ...<Widget>[
          for (final listing in remotePending) ...<Widget>[
            _remoteListingReviewCard(listing),
            const SizedBox(height: 10),
          ],
          for (final listing in queue) ...<Widget>[
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _photo(listing.image,
                      height: 170, width: double.infinity, radius: 14),
                  const SizedBox(height: 9),
                  Text(listing.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(
                    '${listing.species} · ${listing.breed} · ${listing.city} · ${listing.sellerId}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  if (listing.healthNotes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 7),
                    Text('Health disclosure: ${listing.healthNotes}'),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _button('Approve', () {
                          _showStoreResult(
                            _store.reviewListing(
                                listing.id, ListingStatus.active),
                            successMessage: 'Listing approved and published.',
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _button('Reject', () {
                          _showStoreResult(
                            _store.reviewListing(
                                listing.id, ListingStatus.rejected),
                            successMessage: 'Listing rejected.',
                          );
                        }, primary: false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _remoteListingReviewCard(Map<String, dynamic> listing) {
    final price = num.tryParse(listing['price']?.toString() ?? '') ?? 0;
    final score = num.tryParse(listing['riskScore']?.toString() ?? '') ?? 0;
    final factors = listing['riskFactors'];
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              color: _paleTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.pets_outlined, color: _teal, size: 38),
          ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  listing['title']?.toString() ?? 'Untitled listing',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              _pill(
                'Risk ${score.toInt()}/100',
                color: score >= 60 ? const Color(0xFFFFE6E0) : _sand,
                textColor: score >= 60 ? const Color(0xFF9A3525) : _muted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${listing['species'] ?? ''} · ${listing['breed'] ?? ''} · ${listing['city'] ?? ''} · ${listing['sellerName'] ?? listing['sellerId'] ?? ''}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          Text(
            'Status: ${listing['status'] ?? 'unknown'} · Open reports: ${listing['openReportCount'] ?? 0}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          Text('PKR ${price.toStringAsFixed(0)} · ${listing['age'] ?? ''}'),
          if ((listing['healthNotes']?.toString() ?? '')
              .isNotEmpty) ...<Widget>[
            const SizedBox(height: 7),
            Text('Health disclosure: ${listing['healthNotes']}'),
          ],
          if (factors is List && factors.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            for (final factor in factors)
              Text('• $factor',
                  style: const TextStyle(color: _muted, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          const Text(
            'Risk score is an explainable screening signal, not proof of fraud. Human review is required.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _button(
                  'Approve',
                  () => _moderateRemoteListing(listing, 'active'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _button(
                  'Reject',
                  () => _moderateRemoteListing(listing, 'rejected'),
                  primary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _disputes() {
    final cases = _store.openDisputes.toList(growable: false);
    return _scroll(
      <Widget>[
        _title('Disputes & cancellations',
            subtitle: '${cases.length} open case(s)'),
        const SizedBox(height: 13),
        if (cases.isEmpty)
          _card(const Text('No open disputes.'))
        else
          for (final transactionId in cases) ...<Widget>[
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(transactionId,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  const Text(
                      'Review the available transaction details before choosing a resolution.',
                      style: TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 12),
                  for (final decision in <String>[
                    'Refund buyer',
                    'Release payment',
                    'Request more information',
                  ])
                    TextButton(
                      onPressed: () => _showStoreResult(
                        _store.resolveDispute(transactionId, decision),
                        successMessage: 'Dispute resolved: $decision.',
                      ),
                      child: Text(decision),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
      ],
    );
  }

  Widget _auditTrail() {
    final entries = _store.auditTrail;
    return _scroll(
      <Widget>[
        _title('Audit trail',
            subtitle: 'A chronological record of trust and safety actions.'),
        const SizedBox(height: 13),
        _field('Search events', hint: 'User, listing, or action'),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          _card(const Text('No audit events recorded yet.'))
        else
          for (final entry in entries)
            _timelineItem(
              entry.action,
              '${entry.actor} · ${entry.record} · ${entry.createdAt.toLocal()}',
            ),
        const SizedBox(height: 10),
        _button('Export audit records',
            () => _toast('Audit export prepared securely.'),
            primary: false),
      ],
    );
  }

  Widget _timelineItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.circle, size: 10, color: _teal),
          const SizedBox(width: 11),
          Expanded(
            child: _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _muted, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userSettings() {
    return _scroll(
      <Widget>[
        _card(
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 28,
                backgroundColor: _paleTeal,
                foregroundColor: _teal,
                child: Icon(Icons.person_outline_rounded, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_store.currentUserName,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(_store.currentEmail,
                        style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.verified_user_outlined, color: _teal),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _section('Account'),
        const SizedBox(height: 8),
        _settingsRow(Icons.person_outline, 'Personal information',
            () => _toast('Personal information settings')),
        _settingsRow(Icons.pets_outlined, 'Pet profiles',
            () => _switchTab(AppPage.pets)),
        _settingsRow(Icons.privacy_tip_outlined, 'Data & privacy',
            () => _open(AppPage.dataPrivacy)),
        _settingsRow(Icons.notifications_none, 'Notifications',
            () => _open(AppPage.notifications)),
        _settingsRow(Icons.support_agent_outlined, 'Pet care assistant',
            () => _open(AppPage.aiSupport)),
        const SizedBox(height: 12),
        _button('Sign out', () {
          _store.signOut();
          _api.signOut();
          _switchTab(AppPage.authentication);
        }, primary: false),
      ],
    );
  }

  Widget _settingsRow(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _sand,
        foregroundColor: _muted,
        child: Icon(icon, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
      onTap: onTap,
    );
  }

  Widget _dataPrivacy() {
    return _scroll(
      <Widget>[
        _title('Your data, your choices',
            subtitle:
                'Per-record access is managed separately; these preference toggles are session-only.'),
        const SizedBox(height: 13),
        _card(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Record sharing',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 5),
              Text(
                'Health records are private by default. You can share selected records for a limited time.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: _teal,
          value: _requireShareConsent,
          title: const Text('Require consent before sharing'),
          subtitle: const Text('Recommended for health records'),
          onChanged: (value) {
            setState(() => _requireShareConsent = value);
            _store.updatePrivacyPreferences(
              requireConsent: value,
              allowSitterFullRecords: _allowSitterFullRecords,
            );
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: _teal,
          value: _allowSitterFullRecords,
          title: const Text('Allow sitter access to full records'),
          subtitle: const Text('You can share care essentials instead'),
          onChanged: (value) {
            setState(() => _allowSitterFullRecords = value);
            _store.updatePrivacyPreferences(
              requireConsent: _requireShareConsent,
              allowSitterFullRecords: value,
            );
          },
        ),
        const SizedBox(height: 10),
        _settingsRow(Icons.group_outlined, 'Manage pet access',
            () => _open(AppPage.healthRecords)),
        _settingsRow(
            Icons.download_outlined,
            'Download my data',
            () => _toast(
                'Local data export is not implemented; no file was created.')),
        _settingsRow(
            Icons.delete_outline,
            'Account deletion unavailable',
            () => _toast(
                'Account deletion is not implemented by the backend. Contact support for account assistance.')),
      ],
    );
  }

  Widget _notifications() {
    return _scroll(
      <Widget>[
        _title('Notifications',
            subtitle:
                'Notification preferences are session-only; delivery is not configured.'),
        const SizedBox(height: 12),
        _card(
          Column(
            children: <Widget>[
              _notificationRow(
                  'Care reminders', 'Vaccines and vet visits', true),
              const Divider(color: _line),
              _notificationRow(
                  'Messages', 'Buyer, seller, and sitter messages', true),
              const Divider(color: _line),
              _notificationRow(
                  'Marketplace updates', 'Saved listings and replies', true),
              const Divider(color: _line),
              _notificationRow(
                  'Pet essentials', 'Orders and delivery updates', false),
            ],
          ),
        ),
        const SizedBox(height: 13),
        _section('Recent activity'),
        const SizedBox(height: 8),
        if (!_api.isAuthenticated)
          const Text('Sign in to view account notifications.')
        else if (_remoteNotifications.isEmpty)
          const Text('No notifications yet.')
        else
          for (final notification in _remoteNotifications.take(8))
            if (notification['id'] is String &&
                notification['title'] is String &&
                notification['body'] is String) ...<Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  notification['readAt'] != null
                      ? Icons.notifications_none
                      : Icons.notifications_active_outlined,
                  color: _teal,
                ),
                title: Text(notification['title'] as String),
                subtitle: Text(notification['body'] as String),
                trailing: notification['readAt'] != null
                    ? null
                    : TextButton(
                        onPressed: () => _markRemoteNotificationRead(
                            notification['id'] as String),
                        child: const Text('Read'),
                      ),
              ),
            ],
        _button('Save preferences',
            () => _toast('Notification preferences saved locally.')),
      ],
    );
  }

  Widget _notificationRow(String title, String subtitle, bool initialValue) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: _teal,
      value: _notificationSettings[title] ?? initialValue,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
      onChanged: (value) =>
          setState(() => _notificationSettings[title] = value),
    );
  }

  Widget _aiSupport() {
    return _scroll(
      <Widget>[
        _card(
          const Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: _paleTeal,
                foregroundColor: _teal,
                child: Icon(Icons.auto_awesome_outlined),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A grounded guide for everyday pet care.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          color: _paleTeal,
        ),
        const SizedBox(height: 14),
        _title('How can I help?',
            subtitle: 'Share a question, or choose a topic to get started.'),
        const SizedBox(height: 13),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: <Widget>[
            _quickLink('Nutrition', Icons.restaurant_outlined,
                () => _toast('Tell me your pet’s age and dietary question.')),
            _quickLink('Behavior', Icons.psychology_outlined,
                () => _toast('Share what changed and when it started.')),
            _quickLink('Health records', Icons.folder_outlined,
                () => _open(AppPage.healthRecords)),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          const Text(
            'I can help organize information, but I can’t diagnose or replace a veterinarian. If symptoms are sudden or severe, contact a clinic now.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _field('Ask a pet care question',
            hint: 'What would you like to know?',
            controller: _supportController),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Simulate support service unavailable'),
          value: !_supportServiceAvailable,
          onChanged: (value) =>
              setState(() => _supportServiceAvailable = !value),
        ),
        _button('Send question', () {
          setState(() {
            _supportResponse = _store.groundedSupportAnswer(
              _supportController.text,
              serviceAvailable: _supportServiceAvailable,
            );
          });
          if (_supportController.text.trim().isEmpty) {
            _toast('Enter a question first.');
          }
        }, icon: Icons.send_rounded),
        if (_supportResponse != null) ...<Widget>[
          const SizedBox(height: 12),
          _card(Text(_supportResponse!,
              style: const TextStyle(color: _ink, height: 1.4))),
        ],
        const SizedBox(height: 9),
        _button('Urgent symptom guidance', () => _open(AppPage.triageAlert),
            primary: false),
      ],
    );
  }

  Widget _triageAlert() {
    return _scroll(
      <Widget>[
        _card(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFB54D36), size: 32),
              SizedBox(height: 9),
              Text('Seek urgent veterinary help',
                  style: TextStyle(
                      color: _ink, fontWeight: FontWeight.w700, fontSize: 19)),
              SizedBox(height: 6),
              Text(
                'Trouble breathing, collapse, uncontrolled bleeding, seizures, or suspected poisoning can be emergencies.',
                style: TextStyle(color: _muted, height: 1.4),
              ),
            ],
          ),
          color: const Color(0xFFFFF0E9),
        ),
        const SizedBox(height: 14),
        _title('What to do now'),
        const SizedBox(height: 9),
        _timelineItem('Contact a local veterinary clinic',
            'Call ahead and follow the clinic’s instructions.'),
        _timelineItem('Keep your pet safe and calm',
            'Do not give medication unless a veterinarian directs you.'),
        _timelineItem('Bring relevant records',
            'Share only the health information the clinic needs.'),
        const SizedBox(height: 7),
        _field('Describe the symptoms',
            hint: 'Use your own words',
            controller: _triageController,
            maxLines: 3),
        const SizedBox(height: 10),
        _button('Get care-routing guidance', () {
          if (_triageController.text.trim().isEmpty) {
            _toast('Describe the symptoms first.');
            return;
          }
          setState(
              () => _triageResponse = _store.triage(_triageController.text));
        }),
        if (_triageResponse != null) ...<Widget>[
          const SizedBox(height: 10),
          _card(Text(_triageResponse!,
              style: const TextStyle(color: _ink, height: 1.4))),
        ],
        const SizedBox(height: 8),
        _button('Find a veterinarian', () => _open(AppPage.vetDirectory),
            primary: false),
        const SizedBox(height: 8),
        const Text(
          'This guidance is not a diagnosis. If you are unsure, contact a veterinarian.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(label, style: const TextStyle(color: _muted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
