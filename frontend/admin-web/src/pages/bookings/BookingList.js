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
  Typography,
  Tooltip,
  Popconfirm,
  DatePicker,
  Statistic,
} from 'antd';
import {
  SearchOutlined,
  EyeOutlined,
  CheckOutlined,
  CloseOutlined,
  CalendarOutlined,
  UserOutlined,
  HomeOutlined,
  DollarOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { 
  fetchBookings, 
  updateBookingStatus, 
  setFilters 
} from '../../store/slices/bookingSlice';
import { formatCurrency } from '../../utils/format';
import dayjs from 'dayjs';

const { Search } = Input;
const { Option } = Select;
const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

const BookingList = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { bookings, pagination, loading, filters, statistics } = useSelector((state) => state.bookings);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);

  useEffect(() => {
    dispatch(fetchBookings({ 
      page: pagination.page, 
      limit: pagination.limit,
      ...filters 
    }));
  }, [dispatch, pagination.page, pagination.limit, filters]);

  const handleTableChange = (paginationInfo) => {
    dispatch(fetchBookings({
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

  const handleDateRangeChange = (dates) => {
    if (dates && dates.length === 2) {
      dispatch(setFilters({
        startDate: dates[0].toISOString(),
        endDate: dates[1].toISOString(),
      }));
    } else {
      dispatch(setFilters({
        startDate: null,
        endDate: null,
      }));
    }
  };

  const handleStatusUpdate = async (booking, newStatus) => {
    try {
      await dispatch(updateBookingStatus({ 
        id: booking._id, 
        status: newStatus 
      })).unwrap();
      message.success(`Booking ${newStatus} successfully`);
    } catch (error) {
      message.error(error);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: 'warning',
      confirmed: 'success',
      cancelled: 'error',
      checked_in: 'processing',
      checked_out: 'default',
      no_show: 'default',
    };
    return colors[status] || 'default';
  };

  const getPaymentStatusColor = (status) => {
    const colors = {
      pending: 'warning',
      paid: 'success',
      failed: 'error',
      refunded: 'default',
    };
    return colors[status] || 'default';
  };

  const columns = [
    {
      title: t('bookings.bookingId'),
      dataIndex: 'bookingNumber',
      key: 'bookingNumber',
      render: (bookingNumber, record) => <Text code>{bookingNumber || record?._id}</Text>,
      width: 120,
    },
    {
      title: t('bookings.guest'),
      dataIndex: 'customer',
      key: 'customer',
      render: (customer, record) => (
        <Space>
          <UserOutlined />
          <div>
            <div style={{ fontWeight: 'bold' }}>
              {(customer?.firstName || record?.guestInfo?.firstName || '')} {(customer?.lastName || record?.guestInfo?.lastName || '')}
            </div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {customer?.email || record?.guestInfo?.email}
            </Text>
          </div>
        </Space>
      ),
      width: 200,
    },
    {
      title: t('bookings.hotel'),
      dataIndex: 'hotel',
      key: 'hotel',
      render: (hotel) => (
        <Space>
          <HomeOutlined />
          <div>
            <div style={{ fontWeight: 'bold' }}>{hotel?.name}</div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {hotel?.address?.city}, {hotel?.address?.country}
            </Text>
          </div>
        </Space>
      ),
      width: 200,
    },
    {
      title: t('bookings.room'),
      dataIndex: 'room',
      key: 'room',
      render: (room) => (
        <div>
          <div>{room?.type}</div>
          <Text type="secondary" style={{ fontSize: 12 }}>
            Room {room?.roomNumber}
          </Text>
        </div>
      ),
      width: 120,
    },
    {
      title: t('bookings.dates'),
      key: 'dates',
      render: (_, record) => (
        <div>
          <div style={{ fontSize: 12 }}>
            <CalendarOutlined /> Check-in: {dayjs(record.checkIn).format('DD/MM/YY')}
          </div>
          <div style={{ fontSize: 12 }}>
            <CalendarOutlined /> Check-out: {dayjs(record.checkOut).format('DD/MM/YY')}
          </div>
          <Text type="secondary" style={{ fontSize: 11 }}>
            {dayjs(record.checkOut).diff(dayjs(record.checkIn), 'day')} nights
          </Text>
        </div>
      ),
      width: 150,
    },
    {
      title: t('bookings.guests'),
      key: 'guests',
      render: (_, record) => (
        <div>
          <div>Adults: {record.guests?.adults || 0}</div>
          {record.guests?.children > 0 && (
            <div>Children: {record.guests.children}</div>
          )}
        </div>
      ),
      width: 80,
    },
    {
      title: t('bookings.amount'),
      key: 'amount',
      render: (_, record) => (
        <div>
          <div style={{ fontWeight: 'bold' }}>
            {formatCurrency(record.totalAmount)}
          </div>
          <Tag color={getPaymentStatusColor(record.paymentStatus)}>
            {record.paymentStatus}
          </Tag>
        </div>
      ),
      width: 120,
    },
    {
      title: t('bookings.status.label'),
      dataIndex: 'status',
      key: 'status',
      render: (status) => (
        <Tag color={getStatusColor(status)}>
          {t(`bookings.status.${status}`)}
        </Tag>
      ),
      width: 100,
    },
    {
      title: t('bookings.createdAt'),
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (date) => dayjs(date).format('DD/MM/YY HH:mm'),
      width: 120,
    },
    {
      title: t('common.actions'),
      key: 'actions',
      render: (_, record) => (
        <Space size="small">
          <Tooltip title={t('bookings.viewDetails')}>
            <Button
              type="text"
              icon={<EyeOutlined />}
              onClick={() => navigate(`/bookings/${record._id}`)}
            />
          </Tooltip>
          
          {record.status === 'pending' && (
            <>
              <Tooltip title={t('bookings.confirm')}>
                <Popconfirm
                  title={t('bookings.confirmBooking')}
                  onConfirm={() => handleStatusUpdate(record, 'confirmed')}
                  okText={t('common.yes')}
                  cancelText={t('common.no')}
                >
                  <Button
                    type="text"
                    icon={<CheckOutlined />}
                    style={{ color: '#52c41a' }}
                  />
                </Popconfirm>
              </Tooltip>
              <Tooltip title={t('bookings.cancel')}>
                <Popconfirm
                  title={t('bookings.cancelBooking')}
                  onConfirm={() => handleStatusUpdate(record, 'cancelled')}
                  okText={t('common.yes')}
                  cancelText={t('common.no')}
                >
                  <Button
                    type="text"
                    icon={<CloseOutlined />}
                    style={{ color: '#f5222d' }}
                  />
                </Popconfirm>
              </Tooltip>
            </>
          )}

          {record.status === 'confirmed' && dayjs().isAfter(dayjs(record.checkOut)) && (
            <Tooltip title={t('bookings.markCompleted')}>
              <Popconfirm
                title={t('bookings.markCompletedConfirm')}
                onConfirm={() => handleStatusUpdate(record, 'checked_out')}
                okText={t('common.yes')}
                cancelText={t('common.no')}
              >
                <Button
                  type="text"
                  icon={<CheckOutlined />}
                  style={{ color: '#1890ff' }}
                />
              </Popconfirm>
            </Tooltip>
          )}
        </Space>
      ),
      width: 120,
      fixed: 'right',
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
          <Title level={2}>{t('bookings.title')}</Title>
        </Col>
      </Row>

      {/* Statistics */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('dashboard.totalBookings')}
              value={statistics?.total || 0}
              prefix={<CalendarOutlined />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('bookings.status.pending')}
              value={statistics?.pending || 0}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('bookings.status.confirmed')}
              value={statistics?.confirmed || 0}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('dashboard.totalRevenue')}
              value={statistics?.totalRevenue || 0}
              formatter={(value) => formatCurrency(value)}
              prefix={<DollarOutlined />}
            />
          </Card>
        </Col>
      </Row>

      <Card>
        <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
          <Col xs={24} sm={12} md={6}>
            <Search
              placeholder={t('bookings.searchPlaceholder')}
              onSearch={handleSearch}
              style={{ width: '100%' }}
            />
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('bookings.status.label')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('status', value)}
            >
              <Option value="pending">{t('bookings.status.pending')}</Option>
              <Option value="confirmed">{t('bookings.status.confirmed')}</Option>
              <Option value="cancelled">{t('bookings.status.cancelled')}</Option>
              <Option value="checked_in">{t('bookings.status.checked_in')}</Option>
              <Option value="checked_out">{t('bookings.status.checked_out')}</Option>
              <Option value="no_show">{t('bookings.status.no_show')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('bookings.paymentStatus')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('paymentStatus', value)}
            >
              <Option value="pending">{t('bookings.pending')}</Option>
              <Option value="paid">{t('bookings.paid')}</Option>
              <Option value="failed">{t('bookings.failed')}</Option>
              <Option value="refunded">{t('bookings.refunded')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <RangePicker
              style={{ width: '100%' }}
              onChange={handleDateRangeChange}
              placeholder={[t('bookings.checkInFrom'), t('bookings.checkInTo')]}
            />
          </Col>
        </Row>

        <Table
          rowSelection={rowSelection}
          columns={columns}
          dataSource={bookings}
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
          scroll={{ x: 1600 }}
        />
      </Card>
    </div>
  );
};

export default BookingList;
