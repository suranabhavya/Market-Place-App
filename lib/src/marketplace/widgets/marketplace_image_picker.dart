import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_detail_model.dart';

class MarketplaceImagePicker extends StatelessWidget {
  final List<File> images;
  final List<MarketplaceDetailImage> existingImages;
  final Function(ImageSource) onPickImage;
  final Function(int) onRemoveImage;
  final Function(int) onRemoveExistingImage;

  const MarketplaceImagePicker({
    super.key,
    required this.images,
    required this.existingImages,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onRemoveExistingImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Images", 
          style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildImagePickerButton(
              icon: Icons.photo,
              label: "Pick from Gallery",
              onTap: () => onPickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 10),
            _buildImagePickerButton(
              icon: Icons.camera,
              label: "Take Photo",
              onTap: () => onPickImage(ImageSource.camera),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (existingImages.isNotEmpty) _buildExistingImagesSection(),
        if (images.isNotEmpty) _buildNewImagesSection(),
        if (images.isEmpty && existingImages.isEmpty)
          Text(
            "No images selected.",
            style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
          ),
      ],
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Kolors.kPrimary),
      label: Text(
        label,
        style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
      ),
    );
  }

  Widget _buildExistingImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Current Images", 
          style: appStyle(14, Kolors.kPrimary, FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: existingImages
              .asMap()
              .entries
              .map((entry) => _buildImageThumbnail(
                    imageUrl: entry.value.image,
                    onRemove: () => onRemoveExistingImage(entry.key),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNewImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (existingImages.isNotEmpty)
          Text(
            "New Images", 
            style: appStyle(14, Kolors.kPrimary, FontWeight.w500),
          ),
        if (existingImages.isNotEmpty)
          const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: images
              .asMap()
              .entries
              .map((entry) => _buildImageThumbnail(
                    imageFile: entry.value,
                    onRemove: () => onRemoveImage(entry.key),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail({
    String? imageUrl,
    File? imageFile,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        if (imageFile != null)
          Image.file(
            imageFile,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          )
        else
          Image.network(
            imageUrl!,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
              Container(
                height: 100,
                width: 100,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
} 