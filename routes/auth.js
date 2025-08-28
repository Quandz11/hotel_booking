const express = require('express');
const { body } = require('express-validator');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { generateTokens, verifyRefreshToken, generateRandomToken, hashToken, generateOTP } = require('../utils/auth');
const { sendEmailVerification, sendPasswordReset, sendOTP } = require('../utils/email');
const { validate, asyncHandler } = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Register validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('firstName').notEmpty().trim().withMessage('First name is required'),
  body('lastName').notEmpty().trim().withMessage('Last name is required'),
  body('phone').isMobilePhone().withMessage('Please provide a valid phone number'),
  body('role').optional().isIn(['customer', 'hotel_owner']).withMessage('Invalid role')
];

// Login validation rules
const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').notEmpty().withMessage('Password is required')
];

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
router.post('/register', registerValidation, validate, asyncHandler(async (req, res) => {
  const { email, password, firstName, lastName, phone, role = 'customer' } = req.body;
  
  // Check if user exists
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(400).json({ message: 'User already exists with this email' });
  }
  
  // Create user
  const user = new User({
    email,
    password,
    firstName,
    lastName,
    phone,
    role
  });
  
  // Generate OTP for email verification
  const otp = generateOTP();
  user.emailVerificationOTP = otp;
  user.emailVerificationOTPExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
  
  await user.save();
  
  // Send OTP email
  try {
    await sendOTP(email, otp, firstName);
  } catch (error) {
    console.error('Email sending failed:', error);
  }
  
  // Generate JWT tokens
  const { accessToken, refreshToken } = generateTokens(user._id);
  user.refreshToken = refreshToken;
  await user.save();
  
  res.status(201).json({
    message: 'User registered successfully. Please check your email for the verification OTP.',
    user: {
      id: user._id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
      avatar: user.avatar
    },
    accessToken,
    refreshToken
  });
}));

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
router.post('/login', loginValidation, validate, asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  
  // Find user
  const user = await User.findOne({ email }).select('+password');
  if (!user || !user.isActive) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }
  
  // Check password
  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }
  
  // Generate tokens
  const { accessToken, refreshToken } = generateTokens(user._id);
  user.refreshToken = refreshToken;
  user.lastLogin = new Date();
  await user.save();
  
  res.json({
    message: 'Login successful',
    user: {
      id: user._id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
      membershipTier: user.membershipTier,
      isApproved: user.isApproved,
      avatar: user.avatar
    },
    accessToken,
    refreshToken
  });
}));

// @desc    Refresh token
// @route   POST /api/auth/refresh
// @access  Public
router.post('/refresh', asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  
  if (!refreshToken) {
    return res.status(401).json({ message: 'Refresh token required' });
  }
  
  try {
    const decoded = verifyRefreshToken(refreshToken);
    const user = await User.findById(decoded.id);
    
    if (!user || user.refreshToken !== refreshToken || !user.isActive) {
      return res.status(401).json({ message: 'Invalid refresh token' });
    }
    
    // Generate new tokens
    const tokens = generateTokens(user._id);
    user.refreshToken = tokens.refreshToken;
    await user.save();
    
    res.json({
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken
    });
  } catch (error) {
    res.status(401).json({ message: 'Invalid refresh token' });
  }
}));

// @desc    Verify email with OTP
// @route   POST /api/auth/verify-otp
// @access  Public
router.post('/verify-otp', [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('Valid OTP is required')
], validate, asyncHandler(async (req, res) => {
  const { email, otp } = req.body;
  
  const user = await User.findOne({ 
    email,
    emailVerificationOTP: otp,
    emailVerificationOTPExpires: { $gt: Date.now() }
  });
  
  if (!user) {
    return res.status(400).json({ message: 'Invalid or expired OTP' });
  }
  
  user.isEmailVerified = true;
  user.emailVerificationOTP = undefined;
  user.emailVerificationOTPExpires = undefined;
  user.emailVerificationToken = undefined; // Clear any old token if exists
  
  await user.save();
  
  res.json({ 
    message: 'Email verified successfully',
    user: {
      id: user._id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      isEmailVerified: user.isEmailVerified
    }
  });
}));

// @desc    Resend verification OTP
// @route   POST /api/auth/resend-otp
// @access  Public
router.post('/resend-otp', [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email')
], validate, asyncHandler(async (req, res) => {
  const { email } = req.body;
  
  const user = await User.findOne({ email });
  
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  if (user.isEmailVerified) {
    return res.status(400).json({ message: 'Email is already verified' });
  }
  
  // Generate new OTP
  const otp = generateOTP();
  user.emailVerificationOTP = otp;
  user.emailVerificationOTPExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
  
  await user.save();
  
  try {
    await sendOTP(user.email, otp, user.firstName);
    res.json({ message: 'Verification OTP sent successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to send verification OTP' });
  }
}));

// @desc    Forgot password
// @route   POST /api/auth/forgot-password
// @access  Public
router.post('/forgot-password', [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email')
], validate, asyncHandler(async (req, res) => {
  const { email } = req.body;
  
  const user = await User.findOne({ email });
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  // Generate reset token
  const resetToken = generateRandomToken();
  user.passwordResetToken = hashToken(resetToken);
  user.passwordResetExpires = Date.now() + 60 * 60 * 1000; // 1 hour
  await user.save();
  
  try {
    await sendPasswordReset(email, resetToken, user.firstName);
    res.json({ message: 'Password reset email sent successfully' });
  } catch (error) {
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save();
    res.status(500).json({ message: 'Failed to send password reset email' });
  }
}));

// @desc    Reset password
// @route   POST /api/auth/reset-password
// @access  Public
router.post('/reset-password', [
  body('token').notEmpty().withMessage('Reset token is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], validate, asyncHandler(async (req, res) => {
  const { token, password } = req.body;
  
  const hashedToken = hashToken(token);
  const user = await User.findOne({
    passwordResetToken: hashedToken,
    passwordResetExpires: { $gt: Date.now() }
  });
  
  if (!user) {
    return res.status(400).json({ message: 'Invalid or expired reset token' });
  }
  
  user.password = password;
  user.passwordResetToken = undefined;
  user.passwordResetExpires = undefined;
  await user.save();
  
  res.json({ message: 'Password reset successfully' });
}));

// @desc    Logout
// @route   POST /api/auth/logout
// @access  Private
router.post('/logout', authenticate, asyncHandler(async (req, res) => {
  req.user.refreshToken = undefined;
  await req.user.save();
  
  res.json({ message: 'Logged out successfully' });
}));

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
router.get('/me', authenticate, (req, res) => {
  res.json({
    user: {
      id: req.user._id,
      email: req.user.email,
      firstName: req.user.firstName,
      lastName: req.user.lastName,
      phone: req.user.phone,
      role: req.user.role,
      isEmailVerified: req.user.isEmailVerified,
      membershipTier: req.user.membershipTier,
      totalSpent: req.user.totalSpent,
      isApproved: req.user.isApproved,
      avatar: req.user.avatar,
      address: req.user.address
    }
  });
});

module.exports = router;
