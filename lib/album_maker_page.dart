import 'package:flutter/material.dart';

class AlbumMakerPage extends StatefulWidget {
  const AlbumMakerPage({super.key});

  @override
  State<AlbumMakerPage> createState() => _AlbumMakerPage();
}

class _AlbumMakerPage extends State<AlbumMakerPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album Maker'),
        centerTitle: true,
        actions: [],
      ),
    );
  }
}
