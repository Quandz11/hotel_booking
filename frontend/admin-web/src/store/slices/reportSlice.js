import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../services/api';

// Async thunks
export const fetchRevenueReport = createAsyncThunk(
  'reports/fetchRevenueReport',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await api.get('/admin/reports/revenue', { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch revenue report');
    }
  }
);

export const fetchBookingReport = createAsyncThunk(
  'reports/fetchBookingReport',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await api.get('/admin/reports/bookings', { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch booking report');
    }
  }
);

export const fetchUserReport = createAsyncThunk(
  'reports/fetchUserReport',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await api.get('/admin/reports/users', { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch user report');
    }
  }
);

export const fetchHotelReport = createAsyncThunk(
  'reports/fetchHotelReport',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await api.get('/admin/reports/hotels', { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch hotel report');
    }
  }
);

export const exportReport = createAsyncThunk(
  'reports/exportReport',
  async ({ reportType, format, params = {} }, { rejectWithValue }) => {
    try {
      const response = await api.get(`/admin/reports/${reportType}/export`, {
        params: { ...params, format },
        responseType: 'blob',
      });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to export report');
    }
  }
);

const reportSlice = createSlice({
  name: 'reports',
  initialState: {
    revenueReport: {
      data: [],
      summary: {
        totalRevenue: 0,
        totalBookings: 0,
        averageBookingValue: 0,
        growth: 0,
      },
      loading: false,
      error: null,
    },
    bookingReport: {
      data: [],
      summary: {
        totalBookings: 0,
        confirmedBookings: 0,
        cancelledBookings: 0,
        pendingBookings: 0,
      },
      loading: false,
      error: null,
    },
    userReport: {
      data: [],
      summary: {
        totalUsers: 0,
        activeUsers: 0,
        newUsers: 0,
        growth: 0,
      },
      loading: false,
      error: null,
    },
    hotelReport: {
      data: [],
      summary: {
        totalHotels: 0,
        activeHotels: 0,
        averageRating: 0,
        totalRooms: 0,
      },
      loading: false,
      error: null,
    },
    exportLoading: false,
    exportError: null,
  },
  reducers: {
    clearError: (state) => {
      state.revenueReport.error = null;
      state.bookingReport.error = null;
      state.userReport.error = null;
      state.hotelReport.error = null;
      state.exportError = null;
    },
    clearReportData: (state, action) => {
      const reportType = action.payload;
      if (state[reportType]) {
        state[reportType].data = [];
      }
    },
  },
  extraReducers: (builder) => {
    builder
      // Revenue report
      .addCase(fetchRevenueReport.pending, (state) => {
        state.revenueReport.loading = true;
        state.revenueReport.error = null;
      })
      .addCase(fetchRevenueReport.fulfilled, (state, action) => {
        state.revenueReport.loading = false;
        state.revenueReport.data = action.payload.data;
        state.revenueReport.summary = action.payload.summary;
      })
      .addCase(fetchRevenueReport.rejected, (state, action) => {
        state.revenueReport.loading = false;
        state.revenueReport.error = action.payload;
      })
      // Booking report
      .addCase(fetchBookingReport.pending, (state) => {
        state.bookingReport.loading = true;
        state.bookingReport.error = null;
      })
      .addCase(fetchBookingReport.fulfilled, (state, action) => {
        state.bookingReport.loading = false;
        state.bookingReport.data = action.payload.data;
        state.bookingReport.summary = action.payload.summary;
      })
      .addCase(fetchBookingReport.rejected, (state, action) => {
        state.bookingReport.loading = false;
        state.bookingReport.error = action.payload;
      })
      // User report
      .addCase(fetchUserReport.pending, (state) => {
        state.userReport.loading = true;
        state.userReport.error = null;
      })
      .addCase(fetchUserReport.fulfilled, (state, action) => {
        state.userReport.loading = false;
        state.userReport.data = action.payload.data;
        state.userReport.summary = action.payload.summary;
      })
      .addCase(fetchUserReport.rejected, (state, action) => {
        state.userReport.loading = false;
        state.userReport.error = action.payload;
      })
      // Hotel report
      .addCase(fetchHotelReport.pending, (state) => {
        state.hotelReport.loading = true;
        state.hotelReport.error = null;
      })
      .addCase(fetchHotelReport.fulfilled, (state, action) => {
        state.hotelReport.loading = false;
        state.hotelReport.data = action.payload.data;
        state.hotelReport.summary = action.payload.summary;
      })
      .addCase(fetchHotelReport.rejected, (state, action) => {
        state.hotelReport.loading = false;
        state.hotelReport.error = action.payload;
      })
      // Export report
      .addCase(exportReport.pending, (state) => {
        state.exportLoading = true;
        state.exportError = null;
      })
      .addCase(exportReport.fulfilled, (state) => {
        state.exportLoading = false;
      })
      .addCase(exportReport.rejected, (state, action) => {
        state.exportLoading = false;
        state.exportError = action.payload;
      });
  },
});

export const { clearError, clearReportData } = reportSlice.actions;
export default reportSlice.reducer;
