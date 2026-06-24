import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminGpsSettingsScreen extends StatefulWidget {
  const AdminGpsSettingsScreen({super.key});

  @override
  State<AdminGpsSettingsScreen> createState() => _AdminGpsSettingsScreenState();
}

class _AdminGpsSettingsScreenState extends State<AdminGpsSettingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final locs = await SupabaseService.getAttendanceLocations();
      setState(() {
        _locations = locs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat lokasi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Lokasi GPS', style: TextStyle(fontFamily: 'Poppins'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationDialog(),
        child: const Icon(Icons.add_location_alt_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(child: Text('Belum ada pengaturan lokasi. Absensi dapat dilakukan dari mana saja.', style: TextStyle(fontFamily: 'Poppins')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: loc['is_active'] ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          child: Icon(Icons.location_on_rounded, color: loc['is_active'] ? AppColors.success : Colors.grey),
                        ),
                        title: Text(loc['name'], style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        subtitle: Text('Lat: ${loc['latitude']}\nLng: ${loc['longitude']}\nRadius: ${loc['radius_meters']}m', style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
                          onPressed: () => _showLocationDialog(location: loc),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showLocationDialog({Map<String, dynamic>? location}) {
    final isEdit = location != null;
    final nameCtrl = TextEditingController(text: isEdit ? location['name'] : '');
    final latCtrl = TextEditingController(text: isEdit ? location['latitude'].toString() : '');
    final lngCtrl = TextEditingController(text: isEdit ? location['longitude'].toString() : '');
    final radiusCtrl = TextEditingController(text: isEdit ? location['radius_meters'].toString() : '50');
    final searchCtrl = TextEditingController();
    final mapController = MapController();
    bool isActive = isEdit ? (location['is_active'] ?? true) : true;
    bool isSearching = false;
    bool isSaving = false;

    Future<void> searchLocation(StateSetter setStateModal) async {
      if (searchCtrl.text.isEmpty) return;
      setStateModal(() => isSearching = true);
      try {
        final query = Uri.encodeComponent(searchCtrl.text);
        final response = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1'),
          headers: {'User-Agent': 'EduPresenceApp/1.0'},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List && data.isNotEmpty) {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            
            setStateModal(() {
              latCtrl.text = lat.toString();
              lngCtrl.text = lon.toString();
              mapController.move(LatLng(lat, lon), 16.0);
            });
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi tidak ditemukan')));
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data lokasi. Error: ${response.statusCode}')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error pencarian: $e')));
      } finally {
        setStateModal(() => isSearching = false);
      }
    }

    Future<void> getCurrentLocation(StateSetter setStateModal) async {
      setStateModal(() => isSearching = true);
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layanan GPS tidak aktif. Aktifkan GPS Anda.')));
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin akses lokasi ditolak.')));
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin akses lokasi ditolak permanen. Ubah di pengaturan HP Anda.')));
          return;
        }

        Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        setStateModal(() {
          latCtrl.text = position.latitude.toString();
          lngCtrl.text = position.longitude.toString();
          mapController.move(LatLng(position.latitude, position.longitude), 16.0);
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi saat ini: $e')));
      } finally {
        setStateModal(() => isSearching = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(isEdit ? 'Edit Lokasi GPS' : 'Tambah Lokasi GPS', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lokasi (cth: Gerbang Sekolah)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(labelText: 'Cari Alamat / Nama Tempat', prefixIcon: Icon(Icons.search)),
                        onSubmitted: (_) => searchLocation(setStateModal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    isSearching 
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(
                            icon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                            onPressed: () => searchLocation(setStateModal),
                          ),
                    IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: Colors.green),
                      tooltip: 'Gunakan Lokasi Saat Ini',
                      onPressed: () => getCurrentLocation(setStateModal),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Atau Pilih Titik Lokasi Manual pada Peta:', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  height: 250,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: LatLng(double.tryParse(latCtrl.text) ?? -6.200000, double.tryParse(lngCtrl.text) ?? 106.816666),
                        initialZoom: 16.0,
                        onTap: (tapPosition, point) {
                          setStateModal(() {
                            latCtrl.text = point.latitude.toString();
                            lngCtrl.text = point.longitude.toString();
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                          userAgentPackageName: 'com.example.absensi',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(double.tryParse(latCtrl.text) ?? 0, double.tryParse(lngCtrl.text) ?? 0),
                              color: AppColors.primaryBlue.withValues(alpha: 0.2),
                              borderColor: AppColors.primaryBlue,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: true,
                              radius: double.tryParse(radiusCtrl.text) ?? 50,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(double.tryParse(latCtrl.text) ?? 0, double.tryParse(lngCtrl.text) ?? 0),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: radiusCtrl, 
                  keyboardType: TextInputType.number, 
                  decoration: const InputDecoration(labelText: 'Radius (Meter)'),
                  onChanged: (val) {
                    // Triggers rebuild of modal to update circle size on map
                    setStateModal(() {});
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Aktifkan Lokasi Ini'),
                  value: isActive,
                  onChanged: (val) => setStateModal(() => isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (nameCtrl.text.isEmpty || latCtrl.text.isEmpty || lngCtrl.text.isEmpty || radiusCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data')));
                        return;
                      }

                      setStateModal(() => isSaving = true);
                      try {
                        final lat = double.parse(latCtrl.text);
                        final lng = double.parse(lngCtrl.text);
                        final rad = int.parse(radiusCtrl.text);

                        if (isEdit) {
                          await SupabaseService.client.from('attendance_locations').update({
                            'name': nameCtrl.text,
                            'latitude': lat,
                            'longitude': lng,
                            'radius_meters': rad,
                            'is_active': isActive,
                          }).eq('id', location['id']);
                        } else {
                          await SupabaseService.addAttendanceLocation(
                            name: nameCtrl.text,
                            latitude: lat,
                            longitude: lng,
                            radiusMeters: rad,
                          );
                        }

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        _fetchLocations();
                      } catch (e) {
                        setStateModal(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
                      }
                    },
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Lokasi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
    );
  }
}
