import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'bookings': 'Bookings',
      'vehicles': 'Vehicles',
      'parts': 'Parts',
      'me': 'Me',
      
      // Home Page
      'latestUpdates': 'Latest Updates',
      'quickActions': 'Quick Actions',
      'bookService': 'Book Service',
      'history': 'History',
      'myCars': 'My Cars',
      'spareParts': 'Spare Parts',
      'upcomingBooking': 'Upcoming Booking',
      'noUpcomingBooking': 'No Upcoming Booking',
      'bookToStart': 'Book a service to get started',
      'bookNow': 'Book Now',
      
      // Profile / Me
      'preferences': 'Preferences',
      'state': 'State',
      'language': 'Language',
      'appearance': 'Appearance',
      'more': 'More',
      'helpAndSupport': 'Help & Support',
      'contactUs': 'Contact Us',
      'about': 'About',
      'signOut': 'Sign Out',
      'cancel': 'Cancel',
      'selectLanguage': 'Select Language',
    },
    'zh': {
      // Navigation
      'home': '首页',
      'bookings': '预约',
      'vehicles': '车辆',
      'parts': '零件',
      'me': '我的',
      
      // Home Page
      'latestUpdates': '最新动态',
      'quickActions': '快捷操作',
      'bookService': '预约服务',
      'history': '历史记录',
      'myCars': '我的车辆',
      'spareParts': '零件商城',
      'upcomingBooking': '即将到来的预约',
      'noUpcomingBooking': '暂无预约',
      'bookToStart': '预约服务开始体验',
      'bookNow': '立即预约',
      
      // Profile / Me
      'preferences': '偏好设置',
      'state': '地区',
      'language': '语言',
      'appearance': '外观',
      'more': '更多',
      'helpAndSupport': '帮助与支持',
      'contactUs': '联系我们',
      'about': '关于',
      'signOut': '退出登录',
      'cancel': '取消',
      'selectLanguage': '选择语言',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }

  // Shorthand getters for navigation
  String get home => translate('home');
  String get bookings => translate('bookings');
  String get vehicles => translate('vehicles');
  String get parts => translate('parts');
  String get me => translate('me');
  String get cancel => translate('cancel');
  String get selectLanguage => translate('selectLanguage');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
