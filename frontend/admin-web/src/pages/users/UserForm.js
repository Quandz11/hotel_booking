import React, { useEffect, useState } from 'react';
import {
  Form,
  Card,
  Row,
  Col,
  Input,
  Select,
  DatePicker,
  Button,
  Upload,
  Switch,
  Space,
  Typography,
  message,
  Avatar,
} from 'antd';
import {
  UploadOutlined,
  UserOutlined,
  SaveOutlined,
} from '@ant-design/icons';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { createUser, updateUser, fetchUserById, clearCurrentUser } from '../../store/slices/userSlice';
import dayjs from 'dayjs';
import { showFormErrors } from '../../utils/apiError';

const { Option } = Select;
const { TextArea } = Input;
const { Title } = Typography;

const UserForm = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const [form] = Form.useForm();
  const isEdit = !!id;

  const { currentUser: user, loading } = useSelector((state) => state.users);
  const [avatarFile, setAvatarFile] = useState(null);
  const [avatarUrl, setAvatarUrl] = useState('');

  useEffect(() => {
    if (isEdit && id) {
      console.log('🔍 Fetching user with ID:', id);
      // Clear previous user data first
      dispatch(clearCurrentUser());
      dispatch(fetchUserById(id));
    } else if (!isEdit) {
      // Clear user data when creating new user
      dispatch(clearCurrentUser());
    }

    // Cleanup when component unmounts
    return () => {
      dispatch(clearCurrentUser());
    };
  }, [dispatch, isEdit, id]);

  useEffect(() => {
    console.log('👤 User data changed:', user);
    console.log('✏️ Is edit mode:', isEdit);
    console.log('🆔 Current ID:', id);
    
    if (isEdit && user && user._id === id) {
      console.log('📝 Setting form values for user:', user);
      
      const formValues = {
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isActive: user.isActive,
        isEmailVerified: user.isEmailVerified,
        'address.street': user.address?.street,
        'address.city': user.address?.city,
        'address.state': user.address?.state,
        'address.zipCode': user.address?.zipCode,
        'address.country': user.address?.country,
      };
      
      console.log('📋 Form values to set:', formValues);
      form.setFieldsValue(formValues);

      if (user.avatar?.url) {
        setAvatarUrl(user.avatar.url);
      }
    }
  }, [isEdit, user, form, id]);

  const handleSubmit = async (values) => {
    try {
      // Build address object properly
      const address = {
        street: values['address.street'],
        city: values['address.city'],
        state: values['address.state'],
        zipCode: values['address.zipCode'],
        country: values['address.country'],
      };

      // Remove nested field names and build clean data
      const cleanedData = { ...values };
      Object.keys(cleanedData).forEach(key => {
        if (key.includes('.')) {
          delete cleanedData[key];
        }
      });

      // Add properly formatted data
      const formData = {
        ...cleanedData,
        address: address,
      };

      // Add avatar if uploaded
      if (avatarFile) {
        formData.avatar = {
          url: avatarUrl,
          public_id: avatarFile.response?.public_id,
        };
      }

      if (isEdit) {
        await dispatch(updateUser({ id, data: formData })).unwrap();
        message.success(t('users.updateSuccess'));
      } else {
        await dispatch(createUser(formData)).unwrap();
        message.success(t('users.createSuccess'));
      }

      navigate('/users');
    } catch (error) {
      showFormErrors(form, error, t('errors.validationError'));
    }
  };

  const handleAvatarUpload = {
    name: 'file',
    action: '/api/upload/image',
    showUploadList: false,
    beforeUpload: (file) => {
      const isJpgOrPng = file.type === 'image/jpeg' || file.type === 'image/png';
      if (!isJpgOrPng) {
        message.error('You can only upload JPG/PNG file!');
        return false;
      }
      const isLt2M = file.size / 1024 / 1024 < 2;
      if (!isLt2M) {
        message.error('Image must smaller than 2MB!');
        return false;
      }
      return true;
    },
    onChange: (info) => {
      if (info.file.status === 'uploading') {
        return;
      }
      if (info.file.status === 'done') {
        setAvatarFile(info.file);
        setAvatarUrl(info.file.response.url);
        message.success('Avatar uploaded successfully');
      }
      if (info.file.status === 'error') {
        message.error('Avatar upload failed');
      }
    },
  };

  const countryOptions = [
    'Vietnam',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'South Korea',
    'Singapore',
    'Thailand',
    'Malaysia',
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Title level={2}>
            {isEdit ? t('users.editUser') : t('users.addUser')}
          </Title>
        </Col>
        <Col>
          <Button onClick={() => navigate('/users')}>
            ← {t('common.back')}
          </Button>
        </Col>
      </Row>

      {/* Show loading when fetching user data in edit mode */}
      {isEdit && loading && (
        <Card loading>
          <div style={{ height: '400px' }}></div>
        </Card>
      )}

      {/* Show form when not loading or in create mode */}
      {(!isEdit || !loading) && (
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          initialValues={{
            role: 'customer',
          isActive: true,
          isEmailVerified: false,
        }}
      >
        <Row gutter={[24, 0]}>
          {/* Basic Information */}
          <Col xs={24} lg={12}>
            <Card title={t('users.basicInfo')} style={{ height: '100%' }}>
              {/* Avatar Upload */}
              <Row justify="center" style={{ marginBottom: 24 }}>
                <Col>
                  <Space direction="vertical" align="center">
                    <Avatar
                      size={80}
                      src={avatarUrl}
                      icon={<UserOutlined />}
                    />
                    <Upload {...handleAvatarUpload}>
                      <Button icon={<UploadOutlined />}>
                        {t('users.uploadAvatar')}
                      </Button>
                    </Upload>
                  </Space>
                </Col>
              </Row>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name="firstName"
                    label={t('users.firstName')}
                    rules={[
                      { required: true, message: t('validation.required') },
                      { min: 2, message: t('validation.minLength', { min: 2 }) },
                    ]}
                  >
                    <Input placeholder="Enter first name" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="lastName"
                    label={t('users.lastName')}
                    rules={[
                      { required: true, message: t('validation.required') },
                      { min: 2, message: t('validation.minLength', { min: 2 }) },
                    ]}
                  >
                    <Input placeholder="Enter last name" />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item
                name="email"
                label={t('users.email')}
                rules={[
                  { required: true, message: t('validation.required') },
                  { type: 'email', message: t('validation.invalidEmail') },
                ]}
              >
                <Input placeholder="Enter email address" disabled={isEdit} />
              </Form.Item>

              {!isEdit && (
                <Form.Item
                  name="password"
                  label={t('users.password')}
                  rules={[
                    { required: true, message: t('validation.required') },
                    { min: 6, message: t('validation.minLength', { min: 6 }) },
                  ]}
                >
                  <Input.Password placeholder="Enter password" />
                </Form.Item>
              )}

              <Form.Item
                name="phone"
                label={t('users.phone')}
                rules={[
                    { required: true, message: t('validation.required') },
                  ]}
              >
                <Input placeholder="Enter phone number" />
              </Form.Item>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name="dateOfBirth"
                    label={t('users.dateOfBirth')}
                    rules={[
                    { required: true, message: t('validation.required') },
                  ]}
                  >
                    <DatePicker 
                      style={{ width: '100%' }}
                      placeholder="Select date of birth"
                      format="DD/MM/YYYY"
                    />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="gender"
                    label="Gender"
                    rules={[
                    { required: true, message: t('validation.required') },
                  ]}
                  >
                    <Select placeholder="Select gender">
                      <Option value="male">Male</Option>
                      <Option value="female">Female</Option>
                      <Option value="other">Other</Option>
                    </Select>
                  </Form.Item>
                </Col>
              </Row>
            </Card>
          </Col>

          {/* Role & Status */}
          <Col xs={24} lg={12}>
            <Card title={t('users.roleStatus')} style={{ height: '100%' }}>
              <Form.Item
                name="role"
                label={t('users.role')}
                rules={[{ required: true, message: t('validation.required') }]}
              >
                <Select placeholder="Select user role">
                  <Option value="admin">{t('users.roles.admin')}</Option>
                  <Option value="hotel_owner">{t('users.roles.hotel_owner')}</Option>
                  <Option value="customer">{t('users.roles.customer')}</Option>
                </Select>
              </Form.Item>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name="isActive"
                    label={t('users.activeStatus')}
                    valuePropName="checked"
                  >
                    <Switch 
                      checkedChildren="Active"
                      unCheckedChildren="Inactive"
                    />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="isEmailVerified"
                    label="Email Verified"
                    valuePropName="checked"
                  >
                    <Switch 
                      checkedChildren="Verified"
                      unCheckedChildren="Unverified"
                    />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item
                name="bio"
                label={t('users.bio')}
              >
                <TextArea
                  rows={4}
                  placeholder="Enter user bio (optional)"
                  maxLength={500}
                  showCount
                />
              </Form.Item>
            </Card>
          </Col>

          {/* Address Information */}
          <Col xs={24}>
            <Card title={t('users.addressInfo')}>
              <Row gutter={16}>
                <Col xs={24} md={12}>
                  <Form.Item
                    name="address.street"
                    label={t('users.street')}
                  >
                    <Input placeholder="Enter street address" />
                  </Form.Item>
                </Col>
                <Col xs={24} md={12}>
                  <Form.Item
                    name="address.city"
                    label={t('users.city')}
                  >
                    <Input placeholder="Enter city" />
                  </Form.Item>
                </Col>
              </Row>

              <Row gutter={16}>
                <Col xs={24} md={8}>
                  <Form.Item
                    name="address.state"
                    label={t('users.state')}
                  >
                    <Input placeholder="Enter state/province" />
                  </Form.Item>
                </Col>
                <Col xs={24} md={8}>
                  <Form.Item
                    name="address.zipCode"
                    label={t('users.zipCode')}
                  >
                    <Input placeholder="Enter zip code" />
                  </Form.Item>
                </Col>
                <Col xs={24} md={8}>
                  <Form.Item
                    name="address.country"
                    label={t('users.country')}
                  >
                    <Select placeholder="Select country">
                      {countryOptions.map(country => (
                        <Option key={country} value={country}>
                          {country}
                        </Option>
                      ))}
                    </Select>
                  </Form.Item>
                </Col>
              </Row>
            </Card>
          </Col>

          {/* Submit Button */}
          <Col xs={24}>
            <Card>
              <Row justify="end">
                <Space>
                  <Button onClick={() => navigate('/users')}>
                    {t('common.cancel')}
                  </Button>
                  <Button
                    type="primary"
                    htmlType="submit"
                    loading={loading}
                    icon={<SaveOutlined />}
                  >
                    {isEdit ? t('users.updateUser') : t('users.createUser')}
                  </Button>
                </Space>
              </Row>
            </Card>
          </Col>
        </Row>
        </Form>
      )}
    </div>
  );
};

export default UserForm;
