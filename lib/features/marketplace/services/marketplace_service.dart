import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class MarketplaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _listingsRef => _firestore.collection('listings');

  /// Save a new listing
  Future<void> createListing(ListingModel listing) async {
    await _listingsRef.doc(listing.id).set(listing.toMap());
  }

  /// Real-time stream of all active listings (Feed)
  Stream<List<ListingModel>> getActiveListingsStream() {
    return _listingsRef
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListingModel.fromFirestore(doc))
            .toList());
  }
}