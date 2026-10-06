import 'package:get/get.dart';

class PincodeInfo {
  final String city;
  final String state;
  final List<String> areas;
  const PincodeInfo(this.city, this.state, this.areas);
}

// Approximate coordinates for common cities so distance-based matching works
// without GPS. Used by the demo backend and when a pincode lookup succeeds.
const Map<String, List<double>> cityCoords = {
  'delhi': [28.6139, 77.2090],
  'new delhi': [28.6139, 77.2090],
  'gurugram': [28.4595, 77.0266],
  'gurgaon': [28.4595, 77.0266],
  'noida': [28.5355, 77.3910],
  'gautam buddha nagar': [28.5355, 77.3910],
  'ghaziabad': [28.6692, 77.4538],
  'faridabad': [28.4089, 77.3178],
  'mumbai': [19.0760, 72.8777],
  'thane': [19.2183, 72.9781],
  'pune': [18.5204, 73.8567],
  'bangalore': [12.9716, 77.5946],
  'bengaluru': [12.9716, 77.5946],
  'hyderabad': [17.3850, 78.4867],
  'chennai': [13.0827, 80.2707],
  'kolkata': [22.5726, 88.3639],
  'ahmedabad': [23.0225, 72.5714],
  'jaipur': [26.9124, 75.7873],
  'lucknow': [26.8467, 80.9462],
  'patna': [25.5941, 85.1376],
  'indore': [22.7196, 75.8577],
  'bhopal': [23.2599, 77.4126],
};

List<double>? coordsForCity(String? city) => city == null ? null : cityCoords[city.trim().toLowerCase()];

/// Look up an Indian pincode → city/state/areas via the free India Post API.
/// No key needed. Returns null on failure (caller keeps manual entry).
Future<PincodeInfo?> lookupPincode(String pin) async {
  if (!RegExp(r'^\d{6}$').hasMatch(pin)) return null;
  try {
    final res = await GetConnect(timeout: const Duration(seconds: 8))
        .get('https://api.postalpincode.in/pincode/$pin');
    final rec = (res.body is List && (res.body as List).isNotEmpty) ? res.body[0] : null;
    if (rec == null || rec['Status'] != 'Success') return null;
    final po = (rec['PostOffice'] as List?) ?? const [];
    if (po.isEmpty) return null;
    return PincodeInfo(
      (po[0]['District'] ?? '').toString(),
      (po[0]['State'] ?? '').toString(),
      po.map((p) => p['Name'].toString()).toSet().toList(),
    );
  } catch (_) {
    return null;
  }
}
