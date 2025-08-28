import React, { useState, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Form,
  Input,
  Select,
  Switch,
  Button,
  Space,
  Divider,
  Upload,
  message,
  Tabs,
  InputNumber,
  TimePicker,
  Collapse,
  Tag,
  Modal,
} from 'antd';
import {
  SaveOutlined,
  UploadOutlined,
  PlusOutlined,
  DeleteOutlined,
  SettingOutlined,
  SecurityScanOutlined,
  NotificationOutlined,
  GlobalOutlined,
  DollarOutlined,
  MailOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { 
  fetchSettings, 
  updateSettings,
  testEmailSettings,
  resetToDefaults 
} from '../../store/slices/settingsSlice';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;
const { Option } = Select;
const { TextArea } = Input;
const { TabPane } = Tabs;
const { Panel } = Collapse;

const Settings = () => {
  const dispatch = useDispatch();
  const { t, i18n } = useTranslation();
  const [form] = Form.useForm();
  const { settings, loading } = useSelector((state) => state.settings);
  const [activeTab, setActiveTab] = useState('general');
  const [emailTest, setEmailTest] = useState({ loading: false, success: false });

  useEffect(() => {
    dispatch(fetchSettings());
  }, [dispatch]);

  useEffect(() => {
    if (settings) {
      form.setFieldsValue(settings);
    }
  }, [settings, form]);

  const handleSave = async (section) => {
    try {
      const values = await form.validateFields();
      await dispatch(updateSettings({ section, data: values })).unwrap();
      message.success(t('settings.saveSuccess'));
    } catch (error) {
      message.error(error?.message || 'Failed to save settings');
    }
  };

  const handleTestEmail = async () => {
    setEmailTest({ loading: true, success: false });
    try {
      await dispatch(testEmailSettings()).unwrap();
      setEmailTest({ loading: false, success: true });
      message.success('Email test sent successfully!');
    } catch (error) {
      setEmailTest({ loading: false, success: false });
      message.error('Email test failed!');
    }
  };

  const handleReset = () => {
    Modal.confirm({
      title: 'Reset to Default Settings',
      content: 'Are you sure you want to reset all settings to default values? This action cannot be undone.',
      okText: 'Reset',
      cancelText: 'Cancel',
      okType: 'danger',
      onOk: () => {
        dispatch(resetToDefaults());
        message.success('Settings reset to defaults');
      },
    });
  };

  const currencyOptions = [
    { value: 'USD', label: 'US Dollar ($)' },
    { value: 'EUR', label: 'Euro (€)' },
    { value: 'VND', label: 'Vietnamese Dong (₫)' },
    { value: 'GBP', label: 'British Pound (£)' },
    { value: 'JPY', label: 'Japanese Yen (¥)' },
  ];

  const timezoneOptions = [
    { value: 'UTC', label: 'UTC' },
    { value: 'Asia/Ho_Chi_Minh', label: 'Vietnam (UTC+7)' },
    { value: 'America/New_York', label: 'New York (UTC-5)' },
    { value: 'Europe/London', label: 'London (UTC+0)' },
    { value: 'Asia/Tokyo', label: 'Tokyo (UTC+9)' },
  ];

  const languageOptions = [
    { value: 'en', label: 'English' },
    { value: 'vi', label: 'Tiếng Việt' },
  ];

  return (
    <div>
      {/* Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Title level={2}>
            <SettingOutlined /> {t('settings.title')}
          </Title>
        </Col>
        <Col>
          <Space>
            <Button onClick={handleReset} danger>
              {t('settings.resetToDefaults')}
            </Button>
            <Button 
              type="primary" 
              icon={<SaveOutlined />}
              onClick={() => handleSave(activeTab)}
              loading={loading}
            >
              {t('settings.saveChanges')}
            </Button>
          </Space>
        </Col>
      </Row>

      <Form form={form} layout="vertical">
        <Tabs activeKey={activeTab} onChange={setActiveTab}>
          {/* General Settings */}
          <TabPane 
            tab={
              <span>
                <SettingOutlined />
                {t('settings.general')}
              </span>
            } 
            key="general"
          >
            <Row gutter={[24, 0]}>
              <Col xs={24} lg={12}>
                <Card title={t('settings.applicationSettings')}>
                  <Form.Item
                    name={['general', 'siteName']}
                    label={t('settings.siteName')}
                    rules={[{ required: true, message: t('validation.required') }]}
                  >
                    <Input placeholder="Hotel Booking Admin" />
                  </Form.Item>

                  <Form.Item
                    name={['general', 'siteDescription']}
                    label={t("settings.siteDescription")}
                  >
                    <TextArea 
                      rows={3} 
                      placeholder="Hotel booking management system"
                    />
                  </Form.Item>

                  <Form.Item
                    name={['general', 'defaultLanguage']}
                    label="Default Language"
                  >
                    <Select placeholder="Select default language">
                      {languageOptions.map(option => (
                        <Option key={option.value} value={option.value}>
                          {option.label}
                        </Option>
                      ))}
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name={['general', 'timezone']}
                    label={t("settings.timezone")}
                  >
                    <Select placeholder="Select timezone">
                      {timezoneOptions.map(option => (
                        <Option key={option.value} value={option.value}>
                          {option.label}
                        </Option>
                      ))}
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name={['general', 'maintenanceMode']}
                    label={t("settings.maintenanceMode")}
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Card>
              </Col>

              <Col xs={24} lg={12}>
                <Card title={t('settings.regionalSettings')}>
                  <Form.Item
                    name={['general', 'defaultCurrency']}
                    label={t("settings.defaultCurrency")}
                  >
                    <Select placeholder="Select currency">
                      {currencyOptions.map(option => (
                        <Option key={option.value} value={option.value}>
                          {option.label}
                        </Option>
                      ))}
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name={['general', 'dateFormat']}
                    label={t("settings.dateFormat")}
                  >
                    <Select placeholder="Select date format">
                      <Option value="DD/MM/YYYY">DD/MM/YYYY</Option>
                      <Option value="MM/DD/YYYY">MM/DD/YYYY</Option>
                      <Option value="YYYY-MM-DD">YYYY-MM-DD</Option>
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name={['general', 'timeFormat']}
                    label={t("settings.timeFormat")}
                  >
                    <Select placeholder="Select time format">
                      <Option value="24">24 Hour</Option>
                      <Option value="12">12 Hour (AM/PM)</Option>
                    </Select>
                  </Form.Item>

                  <Form.Item
                    name={['general', 'weekStartDay']}
                    label="Week Start Day"
                  >
                    <Select placeholder="Select week start day">
                      <Option value={0}>Sunday</Option>
                      <Option value={1}>Monday</Option>
                    </Select>
                  </Form.Item>
                </Card>
              </Col>
            </Row>
          </TabPane>

          {/* Security Settings */}
          <TabPane 
            tab={
              <span>
                <SecurityScanOutlined />
                {t('settings.security')}
              </span>
            } 
            key="security"
          >
            <Row gutter={[24, 0]}>
              <Col xs={24} lg={12}>
                <Card title={t("settings.authenticationSettings")}>
                  <Form.Item
                    name={['security', 'jwtExpiresIn']}
                    label="JWT Token Expiry (hours)"
                  >
                    <InputNumber min={1} max={168} />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'maxLoginAttempts']}
                    label="Max Login Attempts"
                  >
                    <InputNumber min={3} max={10} />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'lockoutDuration']}
                    label="Account Lockout Duration (minutes)"
                  >
                    <InputNumber min={5} max={1440} />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'requireEmailVerification']}
                    label="Require Email Verification"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'twoFactorAuth']}
                    label="Enable Two-Factor Authentication"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Card>
              </Col>

              <Col xs={24} lg={12}>
                <Card title={t("settings.passwordPolicy")}>
                  <Form.Item
                    name={['security', 'minPasswordLength']}
                    label="Minimum Password Length"
                  >
                    <InputNumber min={6} max={20} />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'requireUppercase']}
                    label="Require Uppercase Letters"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'requireNumbers']}
                    label="Require Numbers"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'requireSpecialChars']}
                    label="Require Special Characters"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['security', 'passwordExpiry']}
                    label="Password Expiry (days)"
                  >
                    <InputNumber min={0} max={365} />
                  </Form.Item>
                </Card>
              </Col>
            </Row>
          </TabPane>

          {/* Email Settings */}
          <TabPane 
            tab={
              <span>
                <MailOutlined />
                {t('settings.email')}
              </span>
            } 
            key="email"
          >
            <Row gutter={[24, 0]}>
              <Col xs={24} lg={12}>
                <Card 
                  title={t("settings.smtpConfiguration")}
                  extra={
                    <Button 
                      size="small"
                      onClick={handleTestEmail}
                      loading={emailTest.loading}
                    >
                      Test Email
                    </Button>
                  }
                >
                  <Form.Item
                    name={['email', 'smtpHost']}
                    label="SMTP Host"
                    rules={[{ required: true, message: 'SMTP host is required' }]}
                  >
                    <Input placeholder="smtp.gmail.com" />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'smtpPort']}
                    label="SMTP Port"
                    rules={[{ required: true, message: 'SMTP port is required' }]}
                  >
                    <InputNumber min={1} max={65535} placeholder="587" />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'smtpSecure']}
                    label="Use TLS/SSL"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'smtpUser']}
                    label="SMTP Username"
                    rules={[{ required: true, message: 'SMTP username is required' }]}
                  >
                    <Input placeholder="your-email@gmail.com" />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'smtpPassword']}
                    label="SMTP Password"
                    rules={[{ required: true, message: 'SMTP password is required' }]}
                  >
                    <Input.Password placeholder="Your app password" />
                  </Form.Item>
                </Card>
              </Col>

              <Col xs={24} lg={12}>
                <Card title={t("settings.emailTemplates")}>
                  <Form.Item
                    name={['email', 'fromName']}
                    label="From Name"
                  >
                    <Input placeholder="Hotel Booking System" />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'fromEmail']}
                    label="From Email"
                    rules={[{ type: 'email', message: 'Invalid email format' }]}
                  >
                    <Input placeholder="noreply@yourdomain.com" />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'replyToEmail']}
                    label="Reply To Email"
                    rules={[{ type: 'email', message: 'Invalid email format' }]}
                  >
                    <Input placeholder="support@yourdomain.com" />
                  </Form.Item>

                  <Divider />

                  <Form.Item
                    name={['email', 'enableBookingConfirmation']}
                    label="Booking Confirmation Emails"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'enablePaymentNotification']}
                    label="Payment Notification Emails"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['email', 'enableReminderEmails']}
                    label="Reminder Emails"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Card>
              </Col>
            </Row>
          </TabPane>

          {/* Business Settings */}
          <TabPane 
            tab={
              <span>
                <DollarOutlined />
                {t('settings.payment')}
              </span>
            } 
            key="business"
          >
            <Row gutter={[24, 0]}>
              <Col xs={24} lg={12}>
                <Card title={t("settings.bookingSettings")}>
                  <Form.Item
                    name={['business', 'bookingCancellationWindow']}
                    label="Cancellation Window (hours)"
                  >
                    <InputNumber min={0} max={168} />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'autoConfirmBookings']}
                    label="Auto-Confirm Bookings"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'requireApprovalForNewHotels']}
                    label="Require Approval for New Hotels"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'maxAdvanceBookingDays']}
                    label="Max Advance Booking (days)"
                  >
                    <InputNumber min={1} max={365} />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'minBookingNotice']}
                    label="Minimum Booking Notice (hours)"
                  >
                    <InputNumber min={0} max={72} />
                  </Form.Item>
                </Card>
              </Col>

              <Col xs={24} lg={12}>
                <Card title={t("settings.commissionAndFees")}>
                  <Form.Item
                    name={['business', 'platformCommission']}
                    label="Platform Commission (%)"
                  >
                    <InputNumber min={0} max={50} step={0.1} />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'paymentProcessingFee']}
                    label="Payment Processing Fee (%)"
                  >
                    <InputNumber min={0} max={10} step={0.1} />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'taxRate']}
                    label="Default Tax Rate (%)"
                  >
                    <InputNumber min={0} max={30} step={0.1} />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'serviceFee']}
                    label="Service Fee (fixed amount)"
                  >
                    <InputNumber min={0} step={0.01} />
                  </Form.Item>

                  <Form.Item
                    name={['business', 'refundProcessingTime']}
                    label="Refund Processing Time (days)"
                  >
                    <InputNumber min={1} max={30} />
                  </Form.Item>
                </Card>
              </Col>
            </Row>
          </TabPane>

          {/* Notification Settings */}
          <TabPane 
            tab={
              <span>
                <NotificationOutlined />
                {t('settings.notifications')}
              </span>
            } 
            key="notifications"
          >
            <Row gutter={[24, 0]}>
              <Col xs={24}>
                <Card title={t("settings.adminNotifications")}>
                  <Collapse>
                    <Panel header="New Booking Notifications" key="newBooking">
                      <Form.Item
                        name={['notifications', 'newBookingEmail']}
                        label="Email Notification"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                      <Form.Item
                        name={['notifications', 'newBookingDashboard']}
                        label="Dashboard Notification"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                    </Panel>

                    <Panel header="Hotel Registration Notifications" key="hotelReg">
                      <Form.Item
                        name={['notifications', 'hotelRegistrationEmail']}
                        label="Email Notification"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                      <Form.Item
                        name={['notifications', 'hotelRegistrationDashboard']}
                        label="Dashboard Notification"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                    </Panel>

                    <Panel header="Payment Notifications" key="payment">
                      <Form.Item
                        name={['notifications', 'paymentFailureEmail']}
                        label="Payment Failure Email"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                      <Form.Item
                        name={['notifications', 'refundRequestEmail']}
                        label="Refund Request Email"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                    </Panel>

                    <Panel header="Review Notifications" key="review">
                      <Form.Item
                        name={['notifications', 'newReviewEmail']}
                        label="New Review Email"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                      <Form.Item
                        name={['notifications', 'negativeReviewEmail']}
                        label="Negative Review Alert"
                        valuePropName="checked"
                      >
                        <Switch />
                      </Form.Item>
                    </Panel>
                  </Collapse>
                </Card>
              </Col>
            </Row>
          </TabPane>
        </Tabs>
      </Form>
    </div>
  );
};

export default Settings;
