import 'package:flutter/foundation.dart';

enum PetVaultRole { owner, seller, sitter, veterinarian, vendor, admin }

enum KycStatus {
  notSubmitted,
  pending,
  verified,
  rejected,
  pendingReview,
  serviceUnavailable
}

enum ListingStatus { draft, pendingReview, active, rejected, sold }

enum BookingStatus { requested, confirmed, declined, cancelled, complete }

enum PaymentStatus { pending, paid, failed, refundPending, refunded }

enum TransactionStatus {
  offer,
  confirmed,
  paymentHeld,
  handoverConfirmed,
  complete,
  disputed,
  cancelled,
}

class PetProfile {
  PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.sex,
    required this.weightKg,
    this.microchip = '',
    this.ownerId = 'owner@petvault.demo',
  });

  final String id;
  String name;
  String species;
  String breed;
  String age;
  String sex;
  double weightKg;
  String microchip;
  String ownerId;
  final List<VaccinationEntry> vaccinations = <VaccinationEntry>[];
  final List<HealthRecord> records = <HealthRecord>[];
  final Map<String, Set<String>> access = <String, Set<String>>{};
}

class VaccinationEntry {
  VaccinationEntry({
    required this.id,
    required this.name,
    required this.givenAt,
    required this.nextDueAt,
    required this.provider,
  });

  final String id;
  final String name;
  final DateTime givenAt;
  final DateTime? nextDueAt;
  final String provider;

  String statusAt(DateTime now) {
    final due = nextDueAt;
    if (due == null) return 'No booster required';
    if (due.isBefore(now)) return 'Overdue';
    if (due.difference(now).inDays <= 14) return 'Due soon';
    return 'Up to date';
  }
}

class HealthRecord {
  HealthRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.provider,
    this.nextDueAt,
    this.vetName,
    this.attachmentName,
    this.attachmentSizeBytes,
    this.attachmentBytes,
  });

  final String id;
  String title;
  String type;
  DateTime date;
  String provider;
  DateTime? nextDueAt;
  String? vetName;
  String? attachmentName;
  int? attachmentSizeBytes;
  Uint8List? attachmentBytes;
}

class PetListing {
  PetListing({
    required this.id,
    required this.title,
    required this.species,
    required this.breed,
    required this.city,
    required this.price,
    required this.age,
    required this.sellerId,
    required this.image,
    this.sellerName = '',
    this.verifiedSeller = true,
    this.healthNotes = '',
    this.status = ListingStatus.active,
  });

  final String id;
  String title;
  String species;
  String breed;
  String city;
  double price;
  String age;
  String sellerId;
  String sellerName;
  final String image;
  bool verifiedSeller;
  String healthNotes;
  ListingStatus status;
  final Set<String> favorites = <String>{};
}

class VaultProduct {
  VaultProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.image,
    this.vendorId = 'vendor@petvault.demo',
    this.vendorName = '',
    this.vendorVerified = true,
    this.published = true,
    this.variant = 'Standard',
  });

  final String id;
  String name;
  double price;
  int stock;
  final String image;
  String vendorId;
  String vendorName;
  bool vendorVerified;
  bool published;
  String variant;
}

class VaultOrder {
  VaultOrder({
    required this.id,
    required this.productIds,
    required this.quantities,
    required this.total,
    required this.createdAt,
    required this.buyerId,
  });

  final String id;
  final List<String> productIds;
  final List<int> quantities;
  final double total;
  final DateTime createdAt;
  String buyerId;
  String status = 'Processing';
  PaymentStatus paymentStatus = PaymentStatus.pending;
  bool reviewed = false;
}

class SittingBooking {
  SittingBooking({
    required this.id,
    required this.sitter,
    required this.date,
    required this.arrangement,
    required this.instructions,
    required this.emergencyName,
    required this.emergencyPhone,
    required this.ownerId,
  });

  final String id;
  String sitter;
  final DateTime date;
  final String arrangement;
  final String instructions;
  final String emergencyName;
  final String emergencyPhone;
  String ownerId;
  BookingStatus status = BookingStatus.requested;
  final List<String> updates = <String>[];
  bool reviewed = false;

  bool get active =>
      status == BookingStatus.confirmed || status == BookingStatus.requested;
}

class PetVisitRequest {
  PetVisitRequest({
    required this.id,
    required this.listingId,
    required this.ownerId,
    required this.date,
    required this.message,
  });

  final String id;
  final String listingId;
  String ownerId;
  final DateTime date;
  final String message;
  String status = 'Requested';
}

class VetAppointment {
  VetAppointment({
    required this.id,
    required this.vet,
    required this.petId,
    required this.slot,
    required this.type,
    required this.ownerId,
  });

  final String id;
  final String vet;
  final String petId;
  final DateTime slot;
  final String type;
  String ownerId;
  String status = 'Confirmed';
  String? consultationNotes;
  bool reviewed = false;
}

class VaultNotification {
  VaultNotification({
    required this.title,
    required this.message,
    required this.createdAt,
    required this.recipientId,
  });

  final String title;
  final String message;
  final DateTime createdAt;
  final String recipientId;
  bool read = false;
}

class PetVaultMessage {
  PetVaultMessage({
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  String sender;
  final String text;
  final DateTime createdAt;
}

class AuditEntry {
  AuditEntry({
    required this.actor,
    required this.action,
    required this.record,
    required this.createdAt,
  });

  String actor;
  final String action;
  final String record;
  final DateTime createdAt;
}

class ShareGrant {
  ShareGrant({
    required this.recipient,
    required this.sections,
    required this.expiresAt,
  });

  final String recipient;
  final Set<String> sections;
  final DateTime? expiresAt;
  bool active = true;
}

class ReviewRecord {
  ReviewRecord({
    required this.author,
    required this.subjectId,
    required this.rating,
    required this.comment,
  });

  String author;
  final String subjectId;
  final int rating;
  final String comment;
  bool reported = false;
}

class ListingReport {
  ListingReport({
    required this.id,
    required this.listingId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  String reporterId;
  final String reason;
  final DateTime createdAt;
  bool resolved = false;
}

class PetVaultStore extends ChangeNotifier {
  PetVaultStore({
    DateTime Function()? clock,
    bool seedDemoData = true,
  }) : _clock = clock ?? DateTime.now {
    if (seedDemoData) {
      currentUserId = 'owner@petvault.demo';
      _seedDemoData();
    }
  }

  final DateTime Function() _clock;
  final Map<String, _DemoAccount> _accounts = <String, _DemoAccount>{};
  final Map<String, PetProfile> pets = <String, PetProfile>{};
  final Map<String, PetListing> listings = <String, PetListing>{};
  final Map<String, VaultProduct> products = <String, VaultProduct>{};
  final List<VaultOrder> orders = <VaultOrder>[];
  final List<SittingBooking> bookings = <SittingBooking>[];
  final List<PetVisitRequest> visitRequests = <PetVisitRequest>[];
  final List<VetAppointment> appointments = <VetAppointment>[];
  final List<VaultNotification> notifications = <VaultNotification>[];
  final Map<String, List<PetVaultMessage>> conversations =
      <String, List<PetVaultMessage>>{};
  final List<AuditEntry> audit = <AuditEntry>[];
  final List<ReviewRecord> reviews = <ReviewRecord>[];
  final List<ListingReport> listingReports = <ListingReport>[];
  final Set<String> openDisputes = <String>{};
  final Map<String, Set<String>> disputeOwners = <String, Set<String>>{};
  final Map<String, int> cart = <String, int>{};
  final Map<String, KycStatus> kyc = <String, KycStatus>{};
  final Map<String, Set<PetVaultRole>> _roles = <String, Set<PetVaultRole>>{};
  final Map<String, Set<DateTime>> sitterUnavailableDates =
      <String, Set<DateTime>>{};
  final Set<DateTime> bookedVetSlots = <DateTime>{};
  final Map<String, Set<DateTime>> vetAvailableSlots =
      <String, Set<DateTime>>{};
  final List<String> _pendingVerification = <String>[];

  String currentUserId = '';
  PetVaultRole activeRole = PetVaultRole.owner;
  String? lastOtp;
  String? lastResetCode;
  String? lastError;
  int paymentCommissionPercent = 5;
  bool requireExplicitConsent = true;
  bool allowSitterFullRecords = false;

  String get currentUserName =>
      _accounts[currentUserId]?.name ?? 'PetVault user';

  String accountName(String email) => _accounts[email]?.name ?? email;

  Set<PetVaultRole> rolesFor(String email) =>
      Set<PetVaultRole>.unmodifiable(_roles[email] ?? <PetVaultRole>{});

  String get currentEmail => _accounts[currentUserId]?.email.isNotEmpty == true
      ? _accounts[currentUserId]!.email
      : currentUserId;

  String get currentPhone => _accounts[currentUserId]?.phone ?? '';

  Set<PetVaultRole> get currentRoles =>
      _roles[currentUserId] ?? <PetVaultRole>{};

  bool get isSignedIn => _accounts.containsKey(currentUserId);

  bool get currentUserVerified => _accounts[currentUserId]?.verified ?? false;

  int get activeOrderCount => orders
      .where((order) =>
          order.buyerId == currentUserId &&
          order.status != 'Delivered' &&
          order.status != 'Cancelled')
      .length;

  int get activeBookingCount => bookings
      .where((booking) =>
          booking.active &&
          (booking.ownerId == currentUserId ||
              booking.sitter == currentUserName))
      .length;

  List<SittingBooking> get visibleBookings => bookings
      .where((booking) =>
          (activeRole == PetVaultRole.owner &&
              booking.ownerId == currentUserId) ||
          (activeRole == PetVaultRole.sitter &&
              booking.sitter == currentUserName))
      .toList(growable: false);

  List<VetAppointment> get visibleAppointments => appointments
      .where((item) =>
          (activeRole == PetVaultRole.owner && item.ownerId == currentUserId) ||
          (activeRole == PetVaultRole.veterinarian &&
              item.vet == currentUserName))
      .toList(growable: false);

  List<VaultOrder> get visibleOrders => orders
      .where((order) =>
          (activeRole == PetVaultRole.owner &&
              order.buyerId == currentUserId) ||
          (activeRole == PetVaultRole.vendor &&
              order.productIds.any(
                (productId) => products[productId]?.vendorId == currentUserId,
              )) ||
          currentRoles.contains(PetVaultRole.admin))
      .toList(growable: false);

  int get openDisputeCount => openDisputes.length;

  List<PetProfile> get ownerPets => pets.values
      .where((pet) => pet.ownerId == currentUserId)
      .toList(growable: false);

  void activateRemoteSession(Map<String, dynamic> user) {
    final userId = user['id'];
    final email = user['email'];
    final displayName = user['displayName'];
    if (userId is! String ||
        email is! String ||
        displayName is! String ||
        user['roles'] is! List<Object?>) {
      throw const FormatException(
          'The backend returned an invalid user profile.');
    }
    final remoteRoles = (user['roles'] as List<Object?>)
        .whereType<String>()
        .map(_roleFromLabel)
        .whereType<PetVaultRole>()
        .toSet();
    if (remoteRoles.isEmpty) {
      throw const FormatException('The backend user has no assigned role.');
    }
    _accounts[userId] = _DemoAccount(
      name: displayName,
      email: email,
      password: '',
      phone: user['phone'] is String ? user['phone'] as String : '',
      verified: user['verified'] == true,
    );
    _roles[userId] = remoteRoles;
    currentUserId = userId;
    activeRole = remoteRoles.contains(PetVaultRole.owner)
        ? PetVaultRole.owner
        : remoteRoles.first;
    lastError = null;
    notifyListeners();
  }

  void replaceRemotePets(List<Map<String, dynamic>> remotePets) {
    pets.removeWhere((_, pet) => pet.ownerId == currentUserId);
    for (final remotePet in remotePets) {
      final id = remotePet['id'];
      final name = remotePet['name'];
      final species = remotePet['species'];
      final breed = remotePet['breed'];
      final age = remotePet['age'];
      final sex = remotePet['sex'];
      final weight = remotePet['weightKg'];
      if (id is! String ||
          name is! String ||
          species is! String ||
          breed is! String ||
          age is! String ||
          sex is! String ||
          weight is! num) {
        throw const FormatException(
            'The backend returned an invalid pet profile.');
      }
      pets[id] = PetProfile(
        id: id,
        name: name,
        species: species,
        breed: breed,
        age: age,
        sex: sex,
        weightKg: weight.toDouble(),
        microchip: remotePet['microchip'] is String
            ? remotePet['microchip'] as String
            : '',
        ownerId: remotePet['ownerId'] is String
            ? remotePet['ownerId'] as String
            : currentUserId,
      );
    }
    notifyListeners();
  }

  void replaceRemoteHealthRecords(
      String petId, List<Map<String, dynamic>> remoteRecords) {
    final pet = pets[petId];
    if (pet == null || pet.ownerId != currentUserId) {
      throw const FormatException(
          'The backend returned records for an unavailable pet.');
    }
    pet
      ..records.clear()
      ..vaccinations.clear();
    for (final remoteRecord in remoteRecords) {
      final id = remoteRecord['id'];
      final title = remoteRecord['title'];
      final type = remoteRecord['type'];
      final provider = remoteRecord['provider'];
      final date = DateTime.tryParse(remoteRecord['date']?.toString() ?? '');
      if (id is! String ||
          title is! String ||
          type is! String ||
          provider is! String ||
          date == null) {
        throw const FormatException(
            'The backend returned an invalid health record.');
      }
      final nextDue =
          DateTime.tryParse(remoteRecord['nextDueAt']?.toString() ?? '');
      final record = HealthRecord(
        id: id,
        title: title,
        type: type,
        date: date,
        provider: provider,
        nextDueAt: nextDue,
        vetName: remoteRecord['vetName'] as String?,
        attachmentName: remoteRecord['attachmentName'] as String?,
      );
      pet.records.add(record);
      if (type.toLowerCase().contains('vaccin')) {
        pet.vaccinations.add(
          VaccinationEntry(
            id: id,
            name: title,
            givenAt: date,
            nextDueAt: nextDue,
            provider: record.vetName ?? provider,
          ),
        );
      }
    }
    pet.records.sort((a, b) => b.date.compareTo(a.date));
    pet.vaccinations.sort((a, b) => b.givenAt.compareTo(a.givenAt));
    notifyListeners();
  }

  void replaceRemoteListings(List<Map<String, dynamic>> remoteListings) {
    listings.clear();
    for (final remoteListing in remoteListings) {
      final id = remoteListing['id'];
      final title = remoteListing['title'];
      final species = remoteListing['species'];
      final breed = remoteListing['breed'];
      final city = remoteListing['city'];
      final price = remoteListing['price'];
      final age = remoteListing['age'];
      final sellerId = remoteListing['sellerId'];
      if (id is! String ||
          title is! String ||
          species is! String ||
          breed is! String ||
          city is! String ||
          sellerId is! String ||
          age is! String ||
          num.tryParse(price?.toString() ?? '') == null) {
        throw const FormatException('The backend returned an invalid listing.');
      }
      final statusName =
          remoteListing['status']?.toString().replaceAll('_', '').toLowerCase();
      final status = ListingStatus.values.firstWhere(
        (candidate) => candidate.name.toLowerCase() == statusName,
        orElse: () => ListingStatus.active,
      );
      listings[id] = PetListing(
        id: id,
        title: title,
        species: species,
        breed: breed,
        city: city,
        price: num.parse(price.toString()).toDouble(),
        age: age,
        sellerId: sellerId,
        sellerName: remoteListing['sellerName'] is String
            ? remoteListing['sellerName'] as String
            : '',
        image: remoteListing['imageUrl'] is String
            ? remoteListing['imageUrl'] as String
            : '',
        verifiedSeller: remoteListing['verifiedSeller'] == true,
        healthNotes: remoteListing['healthNotes'] is String
            ? remoteListing['healthNotes'] as String
            : '',
        status: status,
      );
    }
    notifyListeners();
  }

  void addRemoteListing(Map<String, dynamic> remoteListing) {
    replaceRemoteListings(<Map<String, dynamic>>[
      ...listings.values.map((listing) => <String, dynamic>{
            'id': listing.id,
            'title': listing.title,
            'species': listing.species,
            'breed': listing.breed,
            'city': listing.city,
            'price': listing.price,
            'age': listing.age,
            'sellerId': listing.sellerId,
            'imageUrl': listing.image,
            'healthNotes': listing.healthNotes,
            'status': listing.status.name,
            'verifiedSeller': listing.verifiedSeller,
          }),
      remoteListing,
    ]);
  }

  bool canViewPetProfile(String petId) {
    final pet = pets[petId];
    if (pet == null) return false;
    if (activeRole == PetVaultRole.owner && pet.ownerId == currentUserId) {
      return true;
    }
    return canAccessPetSection(petId, currentUserName, 'health') ||
        canAccessPetSection(petId, currentUserName, 'care essentials');
  }

  List<HealthRecord> accessibleHealthRecords(String petId) {
    final pet = pets[petId];
    if (pet == null) return <HealthRecord>[];
    if ((activeRole == PetVaultRole.owner && pet.ownerId == currentUserId) ||
        canAccessPetSection(petId, currentUserName, 'health')) {
      return List<HealthRecord>.unmodifiable(pet.records);
    }
    return <HealthRecord>[];
  }

  List<String> get licensedVeterinarians =>
      _licensedVets.toList(growable: false);

  List<ShareGrant> activeGrantsForPet(String petId) {
    if (pets[petId]?.ownerId != currentUserId) return <ShareGrant>[];
    return _grants.entries
        .where((entry) => entry.key.startsWith('$petId:') && entry.value.active)
        .map((entry) => entry.value)
        .toList(growable: false);
  }

  List<PetListing> get activeListings => listings.values
      .where((listing) => listing.status == ListingStatus.active)
      .toList(growable: false);

  List<PetListing> get currentSellerListings => listings.values
      .where((listing) => listing.sellerId == currentUserId)
      .toList(growable: false);

  Map<String, KycStatus> get pendingKycQueue =>
      Map<String, KycStatus>.fromEntries(
        kyc.entries.where((entry) =>
            entry.value == KycStatus.pending ||
            entry.value == KycStatus.pendingReview ||
            entry.value == KycStatus.serviceUnavailable),
      );

  List<PetListing> get listingsPendingReview => listings.values
      .where((listing) => listing.status == ListingStatus.pendingReview)
      .toList(growable: false);

  List<ListingReport> get reportsPendingReview => listingReports
      .where((report) => !report.resolved)
      .toList(growable: false);

  List<PetListing> get favoriteListings => listings.values
      .where((listing) => listing.favorites.contains(currentUserId))
      .toList(growable: false);

  List<VaultProduct> get publishedProducts =>
      products.values.where((product) => product.published).toList();

  void replaceRemoteProducts(List<Map<String, dynamic>> remoteProducts) {
    products.clear();
    for (final remoteProduct in remoteProducts) {
      final id = remoteProduct['id'];
      final name = remoteProduct['name'];
      final price = num.tryParse(remoteProduct['price']?.toString() ?? '');
      final stock = remoteProduct['stock'];
      final vendorId = remoteProduct['vendorId'];
      if (id is! String ||
          name is! String ||
          price == null ||
          stock is! int ||
          vendorId is! String) {
        throw const FormatException('The backend returned an invalid product.');
      }
      products[id] = VaultProduct(
        id: id,
        name: name,
        price: price.toDouble(),
        stock: stock,
        image: remoteProduct['imageUrl'] is String
            ? remoteProduct['imageUrl'] as String
            : '',
        vendorId: vendorId,
        vendorName: remoteProduct['vendorName'] is String
            ? remoteProduct['vendorName'] as String
            : '',
        published: remoteProduct['published'] != false,
      );
    }
    cart.removeWhere((productId, _) => !products.containsKey(productId));
    notifyListeners();
  }

  void replaceRemoteFavorites(List<Map<String, dynamic>> remoteFavorites) {
    for (final listing in listings.values) {
      listing.favorites.remove(currentUserId);
    }
    for (final remoteListing in remoteFavorites) {
      final id = remoteListing['id'];
      if (id is! String || !listings.containsKey(id)) {
        throw const FormatException(
            'The backend returned a favorite listing that is unavailable.');
      }
      listings[id]!.favorites.add(currentUserId);
    }
    notifyListeners();
  }

  void replaceRemoteOrders(List<Map<String, dynamic>> remoteOrders) {
    orders.removeWhere((order) => order.buyerId == currentUserId);
    for (final remoteOrder in remoteOrders) {
      final id = remoteOrder['id'];
      final status = remoteOrder['status'];
      final paymentStatus = remoteOrder['paymentStatus'];
      final total = num.tryParse(remoteOrder['total']?.toString() ?? '');
      final createdAt = DateTime.tryParse(
        remoteOrder['createdAt']?.toString() ?? '',
      );
      final items = remoteOrder['items'];
      if (id is! String ||
          status is! String ||
          paymentStatus is! String ||
          total == null ||
          createdAt == null ||
          items is! List) {
        throw const FormatException('The backend returned an invalid order.');
      }
      final productIds = <String>[];
      final quantities = <int>[];
      for (final item in items) {
        if (item is! Map<String, dynamic> ||
            item['productId'] is! String ||
            item['quantity'] is! int) {
          throw const FormatException(
              'The backend returned an invalid order item.');
        }
        productIds.add(item['productId'] as String);
        quantities.add(item['quantity'] as int);
      }
      final parsedPaymentStatus = PaymentStatus.values.firstWhere(
        (value) => value.name.toLowerCase() == paymentStatus.toLowerCase(),
        orElse: () => PaymentStatus.failed,
      );
      orders.add(
        VaultOrder(
          id: id,
          productIds: productIds,
          quantities: quantities,
          total: total.toDouble(),
          createdAt: createdAt,
          buyerId: currentUserId,
        )
          ..status = status
          ..paymentStatus = parsedPaymentStatus,
      );
    }
    notifyListeners();
  }

  List<AuditEntry> get auditTrail => audit.reversed.toList(growable: false);

  List<VaultNotification> get inbox => notifications
      .where((item) => item.recipientId == currentUserId)
      .toList()
      .reversed
      .toList(growable: false);

  List<PetListing> searchListings({
    String species = '',
    String breed = '',
    String city = '',
    double? minPrice,
    double? maxPrice,
    bool verifiedOnly = false,
    String query = '',
  }) {
    final terms = query.trim().toLowerCase();
    final results = activeListings.where((listing) {
      return (species.isEmpty ||
              listing.species.toLowerCase() == species.toLowerCase()) &&
          (breed.isEmpty ||
              listing.breed.toLowerCase().contains(breed.toLowerCase())) &&
          (city.isEmpty ||
              listing.city.toLowerCase().contains(city.toLowerCase())) &&
          (minPrice == null || listing.price >= minPrice) &&
          (maxPrice == null || listing.price <= maxPrice) &&
          (!verifiedOnly || listing.verifiedSeller) &&
          (terms.isEmpty ||
              listing.title.toLowerCase().contains(terms) ||
              listing.breed.toLowerCase().contains(terms));
    }).toList();
    results.sort((a, b) => b.favorites.length.compareTo(a.favorites.length));
    return results;
  }

  List<PetListing> recommendations({bool serviceAvailable = true}) {
    final candidates = activeListings;
    if (!serviceAvailable) return candidates;
    candidates.sort((a, b) {
      final scoreA = (a.verifiedSeller ? 2 : 0) +
          (favoriteListings.any((item) => item.species == a.species) ? 1 : 0);
      final scoreB = (b.verifiedSeller ? 2 : 0) +
          (favoriteListings.any((item) => item.species == b.species) ? 1 : 0);
      return scoreB.compareTo(scoreA);
    });
    return candidates;
  }

  void _seedDemoData() {
    _accounts[currentUserId] = _DemoAccount(
      name: 'Hammad Farman',
      password: 'demo1234',
      verified: true,
    );
    _roles[currentUserId] = <PetVaultRole>{PetVaultRole.owner};
    _accounts['vendor@petvault.demo'] = _DemoAccount(
      name: 'Paw Pantry',
      password: 'demo1234',
      verified: true,
    );
    _roles['vendor@petvault.demo'] = <PetVaultRole>{PetVaultRole.vendor};
    _accounts['admin@petvault.demo'] = _DemoAccount(
      name: 'PetVault Admin',
      password: 'demo1234',
      verified: true,
    );
    _roles['admin@petvault.demo'] = <PetVaultRole>{PetVaultRole.admin};
    _accounts['vet@petvault.demo'] = _DemoAccount(
      name: 'Dr. Ayesha Ali',
      password: 'demo1234',
      verified: true,
    );
    _roles['vet@petvault.demo'] = <PetVaultRole>{PetVaultRole.veterinarian};
    _accounts['seller@petvault.demo'] = _DemoAccount(
      name: 'Zara Ahmed',
      password: 'demo1234',
      verified: true,
    );
    _roles['seller@petvault.demo'] = <PetVaultRole>{
      PetVaultRole.owner,
      PetVaultRole.seller,
    };
    _accounts['sitter@petvault.demo'] = _DemoAccount(
      name: 'Sana Ali',
      password: 'demo1234',
      verified: true,
    );
    _roles['sitter@petvault.demo'] = <PetVaultRole>{PetVaultRole.sitter};
    kyc['vendor@petvault.demo'] = KycStatus.verified;
    kyc['vet@petvault.demo'] = KycStatus.verified;
    kyc['seller@petvault.demo'] = KycStatus.pending;
    kyc['sitter@petvault.demo'] = KycStatus.verified;

    final rosco = PetProfile(
      id: 'pet-rosco',
      name: 'ROSCO',
      species: 'Dog',
      breed: 'Golden Retriever',
      age: '3 years',
      sex: 'Male',
      weightKg: 28,
    );
    rosco.vaccinations.add(
      VaccinationEntry(
        id: 'vaccine-rabies',
        name: 'Rabies booster',
        givenAt: DateTime(2026, 10, 4),
        nextDueAt: DateTime(2026, 11, 18),
        provider: 'PetCare Clinic',
      ),
    );
    rosco.records.addAll(<HealthRecord>[
      HealthRecord(
        id: 'record-vaccine',
        title: 'Vaccination document',
        type: 'Vaccination',
        date: DateTime(2026, 10, 4),
        provider: 'PetCare Clinic',
        nextDueAt: DateTime(2026, 11, 18),
      ),
      HealthRecord(
        id: 'record-clinic',
        title: 'Clinic visit summary',
        type: 'Clinic visit',
        date: DateTime(2026, 9, 22),
        provider: 'Dr. Ayesha Ali',
      ),
      HealthRecord(
        id: 'record-weight',
        title: 'Weight entry · 28 kg',
        type: 'Weight',
        date: DateTime(2026, 10, 12),
        provider: 'Hammad Farman',
      ),
    ]);
    rosco.access['Dr. Ayesha Ali'] = <String>{'health', 'vaccinations'};
    rosco.access['Sana Ali'] = <String>{'care essentials'};
    pets[rosco.id] = rosco;
    _grants['${rosco.id}:Dr. Ayesha Ali'] = ShareGrant(
      recipient: 'Dr. Ayesha Ali',
      sections: <String>{'health', 'vaccinations'},
      expiresAt: null,
    );
    _grants['${rosco.id}:Sana Ali'] = ShareGrant(
      recipient: 'Sana Ali',
      sections: <String>{'care essentials'},
      expiresAt: null,
    );

    final luna = PetProfile(
      id: 'pet-luna',
      name: 'Luna',
      species: 'Cat',
      breed: 'Persian',
      age: '2 years',
      sex: 'Female',
      weightKg: 4.2,
    );
    pets[luna.id] = luna;
    final coco = PetProfile(
      id: 'pet-coco',
      name: 'Coco',
      species: 'Rabbit',
      breed: 'Holland Lop',
      age: '1 year',
      sex: 'Female',
      weightKg: 2.1,
    );
    pets[coco.id] = coco;

    final listingData = <PetListing>[
      PetListing(
        id: 'listing-golden',
        title: 'Golden Retriever Puppy — Champion Line',
        species: 'Dog',
        breed: 'Golden Retriever',
        city: 'Karachi',
        price: 45000,
        age: '8 weeks',
        sellerId: 'seller@petvault.demo',
        image: 'assets/images/listing_golden.png',
        healthNotes: 'Vaccination document uploaded',
      ),
      PetListing(
        id: 'listing-kittens',
        title: 'Persian Kittens — Pair Available',
        species: 'Cat',
        breed: 'Persian',
        city: 'Karachi',
        price: 12000,
        age: '6 weeks',
        sellerId: 'seller-sana',
        image: 'assets/images/listing_kittens.png',
      ),
      PetListing(
        id: 'listing-shepherd',
        title: 'German Shepherd — Trained & Vaccinated',
        species: 'Dog',
        breed: 'German Shepherd',
        city: 'Karachi',
        price: 55000,
        age: '6 months',
        sellerId: 'seller-ahmed',
        image: 'assets/images/listing_shepherd.png',
      ),
      PetListing(
        id: 'listing-rabbits',
        title: 'Holland Lop Rabbits — 3 Available',
        species: 'Rabbit',
        breed: 'Holland Lop',
        city: 'Karachi',
        price: 3500,
        age: '10 weeks',
        sellerId: 'seller-ali',
        image: 'assets/images/listing_rabbits.png',
      ),
    ];
    for (final listing in listingData) {
      listings[listing.id] = listing;
    }

    final productData = <VaultProduct>[
      VaultProduct(
        id: 'product-food',
        name: 'Complete dog food',
        price: 4800,
        stock: 32,
        image: 'assets/images/product_food.png',
      ),
      VaultProduct(
        id: 'product-toy',
        name: 'Interactive chew toy',
        price: 1250,
        stock: 3,
        image: 'assets/images/product_toy.png',
      ),
      VaultProduct(
        id: 'product-bed',
        name: 'Soft pet bed',
        price: 6200,
        stock: 18,
        image: 'assets/images/product_bed.png',
      ),
    ];
    for (final product in productData) {
      products[product.id] = product;
    }

    _pushNotification(
      'Upcoming vaccination',
      'ROSCO’s rabies booster is due on 18 Nov 2026.',
    );
  }

  bool register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty ||
        !normalizedEmail.contains('@') ||
        phone.trim().length < 7 ||
        password.length < 8) {
      return _fail(
          'Enter a name, valid email, phone number, and password of at least 8 characters.');
    }
    if (_accounts.containsKey(normalizedEmail)) {
      return _fail('An account already exists for this email address.');
    }
    _accounts[normalizedEmail] = _DemoAccount(
      name: name.trim(),
      password: password,
      phone: phone.trim(),
    );
    _roles[normalizedEmail] = <PetVaultRole>{PetVaultRole.owner};
    kyc[normalizedEmail] = KycStatus.notSubmitted;
    _pendingVerification.add(normalizedEmail);
    currentUserId = normalizedEmail;
    activeRole = PetVaultRole.owner;
    lastOtp = '123456';
    _pushNotification(
        'Verify your account', 'Demo verification code: $lastOtp');
    _recordAudit('Account registration', normalizedEmail);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool verifyAccount(String code) {
    final account = _accounts[currentUserId];
    if (account == null) return _fail('Register or sign in before verifying.');
    if (lastOtp == null || code.trim() != lastOtp) {
      return _fail('That verification code is invalid or expired.');
    }
    account.verified = true;
    _pendingVerification.remove(currentUserId);
    _roles.putIfAbsent(currentUserId, () => <PetVaultRole>{PetVaultRole.owner});
    lastOtp = null;
    _recordAudit('Account verified', currentUserId);
    _pushNotification('Account verified', 'Your account is ready to use.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool resendVerificationCode() {
    if (!_accounts.containsKey(currentUserId)) {
      return _fail('Register before requesting a verification code.');
    }
    lastOtp = '123456';
    _pushNotification(
        'Verification code reissued', 'Demo verification code: $lastOtp');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool signIn(String email, String password) {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null) return _fail('Email or password is incorrect.');
    final now = _clock();
    if (account.lockedUntil != null && account.lockedUntil!.isAfter(now)) {
      final minutes = account.lockedUntil!.difference(now).inMinutes + 1;
      return _fail(
          'Sign-in is temporarily locked. Try again in $minutes minutes.');
    }
    if (account.password != password) {
      account.failedAttempts += 1;
      _recordAudit('Failed sign-in attempt', key);
      if (account.failedAttempts >= 5) {
        account.lockedUntil = now.add(const Duration(minutes: 15));
        _pushNotification('Temporary sign-in lock',
            'Too many failed attempts. Sign-in is locked for 15 minutes.');
        return _fail(
            'Too many failed attempts. Sign-in is locked for 15 minutes.');
      }
      notifyListeners();
      return _fail('Email or password is incorrect.');
    }
    if (!account.verified) {
      currentUserId = key;
      lastOtp = '123456';
      notifyListeners();
      return _fail('Verify your account first. Demo code: 123456.');
    }
    account.failedAttempts = 0;
    account.lockedUntil = null;
    currentUserId = key;
    final roles = _roles[key] ?? <PetVaultRole>{PetVaultRole.owner};
    _roles[key] = roles;
    activeRole =
        roles.contains(PetVaultRole.owner) ? PetVaultRole.owner : roles.first;
    _recordAudit('Successful sign-in', key);
    notifyListeners();
    lastError = null;
    return true;
  }

  void signOut() {
    currentUserId = '';
    activeRole = PetVaultRole.owner;
    lastOtp = null;
    lastResetCode = null;
    _recordAudit('Signed out', 'session');
    notifyListeners();
  }

  bool requestPasswordReset(String email) {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || !account.verified) {
      return _fail('No verified account was found for that email.');
    }
    lastResetCode = '654321';
    _pushNotification('Password reset requested',
        'Demo reset code: $lastResetCode. Do not share this code.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null ||
        !account.verified ||
        code.trim() != lastResetCode ||
        newPassword.length < 8) {
      return _fail(
          'Check your reset code and enter a password of at least 8 characters.');
    }
    account.password = newPassword;
    account.failedAttempts = 0;
    account.lockedUntil = null;
    lastResetCode = null;
    _recordAudit('Password reset', key);
    _pushNotification('Password updated', 'Your demo password was changed.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool requestKyc({required String documentReference, required String role}) {
    if (!isSignedIn || !currentUserVerified) {
      return _fail('Verify your account before submitting KYC.');
    }
    if (documentReference.trim().isEmpty) {
      return _fail('Add a document reference before submitting KYC.');
    }
    final accountRoles = currentRoles;
    final supplyRoles = accountRoles
        .where((item) =>
            item == PetVaultRole.sitter ||
            item == PetVaultRole.veterinarian ||
            item == PetVaultRole.vendor)
        .toList();
    final requested = _roleFromLabel(role);
    if (requested == null || requested == PetVaultRole.admin) {
      return _fail('Choose a supported supply-side role.');
    }
    if (requested != PetVaultRole.seller &&
        supplyRoles.any((item) => item != requested)) {
      return _fail(
          'This demo account already has a different supply-side role. Use a separate account.');
    }
    if (requested == PetVaultRole.seller &&
        supplyRoles.isNotEmpty &&
        !supplyRoles.contains(PetVaultRole.seller)) {
      return _fail(
          'Only owner + seller is supported on one account. Use a separate account for another supply-side role.');
    }
    if (requested == PetVaultRole.seller &&
        !accountRoles.contains(PetVaultRole.owner)) {
      return _fail('Seller activation is available to verified pet owners.');
    }
    if (requested != PetVaultRole.seller &&
        (accountRoles.length != 1 || !accountRoles.contains(requested))) {
      return _fail(
          'Submit KYC only for the selected role. Use a separate account for another supply-side role.');
    }
    accountRoles.add(requested);
    activeRole = requested;
    kyc[currentUserId] = KycStatus.pending;
    _recordAudit(
        'KYC submitted for ${_roleLabel(requested)}', documentReference.trim());
    _pushNotification('KYC submission received',
        'Your ${_roleLabel(requested)} verification is pending review.');
    notifyListeners();
    lastError = null;
    return true;
  }

  void simulateKycProviderUnavailable() {
    kyc[currentUserId] = KycStatus.serviceUnavailable;
    _recordAudit('KYC provider unavailable; request queued', currentUserId);
    _pushNotification('KYC pending',
        'Verification service is unavailable. Your request is queued for retry.');
    notifyListeners();
  }

  bool reviewKyc(String userId, KycStatus decision) {
    if (!isSignedIn || activeRole != PetVaultRole.admin) {
      return denyAccess('review identity submissions', userId);
    }
    if (decision != KycStatus.verified &&
        decision != KycStatus.rejected &&
        decision != KycStatus.pendingReview) {
      return _fail('Select approve, reject, or request resubmission.');
    }
    kyc[userId] = decision;
    _recordAudit('KYC ${decision.name}', userId);
    _pushNotification('KYC decision', 'Your verification is ${decision.name}.',
        recipientId: userId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool switchRole(PetVaultRole role) {
    if (!currentRoles.contains(role)) {
      return denyAccess('switch to ${_roleLabel(role)} role', currentUserId);
    }
    activeRole = role;
    _recordAudit('Role switched to ${_roleLabel(role)}', currentUserId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool activateSellerRole() {
    if (!currentUserVerified) {
      return _fail('Verify your account before activating seller access.');
    }
    if (currentRoles.any((role) =>
        role == PetVaultRole.sitter ||
        role == PetVaultRole.veterinarian ||
        role == PetVaultRole.vendor)) {
      return _fail(
          'Only owner + seller roles can share an account. Use a separate account for another supply-side role.');
    }
    currentRoles.add(PetVaultRole.seller);
    activeRole = PetVaultRole.seller;
    _recordAudit(
        'Seller role activated; KYC required before publishing', currentUserId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool selectInitialSupplyRole(PetVaultRole role) {
    if (role == PetVaultRole.owner || role == PetVaultRole.seller) {
      return _fail('Use the owner or seller activation flow for that role.');
    }
    final roles = currentRoles;
    if (roles.length == 1 && roles.contains(PetVaultRole.owner)) {
      roles
        ..clear()
        ..add(role);
      activeRole = role;
      _recordAudit('Initial role selected: ${_roleLabel(role)}', currentUserId);
      notifyListeners();
      lastError = null;
      return true;
    }
    if (roles.contains(role) && roles.length == 1) {
      activeRole = role;
      notifyListeners();
      lastError = null;
      return true;
    }
    return _fail(
        'A separate account is required for another supply-side role.');
  }

  bool hasRole(PetVaultRole role) => currentRoles.contains(role);

  bool authorize(PetVaultRole requiredRole, String action) {
    if (isSignedIn && activeRole == requiredRole) return true;
    return denyAccess(action, currentUserId);
  }

  bool denyAccess(String action, String record) {
    _recordAudit('Access denied: $action', record);
    lastError = 'You do not have permission to $action.';
    notifyListeners();
    return false;
  }

  bool addPet({
    required String name,
    required String species,
    required String breed,
    required String age,
    required String sex,
    required String weight,
    String microchip = '',
  }) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('create a pet profile', currentUserId);
    }
    final parsedWeight = double.tryParse(weight.trim());
    if (parsedWeight == null || parsedWeight <= 0) {
      return _fail('Enter a valid weight greater than zero.');
    }
    final errors = <String>[
      if (name.trim().isEmpty) 'pet name',
      if (species.trim().isEmpty) 'species',
      if (breed.trim().isEmpty) 'breed',
      if (age.trim().isEmpty) 'age',
      if (sex.trim().isEmpty) 'sex',
    ];
    if (errors.isNotEmpty) return _fail('Enter ${errors.join(', ')}.');
    final id = _id('pet');
    pets[id] = PetProfile(
      id: id,
      name: name.trim(),
      species: species.trim(),
      breed: breed.trim(),
      age: age.trim(),
      sex: sex.trim(),
      weightKg: parsedWeight,
      microchip: microchip.trim(),
      ownerId: currentUserId,
    );
    _recordAudit('Pet profile created', id);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool updatePet(
    String petId, {
    required String name,
    required String species,
    required String breed,
    required String age,
    required String sex,
    required String weight,
    String microchip = '',
  }) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('update a pet profile', petId);
    }
    final pet = pets[petId];
    final parsedWeight = double.tryParse(weight.trim());
    if (pet == null || pet.ownerId != currentUserId) {
      return _fail('The selected pet profile was not found or is not yours.');
    }
    if (name.trim().isEmpty ||
        species.trim().isEmpty ||
        breed.trim().isEmpty ||
        age.trim().isEmpty ||
        sex.trim().isEmpty ||
        parsedWeight == null ||
        parsedWeight <= 0) {
      return _fail(
          'Complete every required pet field and enter a valid weight.');
    }
    pet
      ..name = name.trim()
      ..species = species.trim()
      ..breed = breed.trim()
      ..age = age.trim()
      ..sex = sex.trim()
      ..weightKg = parsedWeight
      ..microchip = microchip.trim();
    _recordAudit('Pet profile updated', petId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool addHealthRecord({
    required String petId,
    required String title,
    required String type,
    required DateTime date,
    required String provider,
    DateTime? nextDueAt,
    String? vetName,
    String? attachmentName,
    int? attachmentSizeBytes,
    Uint8List? attachmentBytes,
  }) {
    if (!isSignedIn ||
        (activeRole != PetVaultRole.owner &&
            activeRole != PetVaultRole.veterinarian)) {
      return denyAccess('add a health record', petId);
    }
    final pet = pets[petId];
    if (pet == null) return _fail('The selected pet profile was not found.');
    if (activeRole == PetVaultRole.owner && pet.ownerId != currentUserId) {
      return denyAccess('add a health record to this pet', petId);
    }
    if (title.trim().isEmpty ||
        type.trim().isEmpty ||
        provider.trim().isEmpty) {
      return _fail('Enter a record title, type, and provider.');
    }
    if (type.toLowerCase().contains('vaccin') &&
        nextDueAt == null &&
        !title.toLowerCase().contains('no booster')) {
      return _fail(
          'Enter the next due date or record that no booster is required.');
    }
    if (attachmentName != null) {
      final extension = attachmentName.split('.').last.toLowerCase();
      if (!<String>{'pdf', 'jpg', 'jpeg', 'png'}.contains(extension)) {
        return _fail('Choose a PDF, JPG, or PNG health document.');
      }
      if (attachmentSizeBytes == null ||
          attachmentSizeBytes < 1 ||
          attachmentSizeBytes > 10 * 1024 * 1024) {
        return _fail('Health documents must be 10 MB or smaller.');
      }
    }
    if (activeRole == PetVaultRole.veterinarian &&
        !canAccessPetSection(petId, currentUserName, 'health')) {
      return denyAccess('update this pet health record', petId);
    }
    final record = HealthRecord(
      id: _id('record'),
      title: title.trim(),
      type: type.trim(),
      date: date,
      provider: provider.trim(),
      nextDueAt: nextDueAt,
      vetName:
          activeRole == PetVaultRole.veterinarian ? currentUserName : vetName,
      attachmentName: attachmentName,
      attachmentSizeBytes: attachmentSizeBytes,
      attachmentBytes: attachmentBytes,
    );
    pet.records.add(record);
    if (type.toLowerCase().contains('vaccin')) {
      pet.vaccinations.add(
        VaccinationEntry(
          id: record.id,
          name: record.title,
          givenAt: date,
          nextDueAt: nextDueAt,
          provider: record.vetName ?? record.provider,
        ),
      );
    }
    pet.records.sort((a, b) => b.date.compareTo(a.date));
    pet.vaccinations.sort((a, b) => b.givenAt.compareTo(a.givenAt));
    _recordAudit('Health record added', '$petId:${record.id}');
    _scheduleDueReminder(pet, record);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool addWeightEntry(String petId, String weight) {
    final pet = pets[petId];
    final kilograms = double.tryParse(weight.trim());
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('record a pet weight', petId);
    }
    if (pet == null) return _fail('The selected pet profile was not found.');
    if (pet.ownerId != currentUserId) {
      return denyAccess('record this pet weight', petId);
    }
    if (kilograms == null || kilograms <= 0) {
      return _fail('Enter a valid weight greater than zero.');
    }
    pet.weightKg = kilograms;
    pet.records.add(
      HealthRecord(
        id: _id('weight'),
        title: 'Weight entry · $kilograms kg',
        type: 'Weight',
        date: _clock(),
        provider: currentUserName,
      ),
    );
    pet.records.sort((a, b) => b.date.compareTo(a.date));
    _recordAudit('Pet weight recorded', '$petId:$kilograms');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool grantPetAccess({
    required String petId,
    required String recipient,
    required Set<String> sections,
    required bool consentGiven,
    DateTime? expiresAt,
  }) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('share pet data', petId);
    }
    final pet = pets[petId];
    if (pet == null) return _fail('The selected pet profile was not found.');
    if (pet.ownerId != currentUserId) {
      return denyAccess('share another owner’s pet data', petId);
    }
    if (recipient.trim().isEmpty || sections.isEmpty) {
      return _fail('Choose a recipient and at least one profile section.');
    }
    if (requireExplicitConsent && !consentGiven) {
      return _fail('The owner must explicitly consent before sharing records.');
    }
    final recipientAccount = _accounts.entries
        .where((entry) => entry.value.name == recipient.trim())
        .firstOrNull;
    final isSitter = recipientAccount != null &&
        (_roles[recipientAccount.key]?.contains(PetVaultRole.sitter) ?? false);
    if (isSitter && sections.contains('all') && !allowSitterFullRecords) {
      return _fail('Full health-record access for sitters is disabled.');
    }
    pet.access[recipient.trim()] = sections;
    final grant = ShareGrant(
      recipient: recipient.trim(),
      sections: sections,
      expiresAt: expiresAt,
    );
    _grants['$petId:${recipient.trim()}'] = grant;
    _recordAudit('Pet data access granted', '$petId:${recipient.trim()}');
    _pushNotification('Pet profile shared',
        'Selected care details were shared with ${recipient.trim()}.');
    notifyListeners();
    lastError = null;
    return true;
  }

  void updatePrivacyPreferences({
    required bool requireConsent,
    required bool allowSitterFullRecords,
  }) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      denyAccess('update privacy preferences', currentUserId);
      return;
    }
    requireExplicitConsent = requireConsent;
    this.allowSitterFullRecords = allowSitterFullRecords;
    _recordAudit('Privacy preferences updated', currentUserId);
    notifyListeners();
  }

  final Map<String, ShareGrant> _grants = <String, ShareGrant>{};

  bool revokePetAccess(String petId, String recipient) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('revoke pet data access', petId);
    }
    final pet = pets[petId];
    final grant = _grants['$petId:$recipient'];
    if (pet == null ||
        pet.ownerId != currentUserId ||
        grant == null ||
        !grant.active) {
      return _fail('No active access grant was found.');
    }
    grant.active = false;
    pet.access.remove(recipient);
    _recordAudit('Pet data access revoked', '$petId:$recipient');
    _pushNotification('Pet profile access revoked',
        '$recipient no longer has access to ${pet.name}’s profile.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool canAccessPetSection(String petId, String recipient, String section) {
    if (!isSignedIn) return false;
    final grant = _grants['$petId:$recipient'];
    if (activeRole == PetVaultRole.owner &&
        pets[petId]?.ownerId == currentUserId) {
      return true;
    }
    if (grant == null ||
        !grant.active ||
        (grant.expiresAt != null && grant.expiresAt!.isBefore(_clock()))) {
      return false;
    }
    return grant.sections.contains(section) || grant.sections.contains('all');
  }

  bool createListing({
    required String title,
    required String species,
    required String breed,
    required String city,
    required String price,
    required String age,
    required String healthNotes,
    required String image,
  }) {
    if (!currentRoles.contains(PetVaultRole.seller) ||
        activeRole != PetVaultRole.seller) {
      return denyAccess('create a pet listing', currentUserId);
    }
    if (!currentUserVerified || kyc[currentUserId] != KycStatus.verified) {
      return _fail('Complete seller KYC before submitting a listing.');
    }
    final amount = double.tryParse(price.trim());
    if (title.trim().isEmpty ||
        species.trim().isEmpty ||
        breed.trim().isEmpty ||
        city.trim().isEmpty ||
        age.trim().isEmpty ||
        amount == null ||
        amount <= 0) {
      return _fail(
          'Complete every required listing field and enter a valid price.');
    }
    const prohibited = <String>['wildlife', 'endangered', 'protected species'];
    final text =
        '${title.trim()} ${species.trim()} ${breed.trim()}'.toLowerCase();
    final term = prohibited.where(text.contains).firstOrNull;
    if (term != null) {
      return _fail(
          'This listing contains prohibited content (“$term”) and cannot be submitted.');
    }
    final listing = PetListing(
      id: _id('listing'),
      title: title.trim(),
      species: species.trim(),
      breed: breed.trim(),
      city: city.trim(),
      price: amount,
      age: age.trim(),
      sellerId: currentUserId,
      image: image,
      verifiedSeller: kyc[currentUserId] == KycStatus.verified,
      healthNotes: healthNotes.trim(),
      status: ListingStatus.pendingReview,
    );
    listings[listing.id] = listing;
    _recordAudit('Listing submitted for moderation', listing.id);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool updateListing(
    String listingId, {
    required String title,
    required String city,
    required String price,
    required String healthNotes,
  }) {
    if (!isSignedIn ||
        activeRole != PetVaultRole.seller ||
        !currentRoles.contains(PetVaultRole.seller)) {
      return denyAccess('edit a pet listing', listingId);
    }
    final listing = listings[listingId];
    final amount = double.tryParse(price.trim());
    if (listing == null || listing.sellerId != currentUserId) {
      return _fail('You can only edit a listing you own.');
    }
    if (title.trim().isEmpty ||
        city.trim().isEmpty ||
        amount == null ||
        amount <= 0) {
      return _fail('Enter a valid title, city, and price.');
    }
    listing
      ..title = title.trim()
      ..city = city.trim()
      ..price = amount
      ..healthNotes = healthNotes.trim();
    if (listing.status == ListingStatus.active) {
      listing.status = ListingStatus.pendingReview;
    }
    _recordAudit('Listing updated and queued for review', listingId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool setListingSold(String listingId) {
    if (!isSignedIn ||
        activeRole != PetVaultRole.seller ||
        !currentRoles.contains(PetVaultRole.seller)) {
      return denyAccess('mark a pet listing sold', listingId);
    }
    final listing = listings[listingId];
    if (listing == null ||
        listing.sellerId != currentUserId ||
        listing.status != ListingStatus.active) {
      return _fail('You can only update a listing you own.');
    }
    listing.status = ListingStatus.sold;
    _recordAudit('Listing marked sold', listingId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool toggleFavorite(String listingId) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('save a favorite listing', listingId);
    }
    final listing = listings[listingId];
    if (listing == null || listing.status != ListingStatus.active) {
      return _fail('This listing is no longer available.');
    }
    if (!listing.favorites.add(currentUserId)) {
      listing.favorites.remove(currentUserId);
    }
    _recordAudit('Listing favorite toggled', listingId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool reviewListing(String listingId, ListingStatus decision) {
    if (!isSignedIn || activeRole != PetVaultRole.admin) {
      return denyAccess('moderate listings', listingId);
    }
    final listing = listings[listingId];
    if (listing == null ||
        (decision != ListingStatus.active &&
            decision != ListingStatus.rejected)) {
      return _fail('Choose an available listing and approve or reject it.');
    }
    listing.status = decision;
    _recordAudit('Listing moderation: ${decision.name}', listingId);
    _pushNotification(
        'Listing review complete', 'Your listing is ${decision.name}.',
        recipientId: listing.sellerId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool addToCart(String productId, {int quantity = 1}) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('add a product to the cart', productId);
    }
    final product = products[productId];
    if (product == null || !product.published) {
      return _fail('This product is unavailable.');
    }
    if (!product.vendorVerified) {
      return _fail('This product is hidden because its vendor is unverified.');
    }
    if (quantity < 1) return _fail('Choose a valid quantity.');
    if (product.stock <= 0) return _fail('This product is out of stock.');
    final updatedQuantity = (cart[productId] ?? 0) + quantity;
    if (updatedQuantity > product.stock) {
      return _fail('Only ${product.stock} unit(s) are currently in stock.');
    }
    cart[productId] = updatedQuantity;
    notifyListeners();
    lastError = null;
    return true;
  }

  bool saveProduct({
    required String name,
    required String price,
    required String stock,
    required String image,
    String? productId,
  }) {
    if (!isSignedIn ||
        activeRole != PetVaultRole.vendor ||
        kyc[currentUserId] != KycStatus.verified) {
      return denyAccess('publish a product', currentUserId);
    }
    final amount = double.tryParse(price.trim());
    final quantity = int.tryParse(stock.trim());
    if (name.trim().isEmpty ||
        amount == null ||
        amount <= 0 ||
        quantity == null ||
        quantity < 0) {
      return _fail(
          'Enter a product name, positive price, and valid stock quantity.');
    }
    final existing = productId == null ? null : products[productId];
    if (existing != null) {
      if (existing.vendorId != currentUserId) {
        return denyAccess('edit another vendor’s product', existing.id);
      }
      existing
        ..name = name.trim()
        ..price = amount
        ..stock = quantity
        ..published = true;
    } else {
      final product = VaultProduct(
        id: _id('product'),
        name: name.trim(),
        price: amount,
        stock: quantity,
        image: image,
        vendorId: currentUserId,
      );
      products[product.id] = product;
    }
    _recordAudit('Vendor product saved', productId ?? name.trim());
    notifyListeners();
    lastError = null;
    return true;
  }

  void removeFromCart(String productId) {
    cart.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  double get cartSubtotal => cart.entries.fold<double>(0, (total, item) {
        final product = products[item.key];
        return total + (product?.price ?? 0) * item.value;
      });

  bool checkout({bool providerAvailable = true}) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('place a product order', currentUserId);
    }
    if (cart.isEmpty) return _fail('Your cart is empty.');
    final staleItems = cart.entries
        .where((entry) =>
            products[entry.key] == null ||
            products[entry.key]!.stock < entry.value)
        .map((entry) => entry.key)
        .toList();
    if (staleItems.isNotEmpty) {
      for (final id in staleItems) {
        cart.remove(id);
      }
      notifyListeners();
      return _fail(
          'An item went out of stock and was removed. Review your cart before checkout.');
    }
    if (!providerAvailable) {
      return _fail(
          'Payment provider is unavailable. No charge was made; please retry.');
    }
    final entries = cart.entries.toList();
    final total = cartSubtotal;
    final order = VaultOrder(
      id: _id('order'),
      productIds: entries.map((entry) => entry.key).toList(),
      quantities: entries.map((entry) => entry.value).toList(),
      total: total,
      createdAt: _clock(),
      buyerId: currentUserId,
    );
    for (final entry in entries) {
      products[entry.key]!.stock -= entry.value;
    }
    order.paymentStatus = PaymentStatus.paid;
    final commission = total * paymentCommissionPercent / 100;
    orders.add(order);
    cart.clear();
    _recordAudit(
      'Order placed; provider payment paid; commission $commission',
      order.id,
    );
    _pushNotification('Order confirmed', 'Order ${order.id} was placed.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool updateOrderStatus(String orderId, String status) {
    if (!isSignedIn || activeRole != PetVaultRole.vendor) {
      return denyAccess('change an order status', orderId);
    }
    const allowed = <String>{'Processing', 'Shipped', 'Delivered', 'Cancelled'};
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null ||
        !order.productIds.any(
          (productId) => products[productId]?.vendorId == currentUserId,
        ) ||
        !allowed.contains(status)) {
      return _fail('The order or requested status is invalid.');
    }
    order.status = status;
    _recordAudit('Order status changed to $status', orderId);
    _pushNotification('Order $status', 'Order $orderId is now $status.',
        recipientId: order.buyerId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool markOrderReviewed(String orderId, int rating, String comment) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('review an order', orderId);
    }
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null ||
        order.buyerId != currentUserId ||
        order.status != 'Delivered') {
      return _fail('You can review an order after it is delivered.');
    }
    if (order.reviewed) return _fail('This order has already been reviewed.');
    if (rating < 1 || rating > 5 || comment.trim().isEmpty) {
      return _fail('Choose a 1–5 rating and enter a review.');
    }
    order.reviewed = true;
    for (final productId in order.productIds) {
      reviews.add(
        ReviewRecord(
          author: currentUserId,
          subjectId: productId,
          rating: rating,
          comment: comment.trim(),
        ),
      );
    }
    _recordAudit('Product review submitted', orderId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool submitBooking({
    required String sitter,
    required DateTime date,
    required String arrangement,
    required String instructions,
    required String emergencyName,
    required String emergencyPhone,
  }) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('request pet sitting', currentUserId);
    }
    if (instructions.trim().isEmpty ||
        emergencyName.trim().isEmpty ||
        emergencyPhone.trim().length < 7) {
      return _fail('Add care instructions and a valid emergency contact.');
    }
    final unavailable = sitterUnavailableDates[sitter] ?? <DateTime>{};
    if (unavailable.any((item) => _sameDay(item, date))) {
      return _fail('This sitter is not available on the selected date.');
    }
    final booking = SittingBooking(
      id: _id('booking'),
      sitter: sitter,
      date: date,
      arrangement: arrangement,
      instructions: instructions.trim(),
      emergencyName: emergencyName.trim(),
      emergencyPhone: emergencyPhone.trim(),
      ownerId: currentUserId,
    );
    bookings.add(booking);
    _recordAudit('Sitting booking requested', booking.id);
    final sitterAccount = _accounts.entries
        .where((entry) => entry.value.name == sitter)
        .firstOrNull;
    _pushNotification(
        'Booking request sent', 'Your request was sent to $sitter.',
        recipientId: sitterAccount?.key ?? currentUserId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool setSitterUnavailable(String sitter, DateTime date, bool unavailable) {
    if (!isSignedIn ||
        activeRole != PetVaultRole.sitter ||
        sitter != currentUserName) {
      return denyAccess('change sitter availability', sitter);
    }
    final days = sitterUnavailableDates.putIfAbsent(sitter, () => <DateTime>{});
    if (unavailable) {
      days.add(DateTime(date.year, date.month, date.day));
    } else {
      days.removeWhere((item) => _sameDay(item, date));
    }
    notifyListeners();
    return true;
  }

  bool respondToBooking(String bookingId, {required bool accept}) {
    final booking = bookings.where((item) => item.id == bookingId).firstOrNull;
    if (!isSignedIn ||
        activeRole != PetVaultRole.sitter ||
        booking?.sitter != currentUserName) {
      return denyAccess('respond to this sitting request', bookingId);
    }
    if (booking == null || !booking.active) {
      return _fail('This booking is no longer awaiting a response.');
    }
    booking.status = accept ? BookingStatus.confirmed : BookingStatus.declined;
    _recordAudit(
      accept ? 'Sitting booking confirmed' : 'Sitting booking declined',
      bookingId,
    );
    _pushNotification(
      accept ? 'Booking confirmed' : 'Booking declined',
      accept
          ? '$bookingId was added to the owner and sitter calendars.'
          : 'Choose another sitter to make a new booking.',
      recipientId: booking.ownerId,
    );
    notifyListeners();
    lastError = null;
    return true;
  }

  String? emergencyContactForBooking(String bookingId) {
    final booking = bookings.where((item) => item.id == bookingId).firstOrNull;
    if (!isSignedIn ||
        booking == null ||
        !booking.active ||
        activeRole != PetVaultRole.sitter ||
        booking.sitter != currentUserName) {
      return null;
    }
    return '${booking.emergencyName} · ${booking.emergencyPhone}';
  }

  bool cancelBooking(String bookingId, {required bool withinPolicyWindow}) {
    final booking = bookings.where((item) => item.id == bookingId).firstOrNull;
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('cancel a sitting booking', bookingId);
    }
    if (booking == null ||
        booking.ownerId != currentUserId ||
        booking.status != BookingStatus.confirmed) {
      return _fail('Only a confirmed booking can be cancelled.');
    }
    booking.status = BookingStatus.cancelled;
    _recordAudit(
      withinPolicyWindow
          ? 'Booking cancelled; refund eligible'
          : 'Booking cancelled; policy fee may apply',
      bookingId,
    );
    _pushNotification(
        'Booking cancelled',
        withinPolicyWindow
            ? 'A refund is being processed.'
            : 'The cancellation fee policy applies.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool postSittingUpdate(String bookingId, String update) {
    final booking = bookings.where((item) => item.id == bookingId).firstOrNull;
    if (!isSignedIn ||
        booking == null ||
        activeRole != PetVaultRole.sitter ||
        booking.sitter != currentUserName ||
        booking.status != BookingStatus.confirmed ||
        update.trim().isEmpty) {
      return _fail('Check in only during an active booking and add an update.');
    }
    booking.updates.add(update.trim());
    _recordAudit('Sitting check-in update posted', bookingId);
    _pushNotification('Sitting update', 'A new care update was shared.',
        recipientId: booking.ownerId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool completeBooking(String bookingId) {
    final booking = bookings.where((item) => item.id == bookingId).firstOrNull;
    if (!isSignedIn ||
        activeRole != PetVaultRole.sitter ||
        booking?.sitter != currentUserName) {
      return denyAccess('complete this sitting booking', bookingId);
    }
    if (booking == null || booking.status != BookingStatus.confirmed) {
      return _fail('Only a confirmed sitting booking can be completed.');
    }
    booking.status = BookingStatus.complete;
    _recordAudit('Sitting booking completed', bookingId);
    _pushNotification(
        'Sitting complete', 'The sitter marked the booking complete.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool reviewSitter(String bookingId, int rating, String comment) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('review a sitter', bookingId);
    }
    final booking = bookings.where((item) => item.id == bookingId).firstOrNull;
    if (booking == null ||
        booking.ownerId != currentUserId ||
        booking.status != BookingStatus.complete) {
      return _fail('A booking must be complete before rating the sitter.');
    }
    if (booking.reviewed) {
      return _fail('This completed booking was already reviewed.');
    }
    if (rating < 1 || rating > 5 || comment.trim().isEmpty) {
      return _fail('Choose a 1–5 rating and enter a review.');
    }
    booking.reviewed = true;
    reviews.add(
      ReviewRecord(
        author: currentUserId,
        subjectId: booking.sitter,
        rating: rating,
        comment: comment.trim(),
      ),
    );
    _recordAudit('Sitter review submitted', bookingId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool bookVetSlot({
    required String vet,
    required String petId,
    required DateTime slot,
    required String type,
  }) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('book a veterinarian appointment', currentUserId);
    }
    if (pets[petId]?.ownerId != currentUserId) {
      return denyAccess('book an appointment for this pet', petId);
    }
    if (!_licensedVets.contains(vet)) {
      return _fail(
          'Only KYC-verified, licensed veterinarians appear in search.');
    }
    final normalized =
        DateTime(slot.year, slot.month, slot.day, slot.hour, slot.minute);
    final available = vetAvailableSlots[vet] ?? <DateTime>{};
    if (!available.contains(normalized)) {
      return _fail(
          'This veterinarian has not published that appointment slot.');
    }
    if (bookedVetSlots.contains(normalized)) {
      return _fail('This appointment slot has already been booked.');
    }
    bookedVetSlots.add(normalized);
    available.remove(normalized);
    final appointment = VetAppointment(
      id: _id('appointment'),
      vet: vet,
      petId: petId,
      slot: normalized,
      type: type,
      ownerId: currentUserId,
    );
    appointments.add(appointment);
    _recordAudit('Vet appointment booked', appointment.id);
    _pushNotification(
        'Appointment confirmed', 'Your appointment with $vet is confirmed.',
        recipientId: currentUserId);
    notifyListeners();
    lastError = null;
    return true;
  }

  final Set<String> _licensedVets = <String>{'Dr. Ayesha Ali'};

  List<DateTime> availableVetSlots(String vet) {
    final slots = vetAvailableSlots[vet] ?? <DateTime>{};
    return slots.where((slot) => !bookedVetSlots.contains(slot)).toList()
      ..sort();
  }

  bool setVetAvailability(DateTime slot, {required bool available}) {
    if (!isSignedIn ||
        activeRole != PetVaultRole.veterinarian ||
        !_licensedVets.contains(currentUserName)) {
      return denyAccess('manage veterinarian availability', currentUserId);
    }
    final normalized =
        DateTime(slot.year, slot.month, slot.day, slot.hour, slot.minute);
    final slots =
        vetAvailableSlots.putIfAbsent(currentUserName, () => <DateTime>{});
    if (normalized.isBefore(_clock())) {
      return _fail('Availability must be set for a future time.');
    }
    if (available) {
      if (bookedVetSlots.contains(normalized)) {
        return _fail('A booked slot cannot be marked available.');
      }
      slots.add(normalized);
    } else {
      slots.remove(normalized);
    }
    _recordAudit(
      available ? 'Vet availability added' : 'Vet availability removed',
      normalized.toIso8601String(),
    );
    notifyListeners();
    lastError = null;
    return true;
  }

  bool saveConsultationNotes(
    String appointmentId, {
    required String notes,
    DateTime? followUp,
  }) {
    final appointment =
        appointments.where((item) => item.id == appointmentId).firstOrNull;
    if (!isSignedIn ||
        activeRole != PetVaultRole.veterinarian ||
        appointment?.vet != currentUserName) {
      return denyAccess('save veterinarian consultation notes', appointmentId);
    }
    if (appointment == null || notes.trim().isEmpty) {
      return _fail('Enter consultation notes for a valid appointment.');
    }
    final pet = pets[appointment.petId];
    if (pet == null) return _fail('The appointment pet profile was not found.');
    if (activeRole == PetVaultRole.veterinarian &&
        !canAccessPetSection(appointment.petId, currentUserName, 'health')) {
      return denyAccess('write consultation notes', appointmentId);
    }
    appointment.consultationNotes = notes.trim();
    appointment.status = 'Complete';
    pet.records.add(
      HealthRecord(
        id: _id('consultation'),
        title: 'Consultation note',
        type: 'Clinic visit',
        date: _clock(),
        provider: appointment.vet,
        nextDueAt: followUp,
        vetName: appointment.vet,
      ),
    );
    _recordAudit(
        'Consultation notes saved to pet health record', appointmentId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool reviewVet(String appointmentId, int rating, String comment) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('review a veterinarian', appointmentId);
    }
    final appointment =
        appointments.where((item) => item.id == appointmentId).firstOrNull;
    if (appointment == null ||
        appointment.ownerId != currentUserId ||
        appointment.status != 'Complete') {
      return _fail(
          'A completed consultation is required before submitting a review.');
    }
    if (appointment.reviewed) {
      return _fail('This consultation has already been reviewed.');
    }
    if (rating < 1 || rating > 5 || comment.trim().isEmpty) {
      return _fail('Choose a 1–5 rating and enter a review.');
    }
    appointment.reviewed = true;
    reviews.add(
      ReviewRecord(
        author: currentUserId,
        subjectId: appointment.vet,
        rating: rating,
        comment: comment.trim(),
      ),
    );
    _recordAudit('Veterinarian review submitted', appointmentId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool submitReport(String listingId, String reason) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('report a marketplace listing', listingId);
    }
    if (!listings.containsKey(listingId) || reason.trim().isEmpty) {
      return _fail('Choose a listing and a report reason.');
    }
    final report = ListingReport(
      id: _id('report'),
      listingId: listingId,
      reporterId: currentUserId,
      reason: reason.trim(),
      createdAt: _clock(),
    );
    listingReports.add(report);
    _recordAudit('Listing reported: ${reason.trim()}', listingId);
    _pushNotification('Report received',
        'The trust team will review your report. The listing remains visible until review.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool resolveListingReport(String reportId) {
    if (activeRole != PetVaultRole.admin) {
      return denyAccess('resolve a marketplace report', reportId);
    }
    final report =
        listingReports.where((item) => item.id == reportId).firstOrNull;
    if (report == null || report.resolved) {
      return _fail('This report is already resolved or unavailable.');
    }
    report.resolved = true;
    _recordAudit('Marketplace report reviewed', reportId);
    _pushNotification(
        'Report reviewed', 'The trust team reviewed your report.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool requestPetVisit({
    required String listingId,
    required DateTime date,
    required String message,
  }) {
    if (!isSignedIn || activeRole != PetVaultRole.owner) {
      return denyAccess('request a listing visit', listingId);
    }
    final listing = listings[listingId];
    if (listing == null || listing.status != ListingStatus.active) {
      return _fail('This listing is not available for visit requests.');
    }
    if (date.isBefore(_clock()) || message.trim().isEmpty) {
      return _fail(
          'Choose a future visit date and add a message to the seller.');
    }
    final request = PetVisitRequest(
      id: _id('visit'),
      listingId: listingId,
      ownerId: currentUserId,
      date: date,
      message: message.trim(),
    );
    visitRequests.add(request);
    _recordAudit('Pet listing visit requested', request.id);
    _pushNotification('Visit request sent',
        'Your visit request was sent to the listing seller.',
        recipientId: listing.sellerId);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool sendMessage(String conversationId, String text) {
    if (conversationId.trim().isEmpty || text.trim().isEmpty) {
      return _fail('Enter a message before sending.');
    }
    conversations
        .putIfAbsent(conversationId, () => <PetVaultMessage>[])
        .add(PetVaultMessage(
          sender: currentUserId,
          text: text.trim(),
          createdAt: _clock(),
        ));
    _pushNotification('Message sent', 'Your message was saved in this demo.');
    notifyListeners();
    lastError = null;
    return true;
  }

  bool resolveDispute(String transactionId, String decision) {
    if (activeRole != PetVaultRole.admin) {
      return denyAccess('resolve disputes', transactionId);
    }
    const decisions = <String>{
      'Refund buyer',
      'Release payment',
      'Request more information',
    };
    if (!decisions.contains(decision)) {
      return _fail('Choose a valid dispute decision.');
    }
    if (!openDisputes.contains(transactionId)) {
      return _fail('This dispute is no longer open.');
    }
    openDisputes.remove(transactionId);
    _recordAudit('Dispute decision: $decision', transactionId);
    _pushNotification('Dispute reviewed', decision);
    notifyListeners();
    lastError = null;
    return true;
  }

  bool requestAccountDeletion({required bool hasOpenDispute}) {
    if (!isSignedIn) {
      return denyAccess('delete an account', currentUserId);
    }
    if (activeRole == PetVaultRole.admin) {
      return denyAccess('delete an administrator account', currentUserId);
    }
    final userHasOpenDispute =
        disputeOwners[currentUserId]?.any(openDisputes.contains) ?? false;
    final blockedByDispute = hasOpenDispute || userHasOpenDispute;
    if (activeBookingCount > 0 || activeOrderCount > 0 || blockedByDispute) {
      final commitments = <String>[
        if (activeBookingCount > 0) '$activeBookingCount active booking(s)',
        if (activeOrderCount > 0) '$activeOrderCount open order(s)',
        if (blockedByDispute) 'an unresolved dispute',
      ];
      return _fail(
          'Complete ${commitments.join(', ')} before requesting deletion.');
    }
    final deletedUserId = currentUserId;
    final name = currentUserName;
    final anonymousId = 'deleted-${_id('account')}';
    final removedPetIds = pets.values
        .where((pet) => pet.ownerId == deletedUserId)
        .map((pet) => pet.id)
        .toSet();
    pets.removeWhere((_, pet) => pet.ownerId == deletedUserId);
    _grants.removeWhere((key, grant) =>
        removedPetIds.any((petId) => key.startsWith('$petId:')) ||
        grant.recipient == name);
    for (final pet in pets.values) {
      pet.access.remove(name);
    }
    for (final listing in listings.values) {
      if (listing.sellerId == deletedUserId) {
        listing.sellerId = anonymousId;
        if (listing.status == ListingStatus.active ||
            listing.status == ListingStatus.pendingReview) {
          listing.status = ListingStatus.rejected;
        }
      }
      listing.favorites.remove(deletedUserId);
    }
    for (final order in orders) {
      if (order.buyerId == deletedUserId) order.buyerId = anonymousId;
    }
    for (final booking in bookings) {
      if (booking.ownerId == deletedUserId) booking.ownerId = anonymousId;
      if (booking.sitter == name) booking.sitter = 'Deleted sitter';
    }
    for (final request in visitRequests) {
      if (request.ownerId == deletedUserId) request.ownerId = anonymousId;
    }
    for (final appointment in appointments) {
      if (appointment.ownerId == deletedUserId) {
        appointment.ownerId = anonymousId;
      }
    }
    for (final review in reviews) {
      if (review.author == deletedUserId) review.author = anonymousId;
    }
    for (final report in listingReports) {
      if (report.reporterId == deletedUserId) {
        report.reporterId = anonymousId;
      }
    }
    for (final messages in conversations.values) {
      for (final message in messages) {
        if (message.sender == deletedUserId) message.sender = anonymousId;
      }
    }
    for (final entry in audit) {
      if (entry.actor == deletedUserId) entry.actor = anonymousId;
    }
    _accounts.remove(deletedUserId);
    _roles.remove(deletedUserId);
    kyc.remove(deletedUserId);
    notifications.removeWhere(
        (notification) => notification.recipientId == deletedUserId);
    disputeOwners.remove(deletedUserId);
    for (final owners in disputeOwners.values) {
      owners.remove(deletedUserId);
    }
    cart.clear();
    currentUserId = anonymousId;
    activeRole = PetVaultRole.owner;
    _recordAudit(
        'Account deletion completed; transaction and audit history retained',
        'Anonymized account');
    notifyListeners();
    lastError = null;
    return true;
  }

  String triage(String symptoms) {
    final text = symptoms.toLowerCase();
    const redFlags = <String>[
      'trouble breathing',
      'cannot breathe',
      'difficulty breathing',
      'collapse',
      'uncontrolled bleeding',
      'seizure',
      'seizures',
      'poison',
      'poisoning',
    ];
    final urgent = redFlags.any(text.contains);
    final response = urgent
        ? 'A red-flag symptom may need urgent care. Contact a licensed veterinarian or emergency clinic now; do not wait for an online response. This is routing guidance, not a diagnosis.'
        : 'For non-emergency concerns, arrange advice from a licensed veterinarian. Bring your pet’s health records and describe when symptoms began. This is general routing guidance, not a diagnosis.';
    _recordAudit(
        urgent
            ? 'Triage routed to emergency care'
            : 'Triage routed to routine vet care',
        symptoms.trim());
    _pushNotification(
        'Care routing guidance',
        urgent
            ? 'Urgent veterinary care was recommended.'
            : 'A veterinary appointment was recommended.');
    notifyListeners();
    return response;
  }

  String groundedSupportAnswer(String question,
      {bool serviceAvailable = true}) {
    if (!serviceAvailable) {
      return 'The support service is unavailable right now. Please use Profile & Settings, Health Records, or contact PetVault support. Source: PetVault help directory.';
    }
    final text = question.toLowerCase();
    if (text.contains('record') ||
        text.contains('privacy') ||
        text.contains('share')) {
      return 'Health records are private by default. Open a pet profile → Health records → Access to grant or revoke a named person’s access. Source: PetVault Data & Privacy guidance.';
    }
    if (text.contains('listing') || text.contains('sell')) {
      return 'Activate the seller role, complete KYC, and submit a complete listing. It remains in review until an admin decision. Source: PetVault Marketplace listing policy.';
    }
    if (text.contains('order') || text.contains('delivery')) {
      return 'Open Shop → Orders to see processing, shipped, and delivered updates. Source: PetVault Order Tracking help.';
    }
    if (text.contains('booking') || text.contains('sitter')) {
      return 'Choose a verified sitter, select an available date, and include care instructions and an emergency contact. Source: PetVault Sitting Booking help.';
    }
    return 'I can help with account access, pet records, marketplace listings, orders, and bookings. For medical advice, contact a licensed veterinarian. Source: PetVault approved help topics.';
  }

  bool markNotificationRead(VaultNotification notification) {
    if (!isSignedIn || notification.recipientId != currentUserId) {
      return denyAccess('read this notification', notification.recipientId);
    }
    if (!notifications.contains(notification)) return false;
    notification.read = true;
    notifyListeners();
    return true;
  }

  void _scheduleDueReminder(PetProfile pet, HealthRecord record) {
    final due = record.nextDueAt;
    if (due == null) return;
    final days = due.difference(_clock()).inDays;
    if (days <= 14) {
      _pushNotification(
        days < 0 ? 'Vaccination overdue' : 'Vaccination due soon',
        '${pet.name}: ${record.title} ${days < 0 ? 'is overdue' : 'is due on ${_dateLabel(due)}'}.',
      );
    }
  }

  void _pushNotification(
    String title,
    String message, {
    String? recipientId,
  }) {
    notifications.add(
      VaultNotification(
        title: title,
        message: message,
        createdAt: _clock(),
        recipientId: recipientId ?? currentUserId,
      ),
    );
  }

  void _recordAudit(String action, String record) {
    audit.add(
      AuditEntry(
        actor: currentUserId,
        action: action,
        record: record,
        createdAt: _clock(),
      ),
    );
  }

  bool _fail(String message) {
    lastError = message;
    notifyListeners();
    return false;
  }

  String _id(String prefix) =>
      '$prefix-${_clock().microsecondsSinceEpoch}-${audit.length}';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static PetVaultRole? _roleFromLabel(String role) {
    final value = role.toLowerCase().trim();
    if (value == 'owner' || value == 'pet parent') return PetVaultRole.owner;
    if (value == 'seller' || value == 'breeder / seller') {
      return PetVaultRole.seller;
    }
    if (value == 'sitter' || value == 'pet sitter') return PetVaultRole.sitter;
    if (value == 'vet' || value == 'veterinarian') {
      return PetVaultRole.veterinarian;
    }
    if (value == 'vendor') return PetVaultRole.vendor;
    if (value == 'admin') return PetVaultRole.admin;
    return null;
  }

  static String _roleLabel(PetVaultRole role) => switch (role) {
        PetVaultRole.owner => 'owner',
        PetVaultRole.seller => 'seller',
        PetVaultRole.sitter => 'sitter',
        PetVaultRole.veterinarian => 'veterinarian',
        PetVaultRole.vendor => 'vendor',
        PetVaultRole.admin => 'admin',
      };
}

class _DemoAccount {
  _DemoAccount({
    required this.name,
    required this.password,
    this.email = '',
    this.phone = '',
    this.verified = false,
  });

  final String name;
  final String email;
  String password;
  final String phone;
  bool verified;
  int failedAttempts = 0;
  DateTime? lockedUntil;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
