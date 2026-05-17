class MapboxConfig {
  static const String streetsStyleId = 'mapbox/streets-v12';

  static String tileUrlTemplate(String accessToken) =>
      'https://api.mapbox.com/styles/v1/$streetsStyleId/tiles/256/{z}/{x}/{y}{r}?access_token=$accessToken';
}
