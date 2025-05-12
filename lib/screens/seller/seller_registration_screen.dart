import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/models/country.dart';
import '/models/state.dart';
import 'package:haul/models/city.dart';
import 'package:provider/provider.dart';
import '/providers/user_profile_provider.dart';
import '/providers/seller_registration_provider.dart';
import 'seller_verification_screen.dart';
import 'seller_processing_screen.dart';

class SellerRegistrationPage extends StatefulWidget {
  const SellerRegistrationPage({super.key});
  @override
  _SellerRegistrationState createState() => _SellerRegistrationState();
}

class _SellerRegistrationState extends State<SellerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _address1Controller.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  // Updated navigation flow to ensure proper sequence
  void _handleSubmit(SellerRegistrationProvider provider) async {
    if (_formKey.currentState!.validate()) {
      final success = await provider.saveSellerData(
        businessName: _businessNameController.text,
        addressLine1: _address1Controller.text,
        zipCode: _zipCodeController.text,
      );

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<SellerRegistrationProvider>.value(
              value: provider,
              child: SellerProcessingScreen(
                businessName: _businessNameController.text,
              ),
            ),
          ),
        );
      } else if (mounted && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    return ChangeNotifierProvider(
      create: (_) => SellerRegistrationProvider(),
      child: Consumer<SellerRegistrationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/vendor.png",
                            height: 150,
                            width: 150,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Start Selling",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Be part of the seller community",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Business Information",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (provider.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (provider.errorMessage != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              provider.errorMessage!,
                                              style: TextStyle(color: Colors.red.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  _buildFormField(
                                    label: "Business Name",
                                    controller: _businessNameController,
                                    validator: (value) => value?.isEmpty ?? true ? 'Please enter your business name' : null,
                                    prefixIcon: Icons.business,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildFormField(
                                    label: "Business Address",
                                    controller: _address1Controller,
                                    validator: (value) => value?.isEmpty ?? true ? 'Please enter your address' : null,
                                    prefixIcon: Icons.location_on,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "Location",
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRegionDropdown(provider),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildProvinceDropdown(provider),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCityField(provider),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildFormField(
                                          label: "Zip Code",
                                          controller: _zipCodeController,
                                          validator: (value) => value?.isEmpty ?? true ? 'Please enter your zip code' : null,
                                          keyboardType: TextInputType.number,
                                          prefixIcon: Icons.pin,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () => _handleSubmit(provider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        "CONTINUE",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // UI Helper methods that use the provider
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown(SellerRegistrationProvider provider) {
    // Set Philippines as default country when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.selectedCountry == null) {
        provider.setCountry("Philippines", "PH");
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Country",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          enabled: false,
          initialValue: "Philippines",
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.public),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Container(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                'assets/images/philippines_flag.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegionDropdown(SellerRegistrationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Region", style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Show modal bottom sheet with scrollable list
            final selectedRegion = await showModalBottomSheet<Map<String, dynamic>>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return FractionallySizedBox(
                  heightFactor: 0.7,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Select Region',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Divider(),
                      Expanded(
                        child: FutureBuilder<List<dynamic>>(
                          future: provider.regions,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            
                            return ListView.builder(
                              itemCount: snapshot.data?.length ?? 0,
                              itemBuilder: (context, index) {
                                final region = snapshot.data![index];
                                return ListTile(
                                  title: Text(region['name']),
                                  onTap: () {
                                    Navigator.pop(context, region);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
            
            if (selectedRegion != null) {
              provider.setPhilippinesRegion(
                selectedRegion['name'],
                selectedRegion['code'],
              );
            }
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade100,
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.selectedRegion ?? 'Select Region',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: provider.selectedRegion != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProvinceDropdown(SellerRegistrationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Province",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<dynamic>>(
          future: provider.provinces,
          builder: (context, snapshot) {
            if (provider.selectedRegion == null) {
              return _buildDisabledField("Select Region First");
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            return DropdownButtonFormField<String>(
              value: provider.selectedProvince,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              hint: const Text("Select Province"),
              items: snapshot.data?.map((province) => DropdownMenuItem<String>(
                    value: province['name'],
                    child: Text(province['name'], overflow: TextOverflow.ellipsis),
                  )).toList() ?? [],
              onChanged: snapshot.hasData && snapshot.data!.isNotEmpty
                  ? (String? newValue) {
                      if (newValue != null) {
                        final provinceCode = snapshot.data!.firstWhere((p) => p['name'] == newValue)['code'];
                        provider.setPhilippinesProvince(newValue, provinceCode);
                      }
                    }
                  : null,
              validator: (value) => value == null ? 'Please select a province' : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCityField(SellerRegistrationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "City",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<City>>(
          future: provider.cities,
          builder: (context, snapshot) {
            if (provider.selectedRegion == null) {
              return _buildDisabledField("Select Region First");
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_city),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: "Enter City Name",
                ),
                onChanged: (value) {
                  provider.setCity(value);
                },
                validator: (value) => value?.isEmpty ?? true ? 'Please enter your city' : null,
              );
            }

            return DropdownButtonFormField<String>(
              value: provider.selectedCity,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_city),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: snapshot.data!.map((city) => DropdownMenuItem<String>(
                    value: city.name,
                    child: Text(city.name, overflow: TextOverflow.ellipsis),
                  )).toList(),
              onChanged: (String? newValue) {
                provider.setCity(newValue);
                _cityController.text = newValue ?? '';
              },
              validator: (value) => value == null ? 'Please select a city' : null,
              hint: const Text("Select City"),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDisabledField(String hintText) {
    return TextFormField(
      enabled: false,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.not_interested, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}