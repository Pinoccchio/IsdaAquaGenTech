class WeatherIcons {
  static const String _baseAssetPath = 'lib/assets/weather/';

  static String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '${_baseAssetPath}clear.png';
      case 'clouds':
        return '${_baseAssetPath}cloudy.png';
      case 'rain':
        return '${_baseAssetPath}rain.png';
      case 'drizzle':
        return '${_baseAssetPath}drizzle.png';
      case 'thunderstorm':
        return '${_baseAssetPath}thunderstorm.png';
      case 'snow':
        return '${_baseAssetPath}snow.jpg';
      default:
        return '${_baseAssetPath}clear.png';
    }
  }
}

