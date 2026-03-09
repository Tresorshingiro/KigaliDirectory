import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all listings stream
  Stream<List<ListingModel>> getAllListingsStream() {
    return _firestore
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ListingModel.fromDocument(doc);
      }).toList();
    });
  }

  // Get listings by user stream
  Stream<List<ListingModel>> getUserListingsStream(String userId) {
    return _firestore
        .collection('listings')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ListingModel.fromDocument(doc);
      }).toList();
    });
  }

  // Get single listing
  Future<ListingModel?> getListing(String id) async {
    try {
      final doc = await _firestore.collection('listings').doc(id).get();
      if (doc.exists) {
        return ListingModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch listing: $e');
    }
  }

  // Create a new listing
  Future<void> createListing(ListingModel listing) async {
    try {
      await _firestore
          .collection('listings')
          .doc(listing.id)
          .set(listing.toMap());
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  // Update a listing
  Future<void> updateListing(ListingModel listing) async {
    try {
      await _firestore
          .collection('listings')
          .doc(listing.id)
          .update(listing.toMap());
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  // Delete a listing
  Future<void> deleteListing(String id) async {
    try {
      await _firestore.collection('listings').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  // Search listings by name
  Future<List<ListingModel>> searchListings(String query) async {
    try {
      final snapshot = await _firestore
          .collection('listings')
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return snapshot.docs.map((doc) {
        return ListingModel.fromDocument(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search listings: $e');
    }
  }

  // Get listings by category
  Stream<List<ListingModel>> getListingsByCategoryStream(String category) {
    return _firestore
        .collection('listings')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ListingModel.fromDocument(doc);
      }).toList();
    });
  }
}
