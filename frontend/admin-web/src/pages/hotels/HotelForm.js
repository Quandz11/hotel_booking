import React, { useEffect, useState } from 'react';
import {
  Form,
  Card,
  Row,
  Col,
  Input,
  Select,
  InputNumber,
  Button,
  Upload,
  Rate,
  Switch,
  Space,
  Typography,
  message,
  Divider,
  Tag,
} from 'antd';
import {
  PlusOutlined,
  UploadOutlined,
  MinusCircleOutlined,
  SaveOutlined,
} from '@ant-design/icons';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { createHotel, updateHotel, fetchHotelById } from '../../store/slices/hotelSlice';
import { fetchUsers } from '../../store/slices/userSlice';
import { showFormErrors } from '../../utils/apiError';

const { Option } = Select;
const { TextArea } = Input;
const { Title } = Typography;

const HotelForm = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const [form] = Form.useForm();
  const isEdit = !!id;

  const { currentHotel: hotel, loading } = useSelector((state) => state.hotels);
  const { users } = useSelector((state) => state.users);
  const [fileList, setFileList] = useState([]);
  const [amenities, setAmenities] = useState([]);

  useEffect(() => {
    // Fetch users for owner selection
    dispatch(fetchUsers({ role: 'hotel_owner' }));

    if (isEdit && id) {
      dispatch(fetchHotelById(id));
    }
  }, [dispatch, isEdit, id]);

  useEffect(() => {
    if (isEdit && hotel) {
      // Populate form with hotel data
      form.setFieldsValue({
        name: hotel.name,
        description: hotel.description,
        starRating: hotel.starRating,
        owner: hotel.owner?._id,
        isActive: hotel.isActive,
        isApproved: hotel.isApproved,
        'address.street': hotel.address?.street,
        'address.city': hotel.address?.city,
        'address.state': hotel.address?.state,
        'address.zipCode': hotel.address?.zipCode,
        'address.country': hotel.address?.country,
        phone: hotel.phone,
        email: hotel.email,
        website: hotel.website,
      });

      if (hotel.amenities) {
        setAmenities(hotel.amenities);
        form.setFieldsValue({ amenities: hotel.amenities });
      }

      if (hotel.images) {
        setFileList(hotel.images.map((img, index) => ({
          uid: index,
          name: `image-${index}`,
          status: 'done',
          url: img.url,
        })));
      }
    }
  }, [isEdit, hotel, form]);

  const handleSubmit = async (values) => {
    try {
      const formData = {
        ...values,
        address: {
          street: values['address.street'],
          city: values['address.city'],
          state: values['address.state'],
          zipCode: values['address.zipCode'],
          country: values['address.country'],
        },
        amenities,
        images: fileList.map(file => ({
          url: file.url || file.response?.image?.url,
          publicId: file.response?.image?.publicId,
        })).filter(img => !!img.url),
      };

      // Remove nested field names
      const cleanedData = { ...formData };
      Object.keys(cleanedData).forEach(key => {
        if (key.includes('.')) {
          delete cleanedData[key];
        }
      });

      // If approval status is pending (null) omit the field to satisfy validation
      if (cleanedData.isApproved === null) {
        delete cleanedData.isApproved;
      }

      if (isEdit) {
        await dispatch(updateHotel({ id, data: cleanedData })).unwrap();
        message.success(t('hotels.updateSuccess'));
      } else {
        await dispatch(createHotel(cleanedData)).unwrap();
        message.success(t('hotels.createSuccess'));
      }

      navigate('/hotels');
    } catch (error) {
        showFormErrors(form, error, t('errors.validationError'));
      }
    };

  const handleImageUpload = {
    name: 'image',
    action: '/api/upload/image',
    listType: 'picture-card',
    fileList,
    multiple: true,
    accept: 'image/*',
    maxCount: 8,
    headers: {
      Authorization: `Bearer ${localStorage.getItem('token') || ''}`,
    },
    onChange: ({ file, fileList: newFileList }) => {
      // normalize newly uploaded files to include URL for preview
      const normalized = newFileList.map((f) => {
        const next = { ...f };
        if (!next.url && next.response?.image?.url) {
          next.url = next.response.image.url;
        }
        return next;
      });
      setFileList(normalized);
    },
    onPreview: async (file) => {
      let src = file.url;
      if (!src) {
        src = await new Promise((resolve) => {
          const reader = new FileReader();
          reader.readAsDataURL(file.originFileObj);
          reader.onload = () => resolve(reader.result);
        });
      }
      const image = new Image();
      image.src = src;
      const imgWindow = window.open(src);
      imgWindow?.document.write(image.outerHTML);
    },
  };

  const uploadButton = (
    <div>
      <PlusOutlined />
      <div style={{ marginTop: 8 }}>Upload</div>
    </div>
  );

  const HOTEL_AMENITY_OPTIONS = [
    'wifi',
    'parking',
    'pool',
    'gym',
    'spa',
    'restaurant',
    'bar',
    'room_service',
    'concierge',
    'laundry',
    'business_center',
    'conference_room',
    'airport_shuttle',
    'pet_friendly',
    'air_conditioning',
    'elevator',
  ];

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
            {isEdit ? t('hotels.editHotel') : t('hotels.addHotel')}
          </Title>
        </Col>
        <Col>
          <Button onClick={() => navigate('/hotels')}>
            ← {t('common.back')}
          </Button>
        </Col>
      </Row>

      <Form
        form={form}
        layout="vertical"
        onFinish={handleSubmit}
        initialValues={{
          starRating: 3,
          isActive: true,
          isApproved: null,
        }}
      >
        <Row gutter={[24, 0]}>
          {/* Basic Information */}
          <Col xs={24} lg={12}>
            <Card title={t('hotels.basicInfo')} style={{ height: '100%' }}>
              <Form.Item
                name="name"
                label={t('hotels.hotelName')}
                rules={[
                  { required: true, message: t('validation.required') },
                  { min: 3, message: t('validation.minLength', { min: 3 }) },
                ]}
              >
                <Input placeholder="Enter hotel name" />
              </Form.Item>

              <Form.Item
                name="description"
                label={t('hotels.description')}
                rules={[
                  { required: true, message: t('validation.required') },
                  { min: 10, message: t('validation.minLength', { min: 10 }) },
                ]}
              >
                <TextArea
                  rows={4}
                  placeholder="Enter hotel description"
                />
              </Form.Item>

              <Form.Item
                name="starRating"
                label={t('hotels.starRating')}
                rules={[{ required: true, message: t('validation.required') }]}
              >
                <Rate />
              </Form.Item>

              <Form.Item
                name="owner"
                label={t('hotels.owner')}
                rules={[{ required: true, message: t('validation.required') }]}
              >
                <Select
                  placeholder="Select hotel owner"
                  showSearch
                  filterOption={(input, option) =>
                    option.children.toLowerCase().includes(input.toLowerCase())
                  }
                >
                  {users.map(user => (
                    <Option key={user._id} value={user._id}>
                      {user.firstName} {user.lastName} ({user.email})
                    </Option>
                  ))}
                </Select>
              </Form.Item>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name="isActive"
                    label="Active Status"
                    valuePropName="checked"
                  >
                    <Switch />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="isApproved"
                    label="Approval Status"
                  >
                    <Select placeholder="Select status">
                      <Option value={null}>Pending</Option>
                      <Option value={true}>Approved</Option>
                      <Option value={false}>Rejected</Option>
                    </Select>
                  </Form.Item>
                </Col>
              </Row>
            </Card>
          </Col>

          {/* Address Information */}
          <Col xs={24} lg={12}>
            <Card title={t('hotels.addressInfo')} style={{ height: '100%' }}>
              <Form.Item
                name="address.street"
                label={t('hotels.street')}
                rules={[{ required: true, message: t('validation.required') }]}
              >
                <Input placeholder="Enter street address" />
              </Form.Item>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name="address.city"
                    label={t('hotels.city')}
                    rules={[{ required: true, message: t('validation.required') }]}
                  >
                    <Input placeholder="Enter city" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="address.state"
                    label={t('hotels.state')}
                  >
                    <Input placeholder="Enter state/province" />
                  </Form.Item>
                </Col>
              </Row>

              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    name="address.zipCode"
                    label={t('hotels.zipCode')}
                  >
                    <Input placeholder="Enter zip code" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    name="address.country"
                    label={t('hotels.country')}
                    rules={[{ required: true, message: t('validation.required') }]}
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

          {/* Contact Information */}
          <Col xs={24} lg={12}>
            <Card title={t('hotels.contactInfo')}>
              <Form.Item
                name="phone"
                label={t('hotels.phone')}
                rules={[
                  { required: true, message: t('validation.required') },
                  { pattern: /^[+]?[\d\s\-()]+$/, message: t('validation.invalidPhone') },
                ]}
              >
                <Input placeholder="Enter phone number" />
              </Form.Item>

              <Form.Item
                name="email"
                label={t('hotels.email')}
                rules={[
                  { required: true, message: t('validation.required') },
                  { type: 'email', message: t('validation.invalidEmail') },
                ]}
              >
                <Input placeholder="Enter email address" />
              </Form.Item>

              <Form.Item
                name="website"
                label={t('hotels.website')}
                rules={[
                  { type: 'url', message: t('validation.invalidUrl') },
                ]}
              >
                <Input placeholder="Enter website URL" />
              </Form.Item>
            </Card>
          </Col>

          {/* Amenities */}
          <Col xs={24} lg={12}>
            <Card title={t('hotels.amenities')}>
              <Form.Item name="amenities" rules={[]}> 
                <Select
                  mode="multiple"
                  placeholder="Select amenities"
                  value={amenities}
                  onChange={(vals) => setAmenities(vals)}
                  optionFilterProp="children"
                >
                  {HOTEL_AMENITY_OPTIONS.map((opt) => (
                    <Option key={opt} value={opt}>
                      {opt}
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Card>
          </Col>

          {/* Images */}
          <Col xs={24}>
            <Card title={t('hotels.images')}>
              <Upload {...handleImageUpload}>
                {fileList.length >= 8 ? null : uploadButton}
              </Upload>
            </Card>
          </Col>

          {/* Submit Button */}
          <Col xs={24}>
            <Card>
              <Row justify="end">
                <Space>
                  <Button onClick={() => navigate('/hotels')}>
                    {t('common.cancel')}
                  </Button>
                  <Button
                    type="primary"
                    htmlType="submit"
                    loading={loading}
                    icon={<SaveOutlined />}
                  >
                    {isEdit ? t('hotels.updateHotel') : t('hotels.createHotel')}
                  </Button>
                </Space>
              </Row>
            </Card>
          </Col>
        </Row>
      </Form>
    </div>
  );
};

export default HotelForm;
