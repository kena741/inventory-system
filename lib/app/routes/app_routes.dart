// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const AUTH = _Paths.AUTH;
  static const HOME = _Paths.HOME;
}

abstract class _Paths {
  _Paths._();
  static const AUTH = '/login';
  static const HOME = '/home';
}

