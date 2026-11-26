import 'dart:convert';
import 'dart:io';

/// Reads a saved API response from `test/fixtures/`.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;
