import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathira/services/location_service.dart';

void main() {
  test('LocationService fallback returns valid Indian metro coordinates and names', () {
    final fallback = UserLocation.fallback();
    expect(fallback.city, 'Mumbai');
    expect(fallback.state, 'Maharashtra');
    expect(fallback.country, 'India');
    expect(fallback.latitude, 19.0760);
    expect(fallback.longitude, 72.8777);
    expect(fallback.displayName, 'Mumbai, Maharashtra');
  });

  test('CurrentLocationNotifier sets manual and auto location correctly', () async {
    final container = ProviderContainer();
    final notifier = container.read(currentLocationProvider.notifier);

    notifier.setManualLocation('Bengaluru', stateName: 'Karnataka', lat: 12.9716, lng: 77.5946);
    final loc = container.read(currentLocationProvider).value;
    expect(loc?.city, 'Bengaluru');
    expect(loc?.state, 'Karnataka');
    expect(loc?.displayName, 'Bengaluru, Karnataka');
  });
}
