import 'package:admin/utils/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class AdminBloc extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _adminPass;
  String _userType = 'admin';
  bool _isSignedIn = false;
  bool _testing = false;
  bool _isOffline = false;

  List _states = [];
  List get states => _states;

  AdminBloc() {
    _initializeFirestore();
    checkSignIn();
    getAdminPass();
  }

  String? get adminPass => _adminPass;
  String get userType => _userType;
  bool get isSignedIn => _isSignedIn;
  bool get testing => _testing;
  bool get isOffline => _isOffline;

  bool? _adsEnabled = false;
  bool? get adsEnabled => _adsEnabled;

  Future<void> _initializeFirestore() async {
    try {
      // // Verifica se já está autenticado
      // if (_auth.currentUser == null) {
      //   await _auth.signInAnonymously();
      // }

      // Configura listener para estado da conexão
      firestore.enableNetwork();
      FirebaseFirestore.instance.waitForPendingWrites().then((_) {
        print('Pending writes completed');
      });
    } catch (e) {
      print('Error initializing Firestore: $e');
      _isOffline = true;
      notifyListeners();
    }
  }

  Future<void> getAdsData() async {
    try {
      final docSnapshot = await firestore.collection('admin').doc('ads').get();

      if (docSnapshot.exists) {
        _adsEnabled = docSnapshot.data()?['ads_enabled'] ?? false;
      } else {
        await firestore
            .collection('admin')
            .doc('ads')
            .set({'ads_enabled': false});
        _adsEnabled = false;
      }
    } catch (e) {
      print('Error getting ads data: $e');
      _adsEnabled = false;
    }
    notifyListeners();
  }

  Future controllAds(bool value, context) async {
    await firestore
        .collection('admin')
        .doc('ads')
        .update({'ads_enabled': value});
    _adsEnabled = value;
    if (value == true) {
      openToast(context, "Ads enabled successfully");
    } else {
      openToast(context, "Ads disabled successfully");
    }
    notifyListeners();
  }

  Future getAdminPass() async {
    try {
      final snap = await firestore.collection('admin').doc('admin_key').get();
      if (snap.exists && snap.data() != null) {
        _adminPass = snap.data()?['admin_key'];
      }
    } catch (e) {
      print('Error getting admin pass: $e');
    }
    notifyListeners();
  }

  Future<int> getTotalDocuments(String documentName) async {
    final String fieldName = 'count';
    final DocumentReference ref =
        firestore.collection('item_count').doc(documentName);
    DocumentSnapshot snap = await ref.get();
    if (snap.exists == true) {
      int itemCount = snap[fieldName] ?? 0;
      return itemCount;
    } else {
      await ref.set({fieldName: 0});
      return 0;
    }
  }

  Future increaseCount(String documentName) async {
    await getTotalDocuments(documentName).then((int documentCount) async {
      await firestore
          .collection('item_count')
          .doc(documentName)
          .update({'count': documentCount + 1});
    });
  }

  Future decreaseCount(String documentName) async {
    await getTotalDocuments(documentName).then((int documentCount) async {
      await firestore
          .collection('item_count')
          .doc(documentName)
          .update({'count': documentCount - 1});
    });
  }

  Future getStates() async {
    QuerySnapshot snap = await firestore.collection('states').get();
    List d = snap.docs;
    _states.clear();
    d.forEach((element) {
      _states.add(element['name']);
    });
    notifyListeners();
  }

  Future<List> getFeaturedList() async {
    final DocumentReference ref =
        firestore.collection('featured').doc('featured_list');
    DocumentSnapshot snap = await ref.get();
    if (snap.exists == true) {
      List featuredList = snap['places'] ?? [];
      if (featuredList.isNotEmpty) {
        List<int> a = featuredList.map((e) => int.parse(e)).toList()..sort();
        List<String> b = a.take(10).toList().map((e) => e.toString()).toList();
        return b;
      } else {
        return featuredList;
      }
    } else {
      await ref.set({'places': []});
      return [];
    }
  }

  Future addToFeaturedList(context, String? timestamp) async {
    final DocumentReference ref =
        firestore.collection('featured').doc('featured_list');
    await getFeaturedList().then((featuredList) async {
      if (featuredList.contains(timestamp)) {
        openToast(
            context, "This item is already available in the featured list");
      } else {
        featuredList.add(timestamp);
        await ref.update({'places': FieldValue.arrayUnion(featuredList)});
        openToast(context, 'Added Successfully');
      }
    });
  }

  Future removefromFeaturedList(context, String? timestamp) async {
    final DocumentReference ref =
        firestore.collection('featured').doc('featured_list');
    await getFeaturedList().then((featuredList) async {
      if (featuredList.contains(timestamp)) {
        await ref.update({
          'places': FieldValue.arrayRemove([timestamp])
        });
        openToast(context, 'Removed Successfully');
      }
    });
  }

  Future deleteContent(timestamp, String collectionName) async {
    await firestore.collection(collectionName).doc(timestamp).delete();
    notifyListeners();
  }

  Future setSignIn() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('signed_in', true);
    _isSignedIn = true;
    _userType = 'admin';
    notifyListeners();
  }

  Future<void> checkSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSignedIn = prefs.getBool('signed_in') ?? false;
      _userType = prefs.getString('user_type') ?? 'admin';
      notifyListeners();
    } catch (e) {
      print('Error checking sign in: $e');
      _isSignedIn = false;
      notifyListeners();
    }
  }

  Future setSignInForTesting() async {
    _testing = true;
    _userType = 'tester';
    notifyListeners();
  }

  Future saveNewAdminPassword(String newPassword) async {
    await firestore.collection('admin').doc('user type').update(
        {'admin password': newPassword}).then((value) => getAdminPass());
    notifyListeners();
  }
}
