import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../models/room.dart';
import '../../models/hotel.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/loading_widget.dart';

class RoomFormScreen extends StatefulWidget {
  final Room? room; // null for create, room object for edit
  final String? hotelId; // required for create
  
  const RoomFormScreen({super.key, this.room, this.hotelId});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _weekendPriceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final _discountController = TextEditingController();
  final _specialOfferController = TextEditingController();
  
  String _roomType = 'standard';
  String _bedType = 'single';
  int _bedCount = 1;
  int _maxGuests = 1;
  List<String> _selectedAmenities = [];
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  List<Map<String, dynamic>> _existingImages = [];
  bool _isLoading = false;
  String? _selectedHotelId;

  final List<String> _roomTypes = [
    'standard', 'deluxe', 'suite', 'executive', 'presidential'
  ];

  final List<String> _bedTypes = [
    'single', 'double', 'queen', 'king', 'twin'
  ];

  final List<String> _availableAmenities = [
    'wifi', 'air_conditioning', 'tv', 'minibar', 'safe', 
    'balcony', 'city_view', 'ocean_view', 'mountain_view',
    'kitchenette', 'bathtub', 'shower', 'hairdryer',
    'coffee_maker', 'telephone', 'desk', 'sofa'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _populateForm();
    } else {
      _selectedHotelId = widget.hotelId;
    }
  }

  void _populateForm() {
    final room = widget.room!;
    _nameController.text = room.name;
    _descriptionController.text = room.description;
    _basePriceController.text = room.basePrice.toString();
    _weekendPriceController.text = room.weekendPrice.toString();
    _sizeController.text = room.size?.toString() ?? '';
    _totalRoomsController.text = room.totalRooms.toString();
    _discountController.text = room.discountPercentage.toString();
    _specialOfferController.text = room.specialOfferDescription ?? '';
    
    _roomType = room.type;
    _bedType = room.bedType;
    _bedCount = room.bedCount;
    _maxGuests = room.maxGuests;
    _selectedAmenities = List<String>.from(room.amenities);
    _selectedHotelId = room.hotelId;
    
    _existingImageUrls = room.images.map((img) => img.url).toList();
    _existingImages = List<Map<String, dynamic>>.from(
      room.images.map((img) => img.toJson())
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _weekendPriceController.dispose();
    _sizeController.dispose();
    _totalRoomsController.dispose();
    _discountController.dispose();
    _specialOfferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.room != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editRoom : l10n.addRoom),
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
                style: const TextStyle(color: Colors.white),
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
            _buildPricingSection(),
            const SizedBox(height: 24),
            _buildRoomDetailsSection(),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.roomName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterRoomName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.roomDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterRoomDescription;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _roomType,
              decoration: InputDecoration(
                labelText: l10n.roomType,
                border: const OutlineInputBorder(),
              ),
              items: _roomTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getRoomTypeName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _roomType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _basePriceController,
                    decoration: InputDecoration(
                      labelText: l10n.basePrice,
                      border: const OutlineInputBorder(),
                      suffixText: 'VND',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterBasePrice;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.invalidFormat;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weekendPriceController,
                    decoration: InputDecoration(
                      labelText: l10n.weekendPrice,
                      border: const OutlineInputBorder(),
                      suffixText: 'VND',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterWeekendPrice;
                      }
                      if (double.tryParse(value) == null) {
                        return l10n.invalidFormat;
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
                    controller: _discountController,
                    decoration: InputDecoration(
                      labelText: l10n.discountPercentage,
                      border: const OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final discount = double.tryParse(value);
                        if (discount == null || discount < 0 || discount > 100) {
                          return 'Invalid discount percentage';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _specialOfferController,
                    decoration: InputDecoration(
                      labelText: l10n.specialOffer,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDetailsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.roomInfo,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bedType,
                    decoration: InputDecoration(
                      labelText: l10n.bedType,
                      border: const OutlineInputBorder(),
                    ),
                    items: _bedTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getBedTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _bedType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _bedCount,
                    decoration: InputDecoration(
                      labelText: l10n.bedCount,
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(5, (index) => index + 1).map((count) {
                      return DropdownMenuItem(
                        value: count,
                        child: Text(count.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _bedCount = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _maxGuests,
                    decoration: InputDecoration(
                      labelText: l10n.maxGuests,
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(10, (index) => index + 1).map((count) {
                      return DropdownMenuItem(
                        value: count,
                        child: Text('$count ${count == 1 ? 'guest' : 'guests'}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _maxGuests = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _sizeController,
                    decoration: InputDecoration(
                      labelText: l10n.roomSize,
                      border: const OutlineInputBorder(),
                      suffixText: 'm²',
                      hintText: l10n.roomSizeHint,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalRoomsController,
              decoration: InputDecoration(
                labelText: l10n.totalRooms,
                border: const OutlineInputBorder(),
                helperText: 'Number of this room type available',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterTotalRooms;
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
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
              l10n.roomAmenities,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              children: [
                Text(
                  l10n.roomImages,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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
                    ..._existingImageUrls.map((url) => _buildExistingImageItem(url)),
                    ..._selectedImages.map((file) => _buildNewImageItem(file)),
                  ],
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(l10n.noImages, style: TextStyle(color: Colors.grey[600])),
                  ],
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

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    setState(() {
      _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
    });
  }

  String _getRoomTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'standard':
        return l10n.standardRoom;
      case 'deluxe':
        return l10n.deluxeRoom;
      case 'suite':
        return l10n.suiteRoom;
      case 'executive':
        return l10n.executiveRoom;
      case 'presidential':
        return l10n.presidentialRoom;
      default:
        return type;
    }
  }

  String _getBedTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'single':
        return l10n.singleBed;
      case 'double':
        return l10n.doubleBed;
      case 'queen':
        return l10n.queenBed;
      case 'king':
        return l10n.kingBed;
      case 'twin':
        return l10n.twinBed;
      default:
        return type;
    }
  }

  String _getAmenityName(String amenity) {
    final l10n = AppLocalizations.of(context)!;
    switch (amenity) {
      case 'wifi':
        return l10n.wifi;
      case 'air_conditioning':
        return l10n.airConditioning;
      case 'tv':
        return l10n.tv;
      case 'minibar':
        return l10n.minibar;
      case 'safe':
        return l10n.safe;
      case 'balcony':
        return l10n.balcony;
      case 'city_view':
        return l10n.cityView;
      case 'ocean_view':
        return l10n.oceanView;
      case 'mountain_view':
        return l10n.mountainView;
      case 'kitchenette':
        return l10n.kitchenette;
      case 'bathtub':
        return l10n.bathtub;
      case 'shower':
        return l10n.shower;
      case 'hairdryer':
        return l10n.hairdryer;
      case 'coffee_maker':
        return l10n.coffeeMaker;
      case 'telephone':
        return l10n.telephone;
      case 'desk':
        return l10n.desk;
      case 'sofa':
        return l10n.sofa;
      default:
        return amenity.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedHotelId == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectHotelFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
      // Ownership guard: only allow manage rooms of hotels owned by current user
      final targetHotelId = widget.room?.hotelId ?? _selectedHotelId;
      if (targetHotelId == null || !provider.isOwnedHotelId(targetHotelId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có quyền thao tác trên khách sạn này'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }
      
      // Prepare room data
      final roomData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _roomType,
        'maxGuests': _maxGuests,
        'bedType': _bedType,
        'bedCount': _bedCount,
        'basePrice': double.parse(_basePriceController.text),
        'weekendPrice': double.parse(_weekendPriceController.text),
        'size': _sizeController.text.isNotEmpty ? double.parse(_sizeController.text) : null,
        'totalRooms': int.parse(_totalRoomsController.text),
        'amenities': _selectedAmenities,
        'discountPercentage': _discountController.text.isNotEmpty ? double.parse(_discountController.text) : 0,
        'specialOfferDescription': _specialOfferController.text.trim().isNotEmpty ? _specialOfferController.text.trim() : null,
        'existingImages': _existingImages,
      };

      print('Submitting room data: $roomData');
      print('Selected images: ${_selectedImages.length}');

      bool success;
      if (widget.room != null) {
        // Update existing room - add hotel field
        roomData['hotel'] = widget.room!.hotelId;
        print('Updating room with ID: ${widget.room!.id}');
        success = await provider.updateRoom(widget.room!.id, roomData, _selectedImages);
      } else {
        // Create new room
        print('Creating new room for hotel: $_selectedHotelId');
        success = await provider.createRoom(_selectedHotelId!, roomData, _selectedImages);
      }

      print('Operation success: $success');

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.room != null ? 'Room updated successfully!' : 'Room created successfully!'),
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
