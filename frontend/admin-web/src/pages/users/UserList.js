import React, { useEffect, useState } from 'react';
import {
  Table,
  Card,
  Button,
  Tag,
  Space,
  Input,
  Select,
  Row,
  Col,
  Modal,
  message,
  Avatar,
  Typography,
  Tooltip,
  Popconfirm,
  Badge,
} from 'antd';
import {
  PlusOutlined,
  SearchOutlined,
  EyeOutlined,
  EditOutlined,
  DeleteOutlined,
  UserOutlined,
  LockOutlined,
  UnlockOutlined,
  MailOutlined,
  PhoneOutlined,
  CheckCircleOutlined,
  CalendarOutlined,
  StarOutlined,
  HomeOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { 
  fetchUsers, 
  updateUserStatus, 
  deleteUser, 
  setFilters 
} from '../../store/slices/userSlice';
import dayjs from 'dayjs';

const { Search } = Input;
const { Option } = Select;
const { Title, Text } = Typography;

const UserList = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { users, pagination, loading, filters } = useSelector((state) => state.users);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);

  useEffect(() => {
    dispatch(fetchUsers({ 
      page: pagination.page, 
      limit: pagination.limit,
      ...filters 
    }));
  }, [dispatch, pagination.page, pagination.limit, filters]);

  const handleTableChange = (paginationInfo) => {
    dispatch(fetchUsers({
      page: paginationInfo.current,
      limit: paginationInfo.pageSize,
      ...filters
    }));
  };

  const handleSearch = (value) => {
    dispatch(setFilters({ search: value }));
  };

  const handleFilterChange = (key, value) => {
    dispatch(setFilters({ [key]: value }));
  };

  const handleStatusToggle = async (user) => {
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

  const handleDelete = async (user) => {
    try {
      await dispatch(deleteUser(user._id)).unwrap();
      message.success(t('users.deleteSuccess'));
    } catch (error) {
      message.error(error);
    }
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

  const columns = [
    {
      title: t('users.user'),
      key: 'user',
      render: (_, record) => (
        <Card size="small" style={{ margin: 0 }}>
          <Row gutter={16} align="middle">
            <Col flex="none">
              <Avatar
                size={50}
                src={record.avatar?.url}
                icon={<UserOutlined />}
              />
            </Col>
            <Col flex="auto">
              <Space direction="vertical" size="small" style={{ width: '100%' }}>
                <div>
                  <Text strong style={{ fontSize: 16 }}>
                    {record.firstName} {record.lastName}
                  </Text>
                  <Tag 
                    color={getRoleColor(record.role)} 
                    style={{ marginLeft: 8 }}
                  >
                    {t(`users.roles.${record.role}`)}
                  </Tag>
                </div>
                
                <Space size="middle" wrap>
                  <Space size="small">
                    <MailOutlined style={{ color: '#1890ff' }} />
                    <Text style={{ fontSize: 12 }}>{record.email}</Text>
                    {record.isEmailVerified && (
                      <CheckCircleOutlined style={{ color: '#52c41a' }} />
                    )}
                  </Space>
                  
                  {record.phone && (
                    <Space size="small">
                      <PhoneOutlined style={{ color: '#1890ff' }} />
                      <Text style={{ fontSize: 12 }}>{record.phone}</Text>
                    </Space>
                  )}
                </Space>

                <Row justify="space-between" align="middle">
                  <Col>
                    <Space size="middle">
                      <Tag color={getStatusColor(record.isActive, record.isEmailVerified)}>
                        {getStatusText(record.isActive, record.isEmailVerified)}
                      </Tag>
                      
                      <Text style={{ fontSize: 11 }} type="secondary">
                        {t('users.joinedDate')}: {dayjs(record.createdAt).format('DD/MM/YYYY')}
                      </Text>
                      
                      {record.lastLogin && (
                        <Text style={{ fontSize: 11 }} type="secondary">
                          Last login: {dayjs(record.lastLogin).format('DD/MM/YY')}
                        </Text>
                      )}
                    </Space>
                  </Col>
                  
                  <Col>
                    <Space size="small">
                      <Tooltip title={t('users.viewDetails')}>
                        <Button
                          size="small"
                          icon={<EyeOutlined />}
                          onClick={() => navigate(`/users/${record._id}`)}
                        />
                      </Tooltip>
                      <Tooltip title={t('users.editUser')}>
                        <Button
                          size="small"
                          icon={<EditOutlined />}
                          onClick={() => navigate(`/users/${record._id}/edit`)}
                        />
                      </Tooltip>
                      <Tooltip title={record.isActive ? t('users.deactivate') : t('users.activate')}>
                        <Popconfirm
                          title={
                            record.isActive 
                              ? t('users.deactivateConfirm') 
                              : t('users.activateConfirm')
                          }
                          onConfirm={() => handleStatusToggle(record)}
                          okText={t('common.yes')}
                          cancelText={t('common.no')}
                        >
                          <Button
                            size="small"
                            icon={record.isActive ? <LockOutlined /> : <UnlockOutlined />}
                            style={{ 
                              color: record.isActive ? '#f5222d' : '#52c41a' 
                            }}
                          />
                        </Popconfirm>
                      </Tooltip>
                      <Tooltip title={t('users.deleteUser')}>
                        <Popconfirm
                          title={t('users.deleteConfirm')}
                          onConfirm={() => handleDelete(record)}
                          okText={t('common.yes')}
                          cancelText={t('common.no')}
                        >
                          <Button
                            size="small"
                            icon={<DeleteOutlined />}
                            danger
                          />
                        </Popconfirm>
                      </Tooltip>
                    </Space>
                  </Col>
                </Row>

                {/* Stats section */}
                {(record.role === 'hotel_owner' || record.role === 'customer') && (
                  <Space size="middle">
                    {record.role === 'hotel_owner' && (
                      <Text style={{ fontSize: 12 }}>
                        <HomeOutlined /> Hotels: <strong>{record.totalHotels || 0}</strong>
                      </Text>
                    )}
                    {record.role === 'customer' && (
                      <>
                        <Text style={{ fontSize: 12 }}>
                          <CalendarOutlined /> Bookings: <strong>{record.totalBookings || 0}</strong>
                        </Text>
                        <Text style={{ fontSize: 12 }}>
                          <StarOutlined /> Reviews: <strong>{record.totalReviews || 0}</strong>
                        </Text>
                      </>
                    )}
                  </Space>
                )}
              </Space>
            </Col>
          </Row>
        </Card>
      ),
    },
  ];

  const rowSelection = {
    selectedRowKeys,
    onChange: setSelectedRowKeys,
  };

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col>
          <Title level={2}>{t('users.title')}</Title>
        </Col>
        <Col>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/users/new')}
          >
            {t('users.addUser')}
          </Button>
        </Col>
      </Row>

      <Card>
        <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
          <Col xs={24} sm={12} md={8}>
            <Search
              placeholder={t('users.searchPlaceholder')}
              onSearch={handleSearch}
              style={{ width: '100%' }}
            />
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('users.role')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('role', value)}
            >
              <Option value="admin">{t('users.roles.admin')}</Option>
              <Option value="hotel_owner">{t('users.roles.hotel_owner')}</Option>
              <Option value="customer">{t('users.roles.customer')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('users.status')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('isActive', value)}
            >
              <Option value={true}>{t('users.active')}</Option>
              <Option value={false}>{t('users.inactive')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder="Email Status"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('isEmailVerified', value)}
            >
              <Option value={true}>Verified</Option>
              <Option value={false}>Unverified</Option>
            </Select>
          </Col>
        </Row>

        <Table
          rowSelection={rowSelection}
          columns={columns}
          dataSource={users}
          rowKey="_id"
          loading={loading}
          pagination={{
            current: pagination.page,
            pageSize: pagination.limit,
            total: pagination.total,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total, range) =>
              `${range[0]}-${range[1]} of ${total} items`,
          }}
          onChange={handleTableChange}
          showHeader={false}
          size="small"
        />
      </Card>
    </div>
  );
};

export default UserList;
