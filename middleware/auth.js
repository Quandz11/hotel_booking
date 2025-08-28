const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Verify JWT token
const authenticate = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'Access denied. No token provided.' });
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-password -refreshToken');
    
    if (!user || !user.isActive) {
      return res.status(401).json({ message: 'Invalid token or user not found.' });
    }
    
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired.' });
    }
    res.status(401).json({ message: 'Invalid token.' });
  }
};

// Check user role
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Access denied. Please login.' });
    }
    
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: 'Access denied. Insufficient permissions.' 
      });
    }
    
    next();
  };
};

// Check if user owns the resource or is admin
const authorizeOwnerOrAdmin = (resourceField = 'owner') => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Access denied. Please login.' });
    }
    
    // Admin can access everything
    if (req.user.role === 'admin') {
      return next();
    }
    
    // Check if user owns the resource
    const resourceOwnerId = req[resourceField] || req.body[resourceField] || req.params.userId;
    
    if (req.user._id.toString() !== resourceOwnerId.toString()) {
      return res.status(403).json({ 
        message: 'Access denied. You can only access your own resources.' 
      });
    }
    
    next();
  };
};

// Verify email is confirmed
const requireEmailVerification = (req, res, next) => {
  if (!req.user.isEmailVerified) {
    return res.status(403).json({ 
      message: 'Please verify your email before accessing this resource.' 
    });
  }
  next();
};

// Check if hotel owner is approved
const requireApprovedHotelOwner = (req, res, next) => {
  if (req.user.role === 'hotel_owner' && !req.user.isApproved) {
    return res.status(403).json({ 
      message: 'Your hotel owner account is pending approval.' 
    });
  }
  next();
};

module.exports = {
  authenticate,
  authorize,
  authorizeOwnerOrAdmin,
  requireEmailVerification,
  requireApprovedHotelOwner
};
