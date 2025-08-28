// Currency formatting utility
export const formatCurrency = (amount, currency = 'USD') => {
  if (typeof amount !== 'number') {
    return '$0.00';
  }
  
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
};

// Number formatting utility
export const formatNumber = (number) => {
  if (typeof number !== 'number') {
    return '0';
  }
  
  return new Intl.NumberFormat('en-US').format(number);
};

// Percentage formatting utility
export const formatPercentage = (value, decimals = 1) => {
  if (typeof value !== 'number') {
    return '0%';
  }
  
  return `${value.toFixed(decimals)}%`;
};

// Date formatting utility
export const formatDate = (date, format = 'DD/MM/YYYY') => {
  if (!date) return '';
  
  const dayjs = require('dayjs');
  return dayjs(date).format(format);
};

// File size formatting utility
export const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

// Duration formatting utility (in minutes)
export const formatDuration = (minutes) => {
  if (typeof minutes !== 'number') return '0 min';
  
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  
  if (hours > 0) {
    return `${hours}h ${mins}m`;
  }
  return `${mins}m`;
};

// Phone number formatting utility
export const formatPhoneNumber = (phoneNumber) => {
  if (!phoneNumber) return '';
  
  // Remove all non-digit characters
  const cleaned = phoneNumber.replace(/\D/g, '');
  
  // Format as (XXX) XXX-XXXX for US numbers
  if (cleaned.length === 10) {
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`;
  }
  
  // Return as-is if not a standard US number
  return phoneNumber;
};

// Truncate text utility
export const truncateText = (text, maxLength = 100) => {
  if (!text || text.length <= maxLength) return text;
  return text.substr(0, maxLength) + '...';
};

// Capitalize first letter utility
export const capitalizeFirst = (str) => {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
};

// Convert snake_case to Title Case
export const snakeToTitle = (str) => {
  if (!str) return '';
  return str
    .split('_')
    .map(word => capitalizeFirst(word))
    .join(' ');
};
