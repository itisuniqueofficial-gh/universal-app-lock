/// Static application identity, branding, and attribution constants for
/// Universal App Lock.
///
/// These values are the single source of truth for user-visible identity and
/// legal attribution. Do not describe the application as an official Samsung
/// product anywhere in the app.
library;

class AppInfo {
  AppInfo._();

  static const String appName = 'Universal App Lock';
  static const String packageId = 'com.itisuniqueofficial.ual';

  static const String developer = 'Jaydatt Khodave';
  static const String company = 'IT IS UNIQUE OFFICIAL';

  static const String appWebsite = 'https://ual.itisuniqueofficial.com/';
  static const String developerWebsite = 'https://jaydatt.pages.dev/';
  static const String companyWebsite = 'https://www.itisuniqueofficial.com/';

  /// Short one-line tagline (mirrors the original S Secure feature intent,
  /// reworded and rebranded).
  static const String tagline = 'Keep your apps private by locking them.';

  /// Full, legally relevant attribution. Displayed on the About/Credits screen.
  static const String attribution =
      'Universal App Lock is an independent rebuild and modification '
      'inspired by the discontinued Samsung S Secure application.\n\n'
      'It is not affiliated with, sponsored by, or endorsed by '
      'Samsung Electronics.\n\n'
      'Samsung and S Secure are trademarks of their respective owners.';
}
