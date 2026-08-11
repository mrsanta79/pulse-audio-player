/// Route paths and the builders for the ones that take arguments.
///
/// Query strings were previously assembled at each call site, so a change to
/// how (say) an album is addressed meant finding every `Uri.encodeComponent`
/// in the app. These are the only places that know the shape of a URL.
class Routes {
  const Routes._();

  static const home = '/home';
  static const search = '/search';
  static const library = '/library';
  static const hotlist = '/hotlist';

  static const settings = '/settings';
  static const likes = '/likes';

  static const artists = '/library/artists';
  static const albums = '/library/albums';
  static const years = '/library/years';
  static const songs = '/library/songs';

  /// The tabs the bottom nav switches between, in nav order.
  static const shellRoutes = [home, search, library, hotlist];
}

String albumRoute(String album, String artist) =>
    '/album?album=${Uri.encodeComponent(album)}'
    '&artist=${Uri.encodeComponent(artist)}';

String artistRoute(String artist) =>
    '/artist?name=${Uri.encodeComponent(artist)}';

String yearRoute(int year) => '/year?value=$year';

String playlistRoute(int playlistId) => '/playlist?id=$playlistId';
