import 'package:flutter_test/flutter_test.dart';
import 'package:petvault/petvault_store.dart';

void main() {
  group('PetVaultStore demo rules', () {
    test('sign-in failures are rejected and audited', () {
      final store = PetVaultStore();

      expect(store.signIn('owner@petvault.demo', 'wrong'), isFalse);
      expect(store.lastError, 'Email or password is incorrect.');
      expect(store.auditTrail.first.action, 'Failed sign-in attempt');
      expect(store.signIn('owner@petvault.demo', 'demo1234'), isTrue);
    });

    test('pet creation validates required fields and weight', () {
      final store = PetVaultStore();

      expect(
        store.addPet(
          name: '',
          species: 'Dog',
          breed: 'Mixed',
          age: '1 year',
          sex: 'Female',
          weight: '0',
        ),
        isFalse,
      );
      expect(
        store.addPet(
          name: 'Milo',
          species: 'Dog',
          breed: 'Mixed',
          age: '1 year',
          sex: 'Male',
          weight: '8.4',
        ),
        isTrue,
      );
      expect(store.ownerPets.any((pet) => pet.name == 'Milo'), isTrue);
    });

    test('vaccination records require a due date or no-booster disclosure', () {
      final store = PetVaultStore();
      final date = DateTime(2025, 1, 1);

      expect(
        store.addHealthRecord(
          petId: 'pet-rosco',
          title: 'Rabies dose',
          type: 'Vaccination',
          date: date,
          provider: 'Demo clinic',
        ),
        isFalse,
      );
      expect(
        store.addHealthRecord(
          petId: 'pet-rosco',
          title: 'Rabies dose',
          type: 'Vaccination',
          date: date,
          provider: 'Demo clinic',
          nextDueAt: DateTime(2026, 1, 1),
        ),
        isTrue,
      );
      expect(store.pets['pet-rosco']!.vaccinations.length, 2);
    });

    test('pet access can be revoked and expires', () {
      var now = DateTime(2025, 1, 1);
      final store = PetVaultStore(clock: () => now);

      expect(
        store.grantPetAccess(
          petId: 'pet-rosco',
          recipient: 'Dr. Ayesha Ali',
          sections: <String>{'health'},
          consentGiven: true,
          expiresAt: DateTime(2025, 1, 2),
        ),
        isTrue,
      );
      expect(store.signIn('vet@petvault.demo', 'demo1234'), isTrue);
      expect(
        store.canAccessPetSection('pet-rosco', 'Dr. Ayesha Ali', 'health'),
        isTrue,
      );
      now = DateTime(2025, 1, 3);
      expect(
        store.canAccessPetSection('pet-rosco', 'Dr. Ayesha Ali', 'health'),
        isFalse,
      );
      expect(store.signIn('owner@petvault.demo', 'demo1234'), isTrue);
      expect(store.revokePetAccess('pet-rosco', 'Dr. Ayesha Ali'), isTrue);
      expect(store.signIn('vet@petvault.demo', 'demo1234'), isTrue);
      expect(
        store.canAccessPetSection('pet-rosco', 'Dr. Ayesha Ali', 'health'),
        isFalse,
      );
    });

    test('shared health access works for a non-owning owner account only', () {
      final store = PetVaultStore();
      expect(
        store.grantPetAccess(
          petId: 'pet-rosco',
          recipient: 'Zara Ahmed',
          sections: <String>{'health'},
          consentGiven: true,
        ),
        isTrue,
      );

      expect(store.signIn('seller@petvault.demo', 'demo1234'), isTrue);
      expect(store.canViewPetProfile('pet-rosco'), isTrue);
      expect(store.accessibleHealthRecords('pet-rosco'), isNotEmpty);
      expect(store.activeGrantsForPet('pet-rosco'), isEmpty);

      expect(store.signIn('admin@petvault.demo', 'demo1234'), isTrue);
      expect(store.canViewPetProfile('pet-rosco'), isFalse);
      expect(store.accessibleHealthRecords('pet-rosco'), isEmpty);
    });

    test('seller listings require approved KYC and admin moderation', () {
      final store = PetVaultStore();
      expect(store.signIn('seller@petvault.demo', 'demo1234'), isTrue);
      expect(store.switchRole(PetVaultRole.seller), isTrue);
      expect(
        store.createListing(
          title: 'Milo puppy',
          species: 'Dog',
          breed: 'Mixed',
          city: 'Karachi',
          price: '25000',
          age: '10 weeks',
          healthNotes: 'Vaccination record available',
          image: 'assets/images/listing_golden.png',
        ),
        isFalse,
      );

      expect(store.signIn('admin@petvault.demo', 'demo1234'), isTrue);
      expect(
          store.reviewKyc('seller@petvault.demo', KycStatus.verified), isTrue);
      expect(store.signIn('seller@petvault.demo', 'demo1234'), isTrue);
      expect(store.switchRole(PetVaultRole.seller), isTrue);
      expect(
        store.createListing(
          title: 'Milo puppy',
          species: 'Dog',
          breed: 'Mixed',
          city: 'Karachi',
          price: '25000',
          age: '10 weeks',
          healthNotes: 'Vaccination record available',
          image: 'assets/images/listing_golden.png',
        ),
        isTrue,
      );
      final listing = store.currentSellerListings
          .singleWhere((item) => item.title == 'Milo puppy');
      expect(listing.status, ListingStatus.pendingReview);
      expect(
        store.updateListing(
          listing.id,
          title: 'Milo puppy updated',
          city: 'Karachi',
          price: '26000',
          healthNotes: 'Updated health notes',
        ),
        isTrue,
      );
      expect(listing.status, ListingStatus.pendingReview);
      expect(store.signIn('admin@petvault.demo', 'demo1234'), isTrue);
      expect(store.reviewListing(listing.id, ListingStatus.active), isTrue);
      expect(store.listings[listing.id]!.status, ListingStatus.active);
      expect(store.signIn('owner@petvault.demo', 'demo1234'), isTrue);
      expect(
        store.updateListing(
          listing.id,
          title: 'Unauthorized edit',
          city: 'Karachi',
          price: '1',
          healthNotes: '',
        ),
        isFalse,
      );
    });

    test('cart checks stock and does not charge when provider is unavailable',
        () {
      final store = PetVaultStore();

      expect(store.addToCart('product-toy', quantity: 4), isFalse);
      expect(store.addToCart('product-toy', quantity: 2), isTrue);
      expect(store.checkout(providerAvailable: false), isFalse);
      expect(store.cart['product-toy'], 2);
      expect(store.products['product-toy']!.stock, 3);
      expect(store.checkout(), isTrue);
      expect(store.cart, isEmpty);
      expect(store.products['product-toy']!.stock, 1);
      expect(store.orders.single.total, 2500);
    });

    test('sitting booking requires instructions and emergency contact', () {
      final store = PetVaultStore();

      expect(
        store.submitBooking(
          sitter: 'Sana Ali',
          date: DateTime.now().add(const Duration(days: 2)),
          arrangement: 'In-home visit',
          instructions: '',
          emergencyName: '',
          emergencyPhone: '',
        ),
        isFalse,
      );
      expect(
        store.submitBooking(
          sitter: 'Sana Ali',
          date: DateTime.now().add(const Duration(days: 2)),
          arrangement: 'In-home visit',
          instructions: 'Feed at 6 PM',
          emergencyName: 'Sam',
          emergencyPhone: '5551234567',
        ),
        isTrue,
      );
      expect(store.bookings.single.status, BookingStatus.requested);
    });

    test('triage routes red flags to emergency care and avoids diagnosis', () {
      final store = PetVaultStore();

      final urgent = store.triage('My dog is having trouble breathing');
      expect(urgent, contains('emergency clinic now'));
      expect(urgent, contains('not a diagnosis'));

      final routine = store.triage('Mild appetite change for a week');
      expect(routine, contains('licensed veterinarian'));
      expect(routine, contains('not a diagnosis'));
    });

    test('pet and appointment access stays scoped to the signed-in owner', () {
      final store = PetVaultStore();
      expect(store.canViewPetProfile('pet-rosco'), isTrue);

      expect(store.signIn('seller@petvault.demo', 'demo1234'), isTrue);
      expect(store.canViewPetProfile('pet-rosco'), isFalse);
      expect(
        store.bookVetSlot(
          vet: 'Dr. Ayesha Ali',
          petId: 'pet-rosco',
          slot: DateTime(2030, 1, 1, 10),
          type: 'General checkup',
        ),
        isFalse,
      );
    });

    test('signed-out users cannot mutate owner data', () {
      final store = PetVaultStore();
      store.signOut();

      expect(
        store.addPet(
          name: 'Milo',
          species: 'Dog',
          breed: 'Mixed',
          age: '1 year',
          sex: 'Male',
          weight: '8.4',
        ),
        isFalse,
      );
      expect(store.requestAccountDeletion(hasOpenDispute: false), isFalse);
    });

    test('account deletion anonymizes identifiers and removes owner records',
        () {
      final store = PetVaultStore();
      expect(store.pets.containsKey('pet-rosco'), isTrue);

      expect(store.requestAccountDeletion(hasOpenDispute: false), isTrue);
      expect(store.isSignedIn, isFalse);
      expect(store.pets.containsKey('pet-rosco'), isFalse);
      expect(
        store.auditTrail.first.action,
        'Account deletion completed; transaction and audit history retained',
      );
      expect(store.auditTrail.first.record, 'Anonymized account');
    });
  });
}
