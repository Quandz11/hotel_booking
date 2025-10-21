import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../services/api';

// Async thunks
export const fetchUsers = createAsyncThunk(
  'users/fetchUsers',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await api.get('/admin/users', { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch users');
    }
  }
);

export const fetchUserById = createAsyncThunk(
  'users/fetchUserById',
  async (id, { rejectWithValue }) => {
    try {
      console.log('🌐 API: Fetching user by ID:', id);
      const response = await api.get(`/admin/users/${id}`);
      console.log('✅ API: User fetched successfully:', response.data);
      return response.data.user;
    } catch (error) {
      console.error('❌ API: Failed to fetch user:', error.response?.data || error.message);
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch user');
    }
  }
);

export const createUser = createAsyncThunk(
  'users/createUser',
  async (userData, { rejectWithValue }) => {
    try {
      const response = await api.post('/admin/users', userData);
      return response.data.user;
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to create user' });
    }
  }
);

export const updateUser = createAsyncThunk(
  'users/updateUser',
  async ({ id, data }, { rejectWithValue }) => {
    try {
      const response = await api.put(`/admin/users/${id}`, data);
      return response.data.user;
    } catch (error) {
      return rejectWithValue(error.response?.data || { message: 'Failed to update user' });
    }
  }
);

export const deleteUser = createAsyncThunk(
  'users/deleteUser',
  async (id, { rejectWithValue }) => {
    try {
      await api.delete(`/admin/users/${id}`);
      return id;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to delete user');
    }
  }
);

export const updateUserStatus = createAsyncThunk(
  'users/updateUserStatus',
  async ({ id, isActive, isApproved }, { rejectWithValue }) => {
    try {
      const response = await api.patch(`/admin/users/${id}/status`, { 
        isActive, 
        isApproved 
      });
      return response.data.user;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to update user status');
    }
  }
);

export const updateUserPassword = createAsyncThunk(
  'users/updateUserPassword',
  async ({ id, newPassword }, { rejectWithValue }) => {
    try {
      const response = await api.patch(`/admin/users/${id}/password`, { newPassword });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to update user password');
    }
  }
);

export const fetchUserHotels = createAsyncThunk(
  'users/fetchUserHotels',
  async (userId, { rejectWithValue }) => {
    try {
      const response = await api.get(`/admin/users/${userId}/hotels`);
      return response.data.hotels;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch user hotels');
    }
  }
);

export const fetchUserBookings = createAsyncThunk(
  'users/fetchUserBookings',
  async (userId, { rejectWithValue }) => {
    try {
      const response = await api.get(`/admin/users/${userId}/bookings`);
      return response.data.bookings;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch user bookings');
    }
  }
);

export const fetchUserReviews = createAsyncThunk(
  'users/fetchUserReviews',
  async (userId, { rejectWithValue }) => {
    try {
      const response = await api.get(`/admin/users/${userId}/reviews`);
      return response.data.reviews;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch user reviews');
    }
  }
);

const userSlice = createSlice({
  name: 'users',
  initialState: {
    users: [],
    currentUser: null,
    userHotels: [],
    userBookings: [],
    userReviews: [],
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
      role: null,
      isActive: null,
      isApproved: null,
    },
  },
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setFilters: (state, action) => {
      state.filters = { ...state.filters, ...action.payload };
    },
    clearCurrentUser: (state) => {
      state.currentUser = null;
      state.userHotels = [];
      state.userBookings = [];
      state.userReviews = [];
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch users
      .addCase(fetchUsers.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchUsers.fulfilled, (state, action) => {
        state.loading = false;
        state.users = action.payload.users;
        state.pagination = action.payload.pagination;
      })
      .addCase(fetchUsers.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Fetch user by ID
      .addCase(fetchUserById.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchUserById.fulfilled, (state, action) => {
        state.loading = false;
        state.currentUser = action.payload;
      })
      .addCase(fetchUserById.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Create user
      .addCase(createUser.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(createUser.fulfilled, (state, action) => {
        state.loading = false;
        state.users.unshift(action.payload);
        state.pagination.total += 1;
      })
      .addCase(createUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Update user
      .addCase(updateUser.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateUser.fulfilled, (state, action) => {
        state.loading = false;
        const index = state.users.findIndex(user => user._id === action.payload._id);
        if (index !== -1) {
          state.users[index] = action.payload;
        }
        if (state.currentUser && state.currentUser._id === action.payload._id) {
          state.currentUser = action.payload;
        }
      })
      .addCase(updateUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Delete user
      .addCase(deleteUser.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(deleteUser.fulfilled, (state, action) => {
        state.loading = false;
        state.users = state.users.filter(user => user._id !== action.payload);
        state.pagination.total -= 1;
        if (state.currentUser && state.currentUser._id === action.payload) {
          state.currentUser = null;
        }
      })
      .addCase(deleteUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Update user status
      .addCase(updateUserStatus.fulfilled, (state, action) => {
        const index = state.users.findIndex(user => user._id === action.payload.id);
        if (index !== -1) {
          state.users[index].isActive = action.payload.isActive;
          state.users[index].isApproved = action.payload.isApproved;
        }
        if (state.currentUser && state.currentUser._id === action.payload.id) {
          state.currentUser.isActive = action.payload.isActive;
          state.currentUser.isApproved = action.payload.isApproved;
        }
      })
      // Update user password
      .addCase(updateUserPassword.fulfilled, (state, action) => {
        // Password update doesn't need to update state, just show success message
      })
      // Fetch user hotels
      .addCase(fetchUserHotels.fulfilled, (state, action) => {
        state.userHotels = action.payload;
      })
      // Fetch user bookings
      .addCase(fetchUserBookings.fulfilled, (state, action) => {
        state.userBookings = action.payload;
      })
      // Fetch user reviews
      .addCase(fetchUserReviews.fulfilled, (state, action) => {
        state.userReviews = action.payload;
      });
  },
});

export const { clearError, setFilters, clearCurrentUser } = userSlice.actions;
export default userSlice.reducer;
