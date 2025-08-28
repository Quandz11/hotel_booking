import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../models/hotel.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/loading_widget.dart';

class HotelFormScreen extends StatefulWidget {
  final Hotel? hotel; // null for create, hotel object for edit
  
  const HotelFormScreen({super.key, this.hotel});

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _checkInTimeController = TextEditingController();
  final _checkOutTimeController = TextEditingController();
  
  int _starRating = 3;
  List<String> _selectedAmenities = [];
  String _cancellationPolicy = 'moderate';
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  List<Map<String, dynamic>> _existingImages = [];
  bool _isLoading = false;

  final List<String> _availableAmenities = [
    'wifi', 'parking', 'pool', 'gym', 'spa', 'restaurant', 'bar',
    'room_service', 'concierge', 'laundry', 'airport_shuttle',
    'business_center', 'conference_room', 'pet_friendly'
  ];

  final List<String> _cancellationPolicies = [
    'flexible', 'moderate', 'strict'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.hotel != null) {
      _populateForm();
    } else {
      // Set default values for new hotel
      _checkInTimeController.text = '14:00';
      _checkOutTimeController.text = '12:00';
    }
  }

  void _populateForm() {
    final hotel = widget.hotel!;
    _nameController.text = hotel.name;
    _descriptionController.text = hotel.description;
    _streetController.text = hotel.address.street;
    _cityController.text = hotel.address.city;
    _stateController.text = hotel.address.state;
    _countryController.text = hotel.address.country;
    _zipCodeController.text = hotel.address.zipCode;
    _phoneController.text = hotel.contact.phone;
    _emailController.text = hotel.contact.email;
    _websiteController.text = hotel.contact.website;
    _checkInTimeController.text = hotel.policies.checkIn;
    _checkOutTimeController.text = hotel.policies.checkOut;
    _starRating = 3; // Default since starRating is not in model
    _selectedAmenities = List<String>.from(hotel.amenities);
    
    // Ensure cancellation policy is valid
    final hotelPolicy = hotel.policies.cancellation;
    _cancellationPolicy = _cancellationPolicies.contains(hotelPolicy) ? hotelPolicy : 'moderate';
    
    _existingImageUrls = hotel.images.map((img) => img.url).toList();
    _existingImages = List<Map<String, dynamic>>.from(
      hotel.images.map((img) => img.toJson())
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _checkInTimeController.dispose();
    _checkOutTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.hotel != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editHotel : l10n.addHotel),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: Text(
                l10n.save,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildAddressSection(),
            const SizedBox(height: 24),
            _buildContactSection(),
            const SizedBox(height: 24),
            _buildDetailsSection(),
            const SizedBox(height: 24),
            _buildAmenitiesSection(),
            const SizedBox(height: 24),
            _buildImagesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.basicInformation,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.hotelName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterHotelName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterDescription;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _starRating,
              decoration: InputDecoration(
                labelText: l10n.starRating,
                border: const OutlineInputBorder(),
              ),
              items: [3, 4, 5].map((stars) {
                return DropdownMenuItem(
                  value: stars,
                  child: Row(
                    children: [
                      ...List.generate(stars, (index) => const Icon(Icons.star, color: Colors.amber, size: 20)),
                      Text(' ($stars ${l10n.stars})'),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _starRating = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.address,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: l10n.streetAddress,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterStreetAddress;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: l10n.city,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterCity;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: l10n.state,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterState;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: InputDecoration(
                      labelText: l10n.country,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterCountry;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: InputDecoration(
                      labelText: l10n.zipCode,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterZipCode;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.contactInformation,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterPhoneNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterEmail;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return l10n.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: '${l10n.website} (${l10n.optional})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.hotelDetails,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _checkInTimeController,
                    decoration: InputDecoration(
                      labelText: l10n.checkInTime,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context, _checkInTimeController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _checkOutTimeController,
                    decoration: InputDecoration(
                      labelText: l10n.checkOutTime,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context, _checkOutTimeController),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _cancellationPolicy,
              decoration: InputDecoration(
                labelText: l10n.cancellationPolicy,
                border: const OutlineInputBorder(),
              ),
              items: _cancellationPolicies.map((policy) {
                return DropdownMenuItem(
                  value: policy,
                  child: Text(_getCancellationPolicyName(policy)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _cancellationPolicy = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.amenities,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Text(_getAmenityName(amenity)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.images,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(l10n.addImages),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images
                    ..._existingImageUrls.map((url) => _buildExistingImageItem(url)),
                    // New images
                    ..._selectedImages.map((file) => _buildNewImageItem(file)),
                  ],
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noImagesSelected,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImageItem(String url) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _existingImageUrls.remove(url);
                  _existingImages.removeWhere((img) => img['url'] == url);
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageItem(File file) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages.remove(file);
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    setState(() {
      _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
    });
  }

  String _getAmenityName(String amenity) {
    // In a real app, this should use localization
    final amenityNames = {
      'wifi': 'WiFi',
      'parking': 'Parking',
      'pool': 'Swimming Pool',
      'gym': 'Fitness Center',
      'spa': 'Spa',
      'restaurant': 'Restaurant',
      'bar': 'Bar',
      'room_service': 'Room Service',
      'concierge': 'Concierge',
      'laundry': 'Laundry',
      'airport_shuttle': 'Airport Shuttle',
      'business_center': 'Business Center',
      'conference_room': 'Conference Room',
      'pet_friendly': 'Pet Friendly',
    };
    return amenityNames[amenity] ?? amenity;
  }

  String _getCancellationPolicyName(String policy) {
    final l10n = AppLocalizations.of(context)!;
    switch (policy) {
      case 'flexible':
        return l10n.flexible;
      case 'moderate':
        return l10n.moderate;
      case 'strict':
        return l10n.strict;
      default:
        return policy;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
      
      // Prepare hotel data
      final hotelData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'starRating': _starRating,
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'country': _countryController.text.trim(),
          'zipCode': _zipCodeController.text.trim(),
        },
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        'checkInTime': _checkInTimeController.text,
        'checkOutTime': _checkOutTimeController.text,
        'cancellationPolicy': _cancellationPolicy,
        'amenities': _selectedAmenities,
        'existingImages': _existingImages,
      };

      print('Submitting hotel data: $hotelData');
      print('Selected images: ${_selectedImages.length}');

      bool success;
      if (widget.hotel != null) {
        // Update existing hotel
        print('Updating hotel with ID: ${widget.hotel!.id}');
        success = await provider.updateHotel(widget.hotel!.id, hotelData, _selectedImages);
      } else {
        // Create new hotel
        print('Creating new hotel');
        success = await provider.createHotel(hotelData, _selectedImages);
      }

      print('Operation success: $success');

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.hotel != null ? 'Hotel updated successfully!' : 'Hotel created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error.isNotEmpty ? provider.error : 'Operation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error in _submitForm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
