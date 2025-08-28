import React, { useEffect, useState } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Tag,
  Space,
  Button,
  Avatar,
  Descriptions,
  Table,
  Modal,
  message,
  Divider,
  Tooltip,
  Badge,
  Statistic,
  Form,
  Input,
} from 'antd';
import {
  EditOutlined,
  DeleteOutlined,
  LockOutlined,
  UnlockOutlined,
  MailOutlined,
  PhoneOutlined,
  UserOutlined,
  CalendarOutlined,
  HomeOutlined,
  StarOutlined,
  BookOutlined,
  KeyOutlined,
} from '@ant-design/icons';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { 
  fetchUserById, 
  updateUserStatus, 
  deleteUser,
  updateUserPassword
} from '../../store/slices/userSlice';
import { formatCurrency } from '../../utils/format';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

const UserDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { currentUser: user, loading } = useSelector((state) => state.users);
  const [passwordModalVisible, setPasswordModalVisible] = useState(false);
  const [passwordForm] = Form.useForm();

  useEffect(() => {
    if (id) {
      dispatch(fetchUserById(id));
    }
  }, [dispatch, id]);

  const handleStatusToggle = async () => {
    try {
      await dispatch(updateUserStatus({ 
        id: user._id, 
        isActive: !user.isActive 
      })).unwrap();
      message.success(
        user.isActive 
          ? t('users.deactivateSuccess') 
          : t('users.activateSuccess')
      );
    } catch (error) {
      message.error(error);
    }
  };

  const handlePasswordChange = async (values) => {
    try {
      await dispatch(updateUserPassword({ 
        id: user._id, 
        newPassword: values.newPassword 
      })).unwrap();
      message.success(t('users.passwordUpdateSuccess'));
      setPasswordModalVisible(false);
      passwordForm.resetFields();
    } catch (error) {
      message.error(error);
    }
  };

  const handleDelete = async () => {
    Modal.confirm({
      title: t('users.deleteConfirm'),
      content: t('users.deleteConfirmMessage'),
      okText: t('common.yes'),
      cancelText: t('common.no'),
      okType: 'danger',
      onOk: async () => {
        try {
          await dispatch(deleteUser(user._id)).unwrap();
          message.success(t('users.deleteSuccess'));
          navigate('/users');
        } catch (error) {
          message.error(error);
        }
      },
    });
  };

  const getRoleColor = (role) => {
    const colors = {
      admin: 'red',
      hotel_owner: 'blue',
      customer: 'green',
    };
    return colors[role] || 'default';
  };

  const getStatusColor = (isActive, isEmailVerified) => {
    if (!isActive) return 'default';
    if (!isEmailVerified) return 'warning';
    return 'success';
  };

  const getStatusText = (isActive, isEmailVerified) => {
    if (!isActive) return t('users.inactive');
    if (!isEmailVerified) return t('users.unverified');
    return t('users.active');
  };

  // Columns for hotels table (if user is hotel owner)
  const hotelColumns = [
    {
      title: t('hotels.hotelName'),
      dataIndex: 'name',
      key: 'name',
      render: (text, record) => (
        <Space>
          <Avatar
            size={40}
            src={record.images?.[0]?.url}
            icon={<HomeOutlined />}
          />
          <div>
            <div style={{ fontWeight: 'bold' }}>{text}</div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {record.address?.city}, {record.address?.country}
            </Text>
          </div>
        </Space>
      ),
    },
    {
      title: t('hotels.status'),
      key: 'status',
      render: (_, record) => (
        <Tag color={record.isApproved === true ? 'success' : record.isApproved === false ? 'error' : 'warning'}>
          {record.isApproved === true ? 'Approved' : record.isApproved === false ? 'Rejected' : 'Pending'}
        </Tag>
      ),
    },
    {
      title: t('hotels.totalRooms'),
      dataIndex: 'totalRooms',
      key: 'totalRooms',
    },
    {
      title: t('hotels.averageRating'),
      dataIndex: 'averageRating',
      key: 'averageRating',
      render: (rating) => rating?.toFixed(1) || '0.0',
    },
  ];

  // Columns for bookings table (if user is customer)
  const bookingColumns = [
    {
      title: t('bookings.hotel'),
      dataIndex: 'hotel',
      key: 'hotel',
      render: (hotel) => hotel?.name,
    },
    {
      title: t('bookings.checkIn'),
      dataIndex: 'checkInDate',
      key: 'checkIn',
      render: (date) => dayjs(date).format('DD/MM/YYYY'),
    },
    {
      title: t('bookings.checkOut'),
      dataIndex: 'checkOutDate',
      key: 'checkOut',
      render: (date) => dayjs(date).format('DD/MM/YYYY'),
    },
    {
      title: t('bookings.totalAmount'),
      dataIndex: 'totalAmount',
      key: 'totalAmount',
      render: (amount) => formatCurrency(amount),
    },
    {
      title: t('bookings.status'),
      dataIndex: 'status',
      key: 'status',
      render: (status) => (
        <Tag color={
          status === 'confirmed' ? 'success' :
          status === 'cancelled' ? 'error' :
          status === 'completed' ? 'blue' : 'warning'
        }>
          {status}
        </Tag>
      ),
    },
  ];

  // Columns for reviews table (if user is customer)
  const reviewColumns = [
    {
      title: t('reviews.hotel'),
      dataIndex: 'hotel',
      key: 'hotel',
      render: (hotel) => hotel?.name,
    },
    {
      title: t('reviews.rating'),
      dataIndex: 'rating',
      key: 'rating',
      render: (rating) => (
        <Space>
          <StarOutlined style={{ color: '#faad14' }} />
          {rating}
        </Space>
      ),
    },
    {
      title: t('reviews.comment'),
      dataIndex: 'comment',
      key: 'comment',
      render: (comment) => (
        <Paragraph
          ellipsis={{ rows: 2, expandable: true, symbol: 'more' }}
          style={{ marginBottom: 0 }}
        >
          {comment}
        </Paragraph>
      ),
    },
    {
      title: t('reviews.date'),
      dataIndex: 'createdAt',
      key: 'date',
      render: (date) => dayjs(date).format('DD/MM/YYYY'),
    },
  ];

  if (loading || !user) {
    return <Card loading />;
  }

  return (
    <div>
      {/* Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Space>
            <Button onClick={() => navigate('/users')}>
              ← {t('common.back')}
            </Button>
            <Title level={2} style={{ margin: 0 }}>
              {user.firstName} {user.lastName}
            </Title>
            <Tag color={getRoleColor(user.role)}>
              {t(`users.roles.${user.role}`)}
            </Tag>
            <Tag color={getStatusColor(user.isActive, user.isEmailVerified)}>
              {getStatusText(user.isActive, user.isEmailVerified)}
            </Tag>
          </Space>
        </Col>
        <Col>
          <Space>
            <Button
              icon={<EditOutlined />}
              onClick={() => navigate(`/users/${id}/edit`)}
            >
              {t('users.editUser')}
            </Button>
            <Button
              icon={<KeyOutlined />}
              onClick={() => setPasswordModalVisible(true)}
            >
              {t('users.changePassword')}
            </Button>
            <Button
              icon={user.isActive ? <LockOutlined /> : <UnlockOutlined />}
              onClick={handleStatusToggle}
              style={{ 
                color: user.isActive ? '#f5222d' : '#52c41a',
                borderColor: user.isActive ? '#f5222d' : '#52c41a'
              }}
            >
              {user.isActive ? t('users.deactivate') : t('users.activate')}
            </Button>
            <Button
              danger
              icon={<DeleteOutlined />}
              onClick={handleDelete}
            >
              {t('users.deleteUser')}
            </Button>
          </Space>
        </Col>
      </Row>

      <Row gutter={[24, 24]}>
        {/* User Profile */}
        <Col xs={24} lg={8}>
          <Card>
            <Space direction="vertical" style={{ width: '100%', textAlign: 'center' }}>
              <Avatar
                size={120}
                src={user.avatar}
                icon={<UserOutlined />}
              />
              <div>
                <Title level={3} style={{ marginBottom: 0 }}>
                  {user.firstName} {user.lastName}
                </Title>
                <Text type="secondary">{user.email}</Text>
              </div>
              
              <Divider />
              
              <Descriptions column={1} size="small">
                <Descriptions.Item label={t('users.role')}>
                  <Tag color={getRoleColor(user.role)}>
                    {t(`users.roles.${user.role}`)}
                  </Tag>
                </Descriptions.Item>
                
                <Descriptions.Item label={t('users.phone')}>
                  <Space>
                    <PhoneOutlined />
                    {user.phone || 'N/A'}
                  </Space>
                </Descriptions.Item>
                
                <Descriptions.Item label={t('users.emailStatus')}>
                  <Space>
                    <MailOutlined />
                    <Tag color={user.isEmailVerified ? 'success' : 'warning'}>
                      {user.isEmailVerified ? 'Verified' : 'Unverified'}
                    </Tag>
                  </Space>
                </Descriptions.Item>
                
                <Descriptions.Item label={t('users.joinedDate')}>
                  <Space>
                    <CalendarOutlined />
                    {dayjs(user.createdAt).format('DD/MM/YYYY')}
                  </Space>
                </Descriptions.Item>
                
                {user.lastLogin && (
                  <Descriptions.Item label={t('users.lastLogin')}>
                    {dayjs(user.lastLogin).format('DD/MM/YYYY HH:mm')}
                  </Descriptions.Item>
                )}
              </Descriptions>
            </Space>
          </Card>
        </Col>

        {/* Statistics & Details */}
        <Col xs={24} lg={16}>
          <Row gutter={[16, 16]}>
            {/* Statistics */}
            <Col xs={24}>
              <Card title={t('users.statistics')}>
                <Row gutter={16}>
                  {user.role === 'hotel_owner' && (
                    <>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.totalHotels')}
                          value={user.totalHotels || 0}
                          prefix={<HomeOutlined />}
                        />
                      </Col>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.approvedHotels')}
                          value={user.approvedHotels || 0}
                          prefix={<StarOutlined />}
                        />
                      </Col>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.totalRooms')}
                          value={user.totalRooms || 0}
                        />
                      </Col>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.revenue')}
                          value={user.totalRevenue || 0}
                          formatter={(value) => formatCurrency(value)}
                        />
                      </Col>
                    </>
                  )}
                  
                  {user.role === 'customer' && (
                    <>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.totalBookings')}
                          value={user.totalBookings || 0}
                          prefix={<BookOutlined />}
                        />
                      </Col>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.totalSpent')}
                          value={user.totalSpent || 0}
                          formatter={(value) => formatCurrency(value)}
                        />
                      </Col>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.totalReviews')}
                          value={user.totalReviews || 0}
                          prefix={<StarOutlined />}
                        />
                      </Col>
                      <Col xs={12} sm={6}>
                        <Statistic
                          title={t('users.averageRating')}
                          value={user.averageRating || 0}
                          precision={1}
                          suffix="/ 5"
                        />
                      </Col>
                    </>
                  )}
                </Row>
              </Card>
            </Col>

            {/* User Details */}
            <Col xs={24}>
              <Card title={t('users.details')}>
                <Descriptions bordered column={2}>
                  <Descriptions.Item label="User ID">
                    {user._id}
                  </Descriptions.Item>
                  <Descriptions.Item label={t('users.status')}>
                    <Badge
                      status={user.isActive ? 'success' : 'default'}
                      text={user.isActive ? t('users.active') : t('users.inactive')}
                    />
                  </Descriptions.Item>
                  
                  {user.dateOfBirth && (
                    <Descriptions.Item label={t('users.dateOfBirth')}>
                      {dayjs(user.dateOfBirth).format('DD/MM/YYYY')}
                    </Descriptions.Item>
                  )}
                  
                  {user.address && (
                    <Descriptions.Item label={t('users.address')} span={2}>
                      {[
                        user.address.street,
                        user.address.city,
                        user.address.state,
                        user.address.country
                      ].filter(Boolean).join(', ')}
                    </Descriptions.Item>
                  )}
                  
                  <Descriptions.Item label={t('users.createdAt')}>
                    {dayjs(user.createdAt).format('DD/MM/YYYY HH:mm')}
                  </Descriptions.Item>
                  <Descriptions.Item label={t('users.updatedAt')}>
                    {dayjs(user.updatedAt).format('DD/MM/YYYY HH:mm')}
                  </Descriptions.Item>
                </Descriptions>
              </Card>
            </Col>
          </Row>
        </Col>

        {/* Related Data Tables */}
        {user.role === 'hotel_owner' && user.hotels && user.hotels.length > 0 && (
          <Col xs={24}>
            <Card title={`${t('users.hotels')} (${user.hotels.length})`}>
              <Table
                columns={hotelColumns}
                dataSource={user.hotels}
                rowKey="_id"
                pagination={{ pageSize: 5 }}
                size="middle"
              />
            </Card>
          </Col>
        )}

        {user.role === 'customer' && user.bookings && user.bookings.length > 0 && (
          <Col xs={24}>
            <Card title={`${t('users.bookings')} (${user.bookings.length})`}>
              <Table
                columns={bookingColumns}
                dataSource={user.bookings}
                rowKey="_id"
                pagination={{ pageSize: 5 }}
                size="middle"
              />
            </Card>
          </Col>
        )}

        {user.role === 'customer' && user.reviews && user.reviews.length > 0 && (
          <Col xs={24}>
            <Card title={`${t('users.reviews')} (${user.reviews.length})`}>
              <Table
                columns={reviewColumns}
                dataSource={user.reviews}
                rowKey="_id"
                pagination={{ pageSize: 5 }}
                size="middle"
              />
            </Card>
          </Col>
        )}
      </Row>

      {/* Change Password Modal */}
      <Modal
        title={t('users.changePassword')}
        open={passwordModalVisible}
        onCancel={() => {
          setPasswordModalVisible(false);
          passwordForm.resetFields();
        }}
        footer={null}
      >
        <Form
          form={passwordForm}
          layout="vertical"
          onFinish={handlePasswordChange}
        >
          <Form.Item
            name="newPassword"
            label={t('users.newPassword')}
            rules={[
              { required: true, message: t('validation.required') },
              { min: 6, message: t('validation.minLength', { min: 6 }) },
            ]}
          >
            <Input.Password placeholder="Enter new password" />
          </Form.Item>
          
          <Form.Item
            name="confirmPassword"
            label={t('users.confirmPassword')}
            dependencies={['newPassword']}
            rules={[
              { required: true, message: t('validation.required') },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('newPassword') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error(t('validation.passwordMismatch')));
                },
              }),
            ]}
          >
            <Input.Password placeholder="Confirm new password" />
          </Form.Item>
          
          <Form.Item style={{ marginBottom: 0 }}>
            <Space>
              <Button type="primary" htmlType="submit">
                {t('users.updatePassword')}
              </Button>
              <Button onClick={() => {
                setPasswordModalVisible(false);
                passwordForm.resetFields();
              }}>
                {t('common.cancel')}
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default UserDetail;
