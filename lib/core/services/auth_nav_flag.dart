import 'package:shared_preferences/shared_preferences.dart';

class AuthNavFlag {
  static const String _keySignedOutRecently = 'signed_out_recently';

  static Future<void> setSignedOutRecently(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySignedOutRecently, value);
  }

  static Future<bool> wasSignedOutRecently() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySignedOutRecently) ?? false;
  }
}