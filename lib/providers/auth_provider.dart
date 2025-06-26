import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _user;
  bool _isAdmin = false;
  bool _isLoading = true;

  UserModel? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    // Check if there's a current user already (from persistence)
    User? currentUser = _firebaseService.currentUser;
    if (currentUser != null) {
      print('Current user found from persistence: ${currentUser.uid}');
      await _loadUserData(currentUser);
    }

    // Listen to auth state changes
    _firebaseService.authStateChanges.listen((User? firebaseUser) async {
      print('Auth state changed: ${firebaseUser?.uid ?? 'logged out'}');
      
      if (firebaseUser == null) {
        _user = null;
        _isAdmin = false;
        _isLoading = false;
        notifyListeners();
      } else {
        await _loadUserData(firebaseUser);
      }
    });
  }
  
  Future<void> _loadUserData(User firebaseUser) async {
    // Get user data from Firestore
    UserModel? userData = await _firebaseService.getUserData(firebaseUser.uid);
    
    if (userData != null) {
      _user = userData;
      // Get the latest admin status directly from Firestore
      _isAdmin = await _firebaseService.isCurrentUserAdmin();
      print('User data loaded: ${userData.toMap()}');
      print('Admin status from Firestore: $_isAdmin');
    } else {
      // Create a new user document if it doesn't exist
      _user = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      );
      await _firebaseService.createUserDocument(_user!);
      _isAdmin = false;
      print('New user document created');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    try {
      UserCredential credential = await _firebaseService.registerWithEmailAndPassword(email, password);
      
      // Create user document in Firestore
      UserModel newUser = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
      );
      
      await _firebaseService.createUserDocument(newUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshAdminStatus() async {
    if (_user != null) {
      _isAdmin = await _firebaseService.isCurrentUserAdmin();
      print('Admin status refreshed: $_isAdmin'); // Debug print
      notifyListeners();
    }
  }
  
  // Debug method to check admin status
  void debugAdminStatus() {
    print('Current admin status: $_isAdmin');
    print('Current user: ${_user?.toMap()}');
    if (_user != null) {
      // Force refresh admin status from Firestore
      _firebaseService.isCurrentUserAdmin().then((isAdmin) {
        print('Firestore admin status: $isAdmin');
        if (_isAdmin != isAdmin) {
          print('Admin status mismatch! Updating...');
          _isAdmin = isAdmin;
          notifyListeners();
        }
      });
    }
  }
  
  // Method to manually set admin status for testing
  Future<void> setAdminStatus(bool isAdmin) async {
    if (_user != null) {
      print('Manually setting admin status to: $isAdmin'); // Debug print
      
      try {
        // Update the user document in Firestore using FirebaseService
        // await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        //   'isAdmin': isAdmin
        // });
        
        // Update local state
        _isAdmin = isAdmin;
        _user = _user!.copyWith(isAdmin: isAdmin);
        notifyListeners();
        
        print('Admin status updated. New status: $_isAdmin'); // Debug print
      } catch (e) {
        print('Error updating admin status: $e');
      }
    } else {
      print('Cannot set admin status: No user logged in'); // Debug print
    }
  }
}