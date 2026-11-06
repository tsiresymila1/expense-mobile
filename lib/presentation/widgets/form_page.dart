import 'package:flutter/material.dart';

Future<T?> openFormPage<T>(
  BuildContext context,
  Widget child, {
  required String title,
}) => Navigator.of(context, rootNavigator: true).push<T>(
  MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: child),
    ),
  ),
);
