import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import api from '../../services/api';

// Async thunks
export const fetchSettings = createAsyncThunk(
  'settings/fetchSettings',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.get('/admin/settings');
      // Backend returns settings object directly
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch settings');
    }
  }
);

export const updateSettings = createAsyncThunk(
  'settings/updateSettings',
  async (settingsData, { rejectWithValue }) => {
    try {
      const response = await api.put('/admin/settings', settingsData);
      return response.data.settings;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to update settings');
    }
  }
);

export const backupDatabase = createAsyncThunk(
  'settings/backupDatabase',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.post('/admin/settings/backup');
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to backup database');
    }
  }
);

export const restoreDatabase = createAsyncThunk(
  'settings/restoreDatabase',
  async (backupFile, { rejectWithValue }) => {
    try {
      const formData = new FormData();
      formData.append('backup', backupFile);
      const response = await api.post('/admin/settings/restore', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to restore database');
    }
  }
);

export const testEmailSettings = createAsyncThunk(
  'settings/testEmailSettings',
  async (emailSettings, { rejectWithValue }) => {
    try {
      const response = await api.post('/admin/settings/test-email', emailSettings);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to test email settings');
    }
  }
);

export const resetToDefaults = createAsyncThunk(
  'settings/resetToDefaults',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.post('/admin/settings/reset');
      return response.data.settings;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Failed to reset settings');
    }
  }
);

const settingsSlice = createSlice({
  name: 'settings',
  initialState: {
    settings: {
      siteName: '',
      siteDescription: '',
      contactEmail: '',
      contactPhone: '',
      address: '',
      currency: 'VND',
      language: 'vi',
      enableRegistration: true,
      enableBooking: true,
      enableReviews: true,
      paymentMethods: {
        vnpay: { enabled: false, config: {} },
        momo: { enabled: false, config: {} },
        bankTransfer: { enabled: true, config: {} },
      },
      emailSettings: {
        smtpHost: '',
        smtpPort: 587,
        smtpUser: '',
        smtpPassword: '',
        fromEmail: '',
        fromName: '',
      },
      smsSettings: {
        provider: '',
        apiKey: '',
        enabled: false,
      },
    },
    loading: false,
    error: null,
    backupLoading: false,
    restoreLoading: false,
  },
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    updateSettingsLocal: (state, action) => {
      state.settings = { ...state.settings, ...action.payload };
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch settings
      .addCase(fetchSettings.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchSettings.fulfilled, (state, action) => {
        state.loading = false;
        // Merge direct settings object
        state.settings = { ...state.settings, ...action.payload };
      })
      .addCase(fetchSettings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Update settings
      .addCase(updateSettings.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateSettings.fulfilled, (state, action) => {
        state.loading = false;
        state.settings = { ...state.settings, ...action.payload };
      })
      .addCase(updateSettings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Backup database
      .addCase(backupDatabase.pending, (state) => {
        state.backupLoading = true;
        state.error = null;
      })
      .addCase(backupDatabase.fulfilled, (state) => {
        state.backupLoading = false;
      })
      .addCase(backupDatabase.rejected, (state, action) => {
        state.backupLoading = false;
        state.error = action.payload;
      })
      // Restore database
      .addCase(restoreDatabase.pending, (state) => {
        state.restoreLoading = true;
        state.error = null;
      })
      .addCase(restoreDatabase.fulfilled, (state) => {
        state.restoreLoading = false;
      })
      .addCase(restoreDatabase.rejected, (state, action) => {
        state.restoreLoading = false;
        state.error = action.payload;
      })
      // Test email settings
      .addCase(testEmailSettings.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(testEmailSettings.fulfilled, (state) => {
        state.loading = false;
      })
      .addCase(testEmailSettings.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })
      // Reset to defaults
      .addCase(resetToDefaults.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(resetToDefaults.fulfilled, (state, action) => {
        state.loading = false;
        state.settings = { ...state.settings, ...action.payload };
      })
      .addCase(resetToDefaults.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { clearError, updateSettingsLocal } = settingsSlice.actions;
export default settingsSlice.reducer;
