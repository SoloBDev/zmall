// To parse this JSON data, do
//
//     final cart = cartFromJson(jsonString);

import 'dart:convert';

Cart cartFromJson(String str) => Cart.fromJson(json.decode(str));

String cartToJson(Cart data) => json.encode(data.toJson());

class Cart {
  Cart({
    this.userId,
    this.items,
    this.serverToken,
    this.destinationAddress,
    this.storeId,
    this.storeLocation,
    this.isSchedule = false,
    this.scheduleStart,
    this.isForOthers = false,
    this.userName = "",
    this.phone = "",
    this.isLaundryService = false,
  });

  String? userId;
  List<Item>? items;
  String? serverToken;
  DestinationAddress? destinationAddress;
  String? storeId;
  StoreLocation? storeLocation;
  bool isSchedule;
  DateTime? scheduleStart;
  bool isForOthers;
  String userName;
  String phone;
  bool isLaundryService;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        userId: json["user_id"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
        serverToken: json["server_token"],
        destinationAddress:
            DestinationAddress.fromJson(json["destination_address"]),
        storeId: json["store_id"],
        storeLocation: StoreLocation.fromJson(json["store_location"]),
        isSchedule: json["is_schedule"],
        scheduleStart: json["schedule_start"] == null
            ? null
            : DateTime.parse(json["schedule_start"]),
        isForOthers: json["delivery_for_other"],
        userName: json["username"],
        phone: json["phone"],
        isLaundryService: json["is_laundry_service"],
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "items": List<dynamic>.from(items!.map((x) => x.toJson())),
        "server_token": serverToken,
        "destination_address": destinationAddress!.toJson(),
        "store_id": storeId,
        "store_location": storeLocation,
        "is_schedule": isSchedule,
        "schedule_start":
            scheduleStart == null ? null : scheduleStart.toString(),
        "delivery_for_other": isForOthers,
        "username": userName,
        "phone": phone,
        "is_laundry_service" : isLaundryService,
      };
}

class AbroadCart {
  AbroadCart({
    this.userId = "",
    this.items,
    this.serverToken = "",
    this.destinationAddress,
    this.storeId,
    this.storeLocation,
    this.isSchedule = false,
    this.scheduleStart,
    this.isForOthers = true,
    this.isOpen = true,
    this.userName = "",
    this.phone = "",
    this.abroadData,
    this.isAbroad = true,
  });

  String userId;
  List<Item>? items;
  String serverToken;
  DestinationAddress? destinationAddress;
  String? storeId;
  StoreLocation? storeLocation;
  bool isSchedule;
  DateTime? scheduleStart;
  bool isForOthers;
  bool isOpen;
  String userName;
  String phone;
  AbroadData? abroadData;
  bool isAbroad;

  factory AbroadCart.fromJson(Map<String, dynamic> json) => AbroadCart(
        userId: json["user_id"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
        serverToken: json["server_token"],
        destinationAddress:
            DestinationAddress.fromJson(json["destination_address"]),
        storeId: json["store_id"],
        storeLocation: StoreLocation.fromJson(json["store_location"]),
        isSchedule: json["is_schedule"],
        scheduleStart: json["schedule_start"] == null
            ? null
            : DateTime.parse(json["schedule_start"]),
        isForOthers: json["delivery_for_other"],
        isOpen: json['is_open'],
        isAbroad: json["is_abroad"],
        userName: json["username"],
        phone: json['phone'],
        abroadData: json["abroad_data"] == null
            ? null
            : AbroadData.fromJson(json["abroad_data"]),
      );

  Map<String, dynamic> toJson() => {
        "items": List<dynamic>.from(items!.map((x) => x.toJson())),
        "server_token": serverToken,
        "destination_address": destinationAddress!.toJson(),
        "store_id": storeId,
        "store_location": storeLocation,
        "is_schedule": isSchedule,
        "schedule_start":
            scheduleStart == null ? null : scheduleStart.toString(),
        "delivery_for_other": isForOthers,
        "is_open": isOpen,
        "is_abroad": isAbroad,
        "username": userName,
        "phone": phone,
        "abroad_data": abroadData == null ? null : abroadData!.toJson(),
        "user_id": userId == null ? null : userId,
      };
}

class AbroadData {
  AbroadData({
    this.abroadName,
    this.abroadEmail,
    this.abroadPhone,
  });
  String? abroadName, abroadEmail, abroadPhone;
  factory AbroadData.fromJson(Map<String, dynamic> json) => AbroadData(
        abroadName: json["abroad_name"],
        abroadEmail: json["abroad_email"],
        abroadPhone: json["abroad_phone"],
      );
  Map<String, dynamic> toJson() => {
        "abroad_name": abroadName,
        "abroad_email": abroadEmail,
        "abroad_phone": abroadPhone,
      };
}

class StoreLocation {
  StoreLocation({
    this.lat,
    this.long,
  });
  double? lat, long;
  factory StoreLocation.fromJson(Map<String, dynamic> json) => StoreLocation(
        lat: json["lat"].toDouble(),
        long: json["long"].toDouble(),
      );
  Map<String, dynamic> toJson() => {
        "lat": lat,
        "long": long,
      };
}

class DestinationAddress {
  DestinationAddress({
    this.name,
    this.long =38.761886,
    this.lat = 9.010498,
    this.note,
  });

  String? name;
  double? long;
  double? lat;
  String? note;

  factory DestinationAddress.fromJson(Map<String, dynamic> json) =>
      DestinationAddress(
        name: json["name"],
        long: json["long"] != null ? json['long'].toDouble() : 38.761886,
        lat: json['lat']!= null ? json["lat"].toDouble(): 9.010498,
        note: json["note"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "long": long,
        "lat": lat,
        "note": note,
      };
}

class Item {
  Item({
    this.id,
    this.quantity,
    this.specification,
    this.noteForItem = "",
    this.price,
    this.itemName,
    this.imageURL,
  });

  String? id;
  int? quantity;
  List<Specification>? specification;
  String noteForItem;
  double? price;
  String? itemName;
  String? imageURL;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json["_id"],
        quantity: json["quantity"],
        specification: List<Specification>.from(
            json["specification"].map((x) => Specification.fromJson(x))),
        noteForItem: json["note_for_item"],
        price: json["price"],
        itemName: json["item_name"],
        imageURL: json["image_url"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "quantity": quantity,
        "specification":
            List<dynamic>.from(specification!.map((x) => x.toJson())),
        "note_for_item": noteForItem,
        "price": price,
        "item_name": itemName,
        "image_url": imageURL,
      };
}

class Specification {
  Specification({
    this.uniqueId,
    this.list,
  });

  int? uniqueId;
  List<ListElement>? list;

  factory Specification.fromJson(Map<String, dynamic> json) => Specification(
        uniqueId: json["unique_id"],
        list: List<ListElement>.from(
            json["list"].map((x) => ListElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "unique_id": uniqueId,
        "list": List<dynamic>.from(list!.map((x) => x.toJson())),
      };
}

class ListElement {
  ListElement({this.uniqueId, this.price});

  int? uniqueId;
  double? price;

  factory ListElement.fromJson(Map<String, dynamic> json) => ListElement(
        uniqueId: json["unique_id"],
        price: json["price"],
      );

  Map<String, dynamic> toJson() => {
        "unique_id": uniqueId,
        "price": price,
      };
}

class DeliveryLocation {
  DeliveryLocation({this.list, this.note = "Delivery note..."});
  List<DestinationAddress>? list;
  String note;

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) =>
      DeliveryLocation(
        list: List<DestinationAddress>.from(
            json["list"].map((x) => DestinationAddress.fromJson(x))),
      );
  Map<String, dynamic> toJson() => {
        "list": List<dynamic>.from(list!.map((e) => e.toJson())),
      };
}

class Contact {
  Contact({this.name, this.phone});

  String? name;
  String? phone;

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        name: json["name"],
        phone: json["phone"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "phone": phone,
      };
}

class HomeContact {
  HomeContact({this.list});
  List<Contact>? list;

  factory HomeContact.fromJson(Map<String, dynamic> json) => HomeContact(
        list: List<Contact>.from(json["list"].map((x) => Contact.fromJson(x))),
      );
  Map<String, dynamic> toJson() => {
        "list": List<dynamic>.from(list!.map((e) => e.toJson())),
      };
}
