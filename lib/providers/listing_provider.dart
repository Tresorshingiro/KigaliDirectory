import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/listing_model.dart';

// FirestoreService provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// All listings stream provider
final allListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllListingsStream();
});

// User listings stream provider
final userListingsProvider = StreamProvider.family<List<ListingModel>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserListingsStream(userId);
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Selected category filter provider
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Filtered listings provider (combines search and category filter)
final filteredListingsProvider = Provider<List<ListingModel>>((ref) {
  final allListingsAsync = ref.watch(allListingsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return allListingsAsync.when(
    data: (listings) {
      var filtered = listings;

      // Apply category filter
      if (selectedCategory != 'All') {
        filtered = filtered.where((listing) => listing.category == selectedCategory).toList();
      }

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((listing) {
          return listing.name.toLowerCase().contains(searchQuery) ||
              listing.category.toLowerCase().contains(searchQuery) ||
              listing.address.toLowerCase().contains(searchQuery);
        }).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Single listing provider
final listingProvider = FutureProvider.family<ListingModel?, String>((ref, id) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getListing(id);
});

// Listing operations notifier
class ListingNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;

  ListingNotifier(this._firestoreService) : super(const AsyncValue.data(null));

  // Create listing
  Future<void> createListing(ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.createListing(listing);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Update listing
  Future<void> updateListing(ListingModel listing) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateListing(listing);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Delete listing
  Future<void> deleteListing(String id) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteListing(id);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

// Listing notifier provider
final listingNotifierProvider = StateNotifierProvider<ListingNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ListingNotifier(firestoreService);
});

// Location notifications toggle provider (local simulation)
final locationNotificationsProvider = StateProvider<bool>((ref) => false);
