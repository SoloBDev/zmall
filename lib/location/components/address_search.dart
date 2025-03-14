// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:zmall/constants.dart';
//
// import 'package:zmall/location/components/place_service.dart';
// import 'package:zmall/size_config.dart';
//
// class AddressSearch extends SearchDelegate<Suggestion> {
//    AddressSearch(this.sessionToken) {
//     apiClient = PlaceApiProvider(sessionToken);
//   }
//
//   final sessionToken;
//   late PlaceApiProvider apiClient;
//
//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       IconButton(
//         tooltip: 'Clear',
//         icon: Icon(Icons.clear),
//         onPressed: () {
//           query = '';
//         },
//       )
//     ];
//   }
//
//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       tooltip: 'Back',
//       icon: Icon(Icons.arrow_back),
//       onPressed: () {
//         close(context, null);
//       },
//     );
//   }
//
//   @override
//   Widget buildResults(BuildContext context) {
//     return null;
//   }
//
//   @override
//   Widget buildSuggestions(BuildContext context) {
//     return FutureBuilder(
//       future: query == ""
//           ? null
//           : apiClient.fetchSuggestions(
//               query, Localizations.localeOf(context).languageCode),
//       builder: (context, snapshot) => query == ''
//           ? Container(
//               padding:
//                   EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
//               child: Center(child: Text('Enter your address')),
//             )
//           : snapshot.hasData
//               ? ListView.builder(
//                   itemBuilder: (context, index) => Column(
//                     children: [
//                       ListTile(
//                         title: Text(
//                             (snapshot.data[index] as Suggestion).description),
//                         onTap: () {
//                           close(context, snapshot.data[index] as Suggestion);
//                         },
//                       ),
//                       Container(
//                         width: double.infinity,
//                         height: .2,
//                         color: kBlackColor,
//                       )
//                     ],
//                   ),
//                   itemCount: snapshot.data.length,
//                 )
//               : Container(
//                   child: Center(
//                     child: SpinKitCircle(
//                       color: kSecondaryColor,
//                     ),
//                   ),
//                 ),
//     );
//   }
// }
