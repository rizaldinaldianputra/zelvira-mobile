import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_style.dart';
import '../../models/shipping_model.dart';
import '../../models/address_model.dart';
import '../../riverpod/shipping_provider.dart';
import '../../riverpod/address_provider.dart';

class AddressFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? addressData;

  const AddressFormPage({super.key, this.addressData});

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _postalController;

  String? _selectedProvinceId;
  String? _selectedCityId;
  String? _selectedDistrictId;
  String? _selectedSubdistrictId;

  bool _isDefault = false;
  bool _isLoading = false;
  bool _isLoadingCities = false;
  bool _isLoadingDistricts = false;

  List<Province> _provinces = [];
  List<City> _cities = [];
  List<District> _districts = [];
  List<Subdistrict> _subdistricts = [];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.addressData?['label'] ?? '',
    );
    _nameController = TextEditingController(
      text: widget.addressData?['recipientName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.addressData?['phoneNumber'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.addressData?['addressLine'] ?? '',
    );
    _postalController = TextEditingController(
      text: widget.addressData?['postalCode'] ?? '',
    );
    _isDefault = widget.addressData?['isDefault'] ?? false;

    // If editing, we need to load existing data
    if (widget.addressData != null) {
      _selectedProvinceId = widget.addressData!['provinceId'];
      _selectedCityId = widget.addressData!['cityId'];
      _selectedDistrictId = widget.addressData!['districtId'];
      _selectedSubdistrictId = widget.addressData!['subdistrictId'];

      // We'll need to trigger data fetching for cities/districts/subdistricts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeEditingData();
      });
    }
  }

  Future<void> _initializeEditingData() async {
    if (_selectedProvinceId != null) {
      setState(() => _isLoadingCities = true);
      try {
        _cities = await ref
            .read(shippingServiceProvider)
            .getCities(_selectedProvinceId!);
        if (!mounted) return;
        if (_selectedCityId != null) {
          setState(() => _isLoadingDistricts = true);
          _districts = await ref
              .read(shippingServiceProvider)
              .getDistricts(_selectedCityId!);

          if (_selectedDistrictId != null) {
            _subdistricts = await ref
                .read(shippingServiceProvider)
                .getSubdistricts(_selectedDistrictId!);
          }
        }
      } catch (e) {
        debugPrint("Error initializing data: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingCities = false;
            _isLoadingDistricts = false;
          });
        }
      }
    }
  }

  Future<void> _onProvinceChanged(String? val) async {
    if (val == _selectedProvinceId) return;
    setState(() {
      _selectedProvinceId = val;
      _selectedCityId = null;
      _selectedDistrictId = null;
      _selectedSubdistrictId = null;
      _cities = [];
      _districts = [];
      _subdistricts = [];
      _isLoadingCities = true;
    });

    if (val != null) {
      try {
        final cities = await ref.read(shippingServiceProvider).getCities(val);
        if (!mounted) return;
        setState(() {
          _cities = cities;
          _isLoadingCities = false;
        });
      } catch (e) {
        if (mounted) setState(() => _isLoadingCities = false);
        _showError('Gagal memuat kota: $e');
      }
    }
  }

  Future<void> _onCityChanged(String? val) async {
    if (val == _selectedCityId) return;
    setState(() {
      _selectedCityId = val;
      _selectedDistrictId = null;
      _selectedSubdistrictId = null;
      _districts = [];
      _subdistricts = [];
      _isLoadingDistricts = true;
    });

    if (val != null) {
      try {
        final districts = await ref
            .read(shippingServiceProvider)
            .getDistricts(val);
        if (!mounted) return;
        setState(() {
          _districts = districts;
          _isLoadingDistricts = false;
        });

        final city = _cities.firstWhere((c) => c.cityId == val);
        if (city.postalCode.isNotEmpty) {
          _postalController.text = city.postalCode;
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingDistricts = false);
        _showError('Gagal memuat kecamatan: $e');
      }
    }
  }

  Future<void> _onDistrictChanged(String? val) async {
    if (val == _selectedDistrictId) return;
    setState(() {
      _selectedDistrictId = val;
      _selectedSubdistrictId = null;
      _subdistricts = [];
    });

    if (val != null) {
      try {
        final subs = await ref
            .read(shippingServiceProvider)
            .getSubdistricts(val);
        if (!mounted) return;
        setState(() {
          _subdistricts = subs;
        });
      } catch (e) {
        // Subdistricts might fail for some reason, we can still proceed
        debugPrint('Gagal memuat kelurahan: $e');
      }
    }
  }

  void _showError(String msg) {
    if (mounted) AppToast.error(context, msg);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvinceId == null ||
        _selectedCityId == null ||
        _selectedDistrictId == null) {
      _showError('Harap pilih wilayah (Provinsi/Kota/Kecamatan)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_provinces.isEmpty) {
        throw Exception('Data provinsi belum dimuat');
      }
      if (_cities.isEmpty) throw Exception('Data kota belum dimuat');
      if (_districts.isEmpty) throw Exception('Data kecamatan belum dimuat');

      final province = _provinces.firstWhere(
        (p) => p.provinceId == _selectedProvinceId,
      );
      final city = _cities.firstWhere((c) => c.cityId == _selectedCityId);
      final district = _districts.firstWhere(
        (d) => d.districtId == _selectedDistrictId,
      );

      String subdistrictName = '';
      if (_selectedSubdistrictId != null && _subdistricts.isNotEmpty) {
        subdistrictName = _subdistricts
            .firstWhere((s) => s.subdistrictId == _selectedSubdistrictId)
            .subdistrictName;
      }

      final request = AddressRequest(
        label: _labelController.text,
        recipientName: _nameController.text,
        phoneNumber: _phoneController.text,
        addressLine: _addressController.text,
        provinceId: _selectedProvinceId!,
        provinceName: province.province,
        cityId: _selectedCityId!,
        cityName: city.cityName,
        districtId: _selectedDistrictId!,
        districtName: district.districtName,
        subdistrictId: _selectedSubdistrictId ?? '',
        subdistrictName: subdistrictName,
        postalCode: _postalController.text,
        isDefault: _isDefault,
      );

      if (widget.addressData != null) {
        final id = widget.addressData!['id'] as int;
        await ref.read(addressServiceProvider).updateAddress(id, request);
      } else {
        await ref.read(addressServiceProvider).createAddress(request);
      }

      if (mounted) {
        AppToast.success(context, 'Alamat berhasil disimpan');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Gagal menyimpan alamat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: const Text('Apakah Anda yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final id = widget.addressData!['id'] as int;
        await ref.read(addressServiceProvider).deleteAddress(id);
        if (mounted) {
          AppToast.success(context, 'Alamat berhasil dihapus');
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('Gagal menghapus alamat: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.addressData == null ? 'Tambah Alamat' : 'Ubah Alamat',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.addressData != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'Label Alamat',
                'Contoh: Rumah, Kantor',
                _labelController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Nama Penerima',
                'Masukkan nama penerima',
                _nameController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Nomor Telepon',
                'Masukkan nomor telepon',
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Province Dropdown
              Text(
                'Provinsi',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              provincesAsync.when(
                data: (provinces) {
                  // Safely update provinces list for lookups
                  _provinces = provinces;

                  if (provinces.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Data provinsi tidak ditemukan',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.refresh(provincesProvider),
                            child: const Text(
                              'Ulangi',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildDropdown(
                    'Pilih Provinsi',
                    _selectedProvinceId,
                    provinces
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.provinceId,
                            child: Text(p.province),
                          ),
                        )
                        .toList(),
                    _onProvinceChanged,
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gagal memuat provinsi: $e',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () => ref.refresh(provincesProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // City Dropdown
              Text(
                'Kota / Kabupaten',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingCities
                  ? const Center(child: LinearProgressIndicator())
                  : _buildDropdown(
                      'Pilih Kota',
                      _selectedCityId,
                      _cities
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.cityId,
                              child: Text("${c.type} ${c.cityName}"),
                            ),
                          )
                          .toList(),
                      _selectedProvinceId == null ? null : _onCityChanged,
                    ),
              const SizedBox(height: 20),

              // District Dropdown
              Text(
                'Kecamatan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingDistricts
                  ? const Center(child: LinearProgressIndicator())
                  : _buildDropdown(
                      'Pilih Kecamatan',
                      _selectedDistrictId,
                      _districts
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.districtId,
                              child: Text(d.districtName),
                            ),
                          )
                          .toList(),
                      _selectedCityId == null ? null : _onDistrictChanged,
                    ),
              const SizedBox(height: 20),

              // Subdistrict Dropdown
              // Text('Kelurahan / Desa (Opsional)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              // const SizedBox(height: 8),
              // _isLoadingSubdistricts
              //   ? const Center(child: LinearProgressIndicator())
              //   : _buildDropdown(
              //       'Pilih Kelurahan',
              //       _selectedSubdistrictId,
              //       _subdistricts.map((s) => DropdownMenuItem(value: s.subdistrictId, child: Text(s.subdistrictName))).toList(),
              //       _selectedDistrictId == null || _subdistricts.isEmpty ? null : (val) => setState(() => _selectedSubdistrictId = val),
              //     ),
              // const SizedBox(height: 20),
              _buildTextField(
                'Alamat Lengkap',
                'Nama jalan, No. Rumah, Unit, dll',
                _addressController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Kode Pos',
                'Contoh: 12345',
                _postalController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simpan sebagai alamat utama',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Alamat ini akan digunakan untuk semua pengiriman',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isDefault,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isDefault = val),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Alamat',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<DropdownMenuItem<String>> items,
    Function(String?)? onChanged,
  ) {
    // Ensure selected value exists in items to prevent crash
    final bool valueExists = items.any((item) => item.value == value);
    final String? effectiveValue = valueExists ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: onChanged == null ? Colors.grey.shade50 : Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (val) =>
              val == null || val.isEmpty ? 'Field ini wajib diisi' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
