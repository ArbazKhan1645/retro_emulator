/// API endpoint and key constants
class ApiConstants {
  ApiConstants._();

  // IGDB (Twitch Developer API)
  static const String igdbClientId = 'YOUR_IGDB_CLIENT_ID';
  static const String igdbClientSecret = 'YOUR_IGDB_CLIENT_SECRET';
  static const String igdbAuthUrl = 'https://id.twitch.tv/oauth2/token';
  static const String igdbBaseUrl = 'https://api.igdb.com/v4';

  // ScreenScraper
  static const String screenscrapeBaseUrl = 'https://www.screenscraper.fr/api2';
  static const String screenscrapeDevId = 'YOUR_SCREENSCRAPER_DEV_ID';
  static const String screenscrapeDevPassword =
      'YOUR_SCREENSCRAPER_DEV_PASSWORD';
  static const String screenscrapeSystemId = '1'; // Mega Drive = 1

  // RetroAchievements
  static const String raBaseUrl = 'https://retroachievements.org/API';

  // IGDB endpoints
  static const String igdbGames = '/games';
  static const String igdbCovers = '/covers';
  static const String igdbScreenshots = '/screenshots';
  static const String igdbCompanies = '/companies';
  static const String igdbGenres = '/genres';

  // Image CDN
  static const String igdbImageBase =
      'https://images.igdb.com/igdb/image/upload';
  static const String igdbCoverLarge = 't_cover_big';
  static const String igdbScreenshotBig = 't_screenshot_big';
  static const String igdbBackgroundBig = 't_1080p';

  // Timeout
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 15000;
}
