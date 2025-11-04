const nodemailer = require('nodemailer');

// Create transporter
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: process.env.EMAIL_PORT,
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

// Send email verification
const sendEmailVerification = async (email, token, firstName) => {
  const transporter = createTransporter();
  
  const verificationUrl = `${process.env.CLIENT_URL}/verify-email?token=${token}`;
  
  const mailOptions = {
    from: `"Hotel Booking" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Email Verification - Hotel Booking System',
    html: `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h2 style="color: #2c3e50;">Welcome to Hotel Booking System!</h2>
        <p>Hi ${firstName},</p>
        <p>Thank you for registering with our hotel booking system. Please verify your email address by clicking the button below:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" 
             style="background-color: #3498db; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
            Verify Email Address
          </a>
        </div>
        <p>Or copy and paste this link in your browser:</p>
        <p style="word-break: break-all; color: #7f8c8d;">${verificationUrl}</p>
        <p>This link will expire in 24 hours.</p>
        <p>If you didn't create an account, please ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #7f8c8d; font-size: 12px;">
          This is an automated email. Please do not reply to this email.
        </p>
      </div>
    `
  };
  
  await transporter.sendMail(mailOptions);
};

// Send password reset OTP email
const sendPasswordResetOTP = async (email, otp, firstName) => {
  const transporter = createTransporter();
  
  const mailOptions = {
    from: `"Hotel Booking" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Password Reset Code - Hotel Booking System',
    html: `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h2 style="color: #2c3e50;">Password Reset Request</h2>
        <p>Hi ${firstName},</p>
        <p>Use the One-Time Password (OTP) below to reset your account password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <div style="background-color: #f8f9fa; border: 2px dashed #e74c3c; padding: 20px; border-radius: 5px; display: inline-block;">
            <h1 style="margin: 0; color: #e74c3c; font-size: 32px; letter-spacing: 5px;">${otp}</h1>
          </div>
        </div>
        <p>This code will expire in 10 minutes. Please enter it in the app to continue with your password reset.</p>
        <p>If you didn't request a password reset, please ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #7f8c8d; font-size: 12px;">
          This is an automated email. Please do not reply to this email.
        </p>
      </div>
    `
  };
  
  await transporter.sendMail(mailOptions);
};

// Send booking confirmation
const sendBookingConfirmation = async (booking, status = 'confirmed') => {
  const transporter = createTransporter();
  
  // Determine email content based on status
  let subject, title, color, message;
  
  switch (status) {
    case 'confirmed':
      subject = `Booking Confirmed - ${booking.bookingNumber}`;
      title = 'Booking Confirmed!';
      color = '#27ae60';
      message = 'Your hotel booking has been confirmed. Here are the details:';
      break;
    case 'cancelled':
      subject = `Booking Cancelled - ${booking.bookingNumber}`;
      title = 'Booking Cancelled';
      color = '#e74c3c';
      message = 'Your hotel booking has been cancelled. Here are the details:';
      break;
    case 'checked_in':
      subject = `Check-in Confirmed - ${booking.bookingNumber}`;
      title = 'Welcome! Check-in Confirmed';
      color = '#3498db';
      message = 'You have successfully checked in. We hope you enjoy your stay!';
      break;
    default:
      subject = `Booking Update - ${booking.bookingNumber}`;
      title = 'Booking Update';
      color = '#95a5a6';
      message = 'Your booking status has been updated. Here are the details:';
  }
  
  const customerEmail = booking.customer?.email || booking.guestInfo?.email;
  const customerName = booking.customer ? 
    `${booking.customer.firstName} ${booking.customer.lastName}` : 
    `${booking.guestInfo?.firstName} ${booking.guestInfo?.lastName}`;
  
  const mailOptions = {
    from: `"Hotel Booking" <${process.env.EMAIL_USER}>`,
    to: customerEmail,
    subject: subject,
    html: `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h2 style="color: ${color};">${title}</h2>
        <p>Hi ${customerName},</p>
        <p>${message}</p>
        
        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin-top: 0; color: #2c3e50;">Booking Details</h3>
          <p><strong>Booking Number:</strong> ${booking.bookingNumber}</p>
          <p><strong>Hotel:</strong> ${booking.hotel?.name || 'N/A'}</p>
          <p><strong>Room Type:</strong> ${booking.room?.name || 'N/A'}</p>
          <p><strong>Check-in:</strong> ${new Date(booking.checkIn).toLocaleDateString()}</p>
          <p><strong>Check-out:</strong> ${new Date(booking.checkOut).toLocaleDateString()}</p>
          <p><strong>Guests:</strong> ${booking.guests?.adults || booking.adults} adults${(booking.guests?.children || booking.children) > 0 ? `, ${booking.guests?.children || booking.children} children` : ''}</p>
          <p><strong>Total Amount:</strong> ${booking.totalAmount.toLocaleString()} ${booking.currency}</p>
          <p><strong>Status:</strong> ${status.charAt(0).toUpperCase() + status.slice(1).replace('_', ' ')}</p>
        </div>
        
        <p>Please save this email for your records. You'll need your booking number at check-in.</p>
        <p>If you have any questions, please contact us or the hotel directly.</p>
        
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #7f8c8d; font-size: 12px;">
          This is an automated email. Please do not reply to this email.
        </p>
      </div>
    `
  };
  
  await transporter.sendMail(mailOptions);
};

// Send OTP
const sendOTP = async (email, otp, firstName) => {
  const transporter = createTransporter();
  
  const mailOptions = {
    from: `"Hotel Booking" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'OTP Verification - Hotel Booking System',
    html: `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h2 style="color: #2c3e50;">OTP Verification</h2>
        <p>Hi ${firstName},</p>
        <p>Your One-Time Password (OTP) for verification is:</p>
        <div style="text-align: center; margin: 30px 0;">
          <div style="background-color: #f8f9fa; border: 2px dashed #3498db; padding: 20px; border-radius: 5px; display: inline-block;">
            <h1 style="margin: 0; color: #3498db; font-size: 32px; letter-spacing: 5px;">${otp}</h1>
          </div>
        </div>
        <p>This OTP will expire in 10 minutes.</p>
        <p>If you didn't request this OTP, please ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #7f8c8d; font-size: 12px;">
          This is an automated email. Please do not reply to this email.
        </p>
      </div>
    `
  };
  
  await transporter.sendMail(mailOptions);
};

module.exports = {
  sendEmailVerification,
  sendPasswordResetOTP,
  sendBookingConfirmation,
  sendOTP
};
