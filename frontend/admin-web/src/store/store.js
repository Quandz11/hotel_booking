import { configureStore } from '@reduxjs/toolkit';
import authSlice from './slices/authSlice';
import hotelSlice from './slices/hotelSlice';
import userSlice from './slices/userSlice';
import bookingSlice from './slices/bookingSlice';
import reviewSlice from './slices/reviewSlice';
import dashboardSlice from './slices/dashboardSlice';
import settingsSlice from './slices/settingsSlice';
import reportSlice from './slices/reportSlice';
import roomSlice from './slices/roomSlice';

export const store = configureStore({
  reducer: {
    auth: authSlice,
    hotels: hotelSlice,
    users: userSlice,
    bookings: bookingSlice,
    reviews: reviewSlice,
    rooms: roomSlice,
    dashboard: dashboardSlice,
    settings: settingsSlice,
    reports: reportSlice,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST'],
      },
    }),
});
