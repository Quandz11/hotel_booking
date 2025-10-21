import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../services/api';

// Async thunks
export const fetchHotels = createAsyncThunk(
  'hotels/fetchHotels',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await api.get('/admin/hotels', { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch hotels');
    }
  }
);

export const fetchHotelById = createAsyncThunk(
  'hotels/fetchHotelById',
  async (id, { rejectWithValue }) => {
    try {
      const response = await api.get(`/hotels/${id}`);
      // Backend returns { success: true, data: hotel } structure
      return response.data.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch hotel');
    }
  }
);

export const createHotel = createAsyncThunk(
  'hotels/createHotel',
  async (hotelData, { rejectWithValue }) => {
    try {
      const response = await api.post('/hotels', hotelData);
      // Backend returns { success, message, data }
      return response.data.data;
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to create hotel' });
    }
  }
);

export const updateHotel = createAsyncThunk(
  'hotels/updateHotel',
  async ({ id, data }, { rejectWithValue }) => {
    try {
      const response = await api.put(`/hotels/${id}`, data);
      // Backend returns { success, message, data }
      return response.data.data;
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to update hotel' });
    }
  }
);

export const deleteHotel = createAsyncThunk(
  'hotels/deleteHotel',
  async (id, { rejectWithValue }) => {
    try {
      await api.delete(`/hotels/${id}`);
      return id;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to delete hotel');
    }
  }
);

export const approveHotel = createAsyncThunk(
  'hotels/approveHotel',
  async ({ id, data }, { rejectWithValue }) => {
    try {
      const response = await api.patch(`/admin/hotels/${id}/approval`, data);
      return response.data.hotel;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to approve hotel');
    }
  }
);

const hotelSlice = createSlice({
  name: 'hotels',
  initialState: {
    hotels: [],
    currentHotel: null,
    pagination: {
      page: 1,
      limit: 10,
      total: 0,
      pages: 0,
    },
    loading: false,
    error: null,
    filters: {
      search: '',
      isApproved: null,
      isActive: null,
      starRating: null,
    },
  },
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setFilters: (state, action) => {
      state.filters = { ...state.filters, ...action.payload };
    },
    clearCurrentHotel: (state) => {
      state.currentHotel = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch hotels
      .addCase(fetchHotels.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHotels.fulfilled, (state, action) => {
        state.loading = false;
        state.hotels = action.payload.hotels;
        state.pagination = action.payload.pagination;
      })
      .addCase(fetchHotels.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Fetch hotel by ID
      .addCase(fetchHotelById.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchHotelById.fulfilled, (state, action) => {
        state.loading = false;
        state.currentHotel = action.payload;
      })
      .addCase(fetchHotelById.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Create hotel
      .addCase(createHotel.fulfilled, (state, action) => {
        state.hotels.unshift(action.payload);
      })
      // Update hotel
      .addCase(updateHotel.fulfilled, (state, action) => {
        const index = state.hotels.findIndex(hotel => hotel._id === action.payload._id);
        if (index !== -1) {
          state.hotels[index] = action.payload;
        }
        if (state.currentHotel?._id === action.payload._id) {
          state.currentHotel = action.payload;
        }
      })
      // Delete hotel
      .addCase(deleteHotel.fulfilled, (state, action) => {
        state.hotels = state.hotels.filter(hotel => hotel._id !== action.payload);
      })
      // Approve hotel
      .addCase(approveHotel.fulfilled, (state, action) => {
        const index = state.hotels.findIndex(hotel => hotel._id === action.payload.id);
        if (index !== -1) {
          state.hotels[index].isApproved = action.payload.isApproved;
        }
      });
  },
});

export const { clearError, setFilters, clearCurrentHotel } = hotelSlice.actions;
export default hotelSlice.reducer;
