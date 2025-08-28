const express = require('express');
const multer = require('multer');
const { cloudinary } = require('../utils/cloudinary');
const { authenticate } = require('../middleware/auth');
const { asyncHandler } = require('../middleware/validation');

const router = express.Router();

// Configure multer for memory storage
const storage = multer.memoryStorage();
const upload = multer({ 
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Check file type
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// @desc    Upload single image
// @route   POST /api/upload/image
// @access  Private
router.post('/image', authenticate, upload.single('image'), asyncHandler(async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No image file provided' });
  }
  
  try {
    // Convert buffer to base64
    const b64 = Buffer.from(req.file.buffer).toString('base64');
    const dataURI = `data:${req.file.mimetype};base64,${b64}`;
    
    // Upload to Cloudinary
    const result = await cloudinary.uploader.upload(dataURI, {
      folder: 'hotel-booking',
      use_filename: true,
      unique_filename: true,
      transformation: [
        { quality: 'auto' },
        { fetch_format: 'auto' }
      ]
    });
    
    res.json({
      message: 'Image uploaded successfully',
      image: {
        url: result.secure_url,
        publicId: result.public_id,
        width: result.width,
        height: result.height
      }
    });
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    res.status(500).json({ message: 'Failed to upload image' });
  }
}));

// @desc    Upload multiple images
// @route   POST /api/upload/images
// @access  Private
router.post('/images', authenticate, upload.array('images', 10), asyncHandler(async (req, res) => {
  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ message: 'No image files provided' });
  }
  
  try {
    const uploadPromises = req.files.map(async (file) => {
      const b64 = Buffer.from(file.buffer).toString('base64');
      const dataURI = `data:${file.mimetype};base64,${b64}`;
      
      const result = await cloudinary.uploader.upload(dataURI, {
        folder: 'hotel-booking',
        use_filename: true,
        unique_filename: true,
        transformation: [
          { quality: 'auto' },
          { fetch_format: 'auto' }
        ]
      });
      
      return {
        url: result.secure_url,
        publicId: result.public_id,
        width: result.width,
        height: result.height
      };
    });
    
    const images = await Promise.all(uploadPromises);
    
    res.json({
      message: `${images.length} images uploaded successfully`,
      images
    });
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    res.status(500).json({ message: 'Failed to upload images' });
  }
}));

// @desc    Delete image
// @route   DELETE /api/upload/image/:publicId
// @access  Private
router.delete('/image/:publicId', authenticate, asyncHandler(async (req, res) => {
  const { publicId } = req.params;
  
  try {
    const result = await cloudinary.uploader.destroy(publicId);
    
    if (result.result === 'ok') {
      res.json({ message: 'Image deleted successfully' });
    } else {
      res.status(404).json({ message: 'Image not found' });
    }
  } catch (error) {
    console.error('Cloudinary delete error:', error);
    res.status(500).json({ message: 'Failed to delete image' });
  }
}));

// @desc    Upload document (for hotel owners)
// @route   POST /api/upload/document
// @access  Private
router.post('/document', authenticate, upload.single('document'), asyncHandler(async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No document file provided' });
  }
  
  // Check file type for documents
  const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
  if (!allowedTypes.includes(req.file.mimetype)) {
    return res.status(400).json({ 
      message: 'Only JPEG, PNG, and PDF files are allowed for documents' 
    });
  }
  
  try {
    // Convert buffer to base64
    const b64 = Buffer.from(req.file.buffer).toString('base64');
    const dataURI = `data:${req.file.mimetype};base64,${b64}`;
    
    // Upload to Cloudinary
    const result = await cloudinary.uploader.upload(dataURI, {
      folder: 'hotel-booking/documents',
      use_filename: true,
      unique_filename: true,
      resource_type: 'auto' // Allows PDFs and other file types
    });
    
    res.json({
      message: 'Document uploaded successfully',
      document: {
        url: result.secure_url,
        publicId: result.public_id,
        format: result.format,
        resourceType: result.resource_type
      }
    });
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    res.status(500).json({ message: 'Failed to upload document' });
  }
}));

// @desc    Get upload signature for direct upload
// @route   GET /api/upload/signature
// @access  Private
router.get('/signature', authenticate, asyncHandler(async (req, res) => {
  const timestamp = Math.round(new Date().getTime() / 1000);
  const params = {
    timestamp,
    folder: 'hotel-booking',
    use_filename: true,
    unique_filename: true
  };
  
  try {
    const signature = cloudinary.utils.api_sign_request(params, process.env.CLOUDINARY_API_SECRET);
    
    res.json({
      signature,
      timestamp,
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      folder: params.folder
    });
  } catch (error) {
    console.error('Signature generation error:', error);
    res.status(500).json({ message: 'Failed to generate upload signature' });
  }
}));

// Error handling for multer
router.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ message: 'File too large. Maximum size is 10MB.' });
    }
    if (error.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({ message: 'Too many files. Maximum is 10 files.' });
    }
  }
  
  if (error.message === 'Only image files are allowed') {
    return res.status(400).json({ message: error.message });
  }
  
  next(error);
});

module.exports = router;
