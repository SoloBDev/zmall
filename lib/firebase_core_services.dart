// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class FirebaseCoreServices {
//   static Future<bool> addDataToUserProfile(uid, data,
//       {isUpdate = false}) async {
//     CollectionReference collectionReference =
//         FirebaseFirestore.instance.collection("global_user_profile");
//     if (uid != null) {
//       if (isUpdate) {
//         await collectionReference.doc(uid).update(data);
//       } else {
//         await collectionReference.doc(uid).set(data);
//       }
//       return true;
//     } else {
//       return false;
//     }
//   }
//
//   static Future<bool> addDataToUserProfileCollection(
//       uid, data, String collectionName) async {
//     CollectionReference collectionReference =
//         FirebaseFirestore.instance.collection("global_user_profile");
//     if (uid != null) {
//       await collectionReference.doc(uid).collection(collectionName).add(data);
//       return true;
//     } else {
//       return false;
//     }
//   }
//
//   static Future<Map<String, dynamic>> getProfileData(uid) async {
//     Map<String, dynamic> list = {};
//     // FirebaseFirestore.instance
//     //     .collection('global_user_profile')
//     //     .doc(uid)
//     //     .get()
//     //     .then((DocumentSnapshot documentSnapshot) {
//     //   if (documentSnapshot.exists) {
//     //     list = documentSnapshot.data();
//     //     list['locations'] = getProfileCollectionData(uid, "locations");
//     //     list['receiver'] = getProfileCollectionData(uid, "receiver");
//     //     print("############################");
//     //     print(list);
//     //     print("############################");
//     //   }
//     // });
//     DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
//         .collection('global_user_profile')
//         .doc(uid)
//         .get();
//     if (documentSnapshot.exists) {
//       list = documentSnapshot.data();
//       list['locations'] = await getProfileCollectionData(uid, "locations");
//       list['receiver'] = await getProfileCollectionData(uid, "receiver");
//       print("############################");
//       print(list);
//       print("############################");
//     }
//     return list;
//   }
//
//   static Future<List<Map<String, dynamic>>> getProfileCollectionData(
//       uid, String collectionName) async {
//     List<Map<String, dynamic>> list = [];
//     // FirebaseFirestore.instance
//     //     .collection('global_user_profile')
//     //     .doc(uid)
//     //     .collection(collectionName)
//     //     .get()
//     //     .then((value) {
//     //   // print("############################");
//     //   // print(value.docs.length);
//     //   // print("############################");
//     //   value.docs.forEach((element) {
//     //     list.add(element.data());
//     //   });
//     // });
//     QuerySnapshot<Map<String, dynamic>> document = await FirebaseFirestore
//         .instance
//         .collection('global_user_profile')
//         .doc(uid)
//         .collection(collectionName)
//         .get();
//     document.docs.forEach((element) {
//       list.add(element.data());
//     });
//     return list;
//   }
// }
