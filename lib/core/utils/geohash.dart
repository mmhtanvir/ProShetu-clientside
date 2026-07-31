/// Standard geohash encoding (public algorithm, e.g. Niemeyer 2008).
/// Used to turn a device's lat/lng into the coarse shard topic
/// `/v1/coord/{geohash}` expects. The backend itself truncates to
/// its configured precision server-side (`COORD_GEOHASH_LEN`, ~5
/// chars ≈ 5km) so a client can't smuggle a precise location into
/// the topic — this just needs to produce a valid geohash prefix.
abstract final class Geohash {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double lat, double lng, {int precision = 5}) {
    double latMin = -90, latMax = 90;
    double lngMin = -180, lngMax = 180;
    final StringBuffer geohash = StringBuffer();
    int bit = 0;
    int ch = 0;
    bool evenBit = true;

    while (geohash.length < precision) {
      if (evenBit) {
        final double mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          ch |= (1 << (4 - bit));
          lngMin = mid;
        } else {
          lngMax = mid;
        }
      } else {
        final double mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      evenBit = !evenBit;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return geohash.toString();
  }
}
