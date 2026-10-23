import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FamilyMembersStore extends ChangeNotifier {
  FamilyMembersStore._() {
    _initListener();
  }

  static final FamilyMembersStore instance = FamilyMembersStore._();

  final List<Map<String, String>> familyMembers = [];
  StreamSubscription? _subscription;

  void _initListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _subscription?.cancel();
      familyMembers.clear();
      notifyListeners();

      if (user != null) {
        _subscription = FirebaseFirestore.instance
            .collection('family_members')
            .where('userId', isEqualTo: user.uid)
            .snapshots()
            .listen((snap) {
          familyMembers.clear();
          for (final doc in snap.docs) {
            final data = doc.data();
            familyMembers.add({
              "id": doc.id,
              "name": (data['name'] ?? 'Family Member').toString(),
              "relation": (data['relationship'] ?? 'Other').toString(),
              "age": (data['dob'] ?? 'N/A').toString(),
              "gender": (data['gender'] ?? 'Other').toString(),
              "phone": (data['phone'] ?? '').toString(),
            });
          }
          notifyListeners();
        });
      }
    });
  }

  Future<void> addMember(Map<String, String> member) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await FirebaseFirestore.instance.collection('family_members').add({
        'userId': uid,
        'name': member['name'] ?? '',
        'relationship': member['relation'] ?? 'Other',
        'dob': member['age'] ?? '',
        'gender': member['gender'] ?? 'Other',
        'phone': member['phone'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteMember(int index) async {
    if (index >= 0 && index < familyMembers.length) {
      final docId = familyMembers[index]['id'];
      if (docId != null && docId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('family_members').doc(docId).delete();
      }
      familyMembers.removeAt(index);
      notifyListeners();
    }
  }

  List<Map<String, String>> getMembers() {
    return List<Map<String, String>>.from(familyMembers);
  }
}