import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../services/api';

export const fetchRoomsByHotel = createAsyncThunk(
  'rooms/fetchByHotel',
  async (hotelId, { rejectWithValue }) => {
    try {
      // Prefer admin endpoint for full list; fallback to public
      try {
        const res = await api.get(`/admin/hotels/${hotelId}/rooms`);
        return res.data.rooms;
      } catch (e) {
        const res = await api.get(`/rooms/hotel/${hotelId}`);
        return res.data.rooms;
      }
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to fetch rooms' });
    }
  }
);

export const createRoom = createAsyncThunk(
  'rooms/create',
  async (data, { rejectWithValue }) => {
    try {
      const res = await api.post('/rooms', data);
      return res.data.room;
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to create room' });
    }
  }
);

export const updateRoom = createAsyncThunk(
  'rooms/update',
  async ({ id, data }, { rejectWithValue }) => {
    try {
      const res = await api.put(`/rooms/${id}`, data);
      return res.data.room;
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to update room' });
    }
  }
);

export const deleteRoom = createAsyncThunk(
  'rooms/delete',
  async (id, { rejectWithValue }) => {
    try {
      await api.delete(`/rooms/${id}`);
      return id;
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to delete room' });
    }
  }
);

const roomSlice = createSlice({
  name: 'rooms',
  initialState: {
    rooms: [],
    loading: false,
    error: null,
  },
  reducers: {
    clearError: (state) => { state.error = null; },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchRoomsByHotel.pending, (state) => {
        state.loading = true; state.error = null;
      })
      .addCase(fetchRoomsByHotel.fulfilled, (state, action) => {
        state.loading = false; state.rooms = action.payload || [];
      })
      .addCase(fetchRoomsByHotel.rejected, (state, action) => {
        state.loading = false; state.error = action.payload;
      })
      .addCase(createRoom.fulfilled, (state, action) => {
        state.rooms.unshift(action.payload);
      })
      .addCase(updateRoom.fulfilled, (state, action) => {
        const idx = state.rooms.findIndex(r => r._id === action.payload._id);
        if (idx !== -1) state.rooms[idx] = action.payload;
      })
      .addCase(deleteRoom.fulfilled, (state, action) => {
        state.rooms = state.rooms.filter(r => r._id !== action.payload);
      });
  }
});

export const { clearError } = roomSlice.actions;
export default roomSlice.reducer;

