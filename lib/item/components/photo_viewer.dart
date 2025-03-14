import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({required this.imageUrl, required this.itemName});

  final String imageUrl;
  final String itemName;

  @override
  _PhotoViewerState createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late ImageProvider imageProvider;
  double minScale = 0.9;
  double maxScale = 1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imageProvider = CachedNetworkImageProvider(
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/${widget.imageUrl}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemName,
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: Container(
        child: PhotoView(
          imageProvider: imageProvider,
        ),
      ),
    );
  }
}
