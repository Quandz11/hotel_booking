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
  Rate,
  Avatar,
  Statistic,
} from 'antd';
import {
  SearchOutlined,
  EyeOutlined,
  DeleteOutlined,
  CheckOutlined,
  CloseOutlined,
  UserOutlined,
  HomeOutlined,
  StarOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { 
  fetchReviews, 
  updateReviewStatus, 
  deleteReview, 
  setFilters 
} from '../../store/slices/reviewSlice';
import dayjs from 'dayjs';

const { Search } = Input;
const { Option } = Select;
const { Title, Text, Paragraph } = Typography;

const ReviewList = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { reviews, pagination, loading, filters, statistics } = useSelector((state) => state.reviews);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);

  useEffect(() => {
    dispatch(fetchReviews({ 
      page: pagination.page, 
      limit: pagination.limit,
      ...filters 
    }));
  }, [dispatch, pagination.page, pagination.limit, filters]);

  const handleTableChange = (paginationInfo) => {
    dispatch(fetchReviews({
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

  const handleApprove = async (review) => {
    try {
      await dispatch(updateReviewStatus({ 
        id: review._id, 
        isApproved: true 
      })).unwrap();
      message.success(t('reviews.approveSuccess'));
    } catch (error) {
      message.error(error);
    }
  };

  const handleReject = async (review) => {
    try {
      await dispatch(updateReviewStatus({ 
        id: review._id, 
        isApproved: false 
      })).unwrap();
      message.success(t('reviews.rejectSuccess'));
    } catch (error) {
      message.error(error);
    }
  };

  const handleDelete = async (review) => {
    try {
      await dispatch(deleteReview(review._id)).unwrap();
      message.success(t('reviews.deleteSuccess'));
    } catch (error) {
      message.error(error);
    }
  };

  const getStatusColor = (isApproved) => {
    if (isApproved === true) return 'success';
    if (isApproved === false) return 'error';
    return 'warning';
  };

  const getStatusText = (isApproved) => {
    if (isApproved === true) return t('reviews.approved');
    if (isApproved === false) return t('reviews.rejected');
    return t('reviews.rejected');
  };

  const getRatingColor = (rating) => {
    if (rating >= 4) return '#52c41a';
    if (rating >= 3) return '#faad14';
    return '#f5222d';
  };

  const columns = [
    {
      title: t('reviews.reviewer'),
      dataIndex: 'user',
      key: 'user',
      render: (user) => (
        <Space>
          <Avatar
            size={32}
            src={user?.avatar?.url}
            icon={<UserOutlined />}
          />
          <div>
            <div style={{ fontWeight: 'bold' }}>
              {user?.firstName} {user?.lastName}
            </div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {user?.email}
            </Text>
          </div>
        </Space>
      ),
      width: 200,
    },
    {
      title: t('reviews.hotel'),
      dataIndex: 'hotel',
      key: 'hotel',
      render: (hotel) => (
        <Space>
          <Avatar
            size={32}
            src={hotel?.images?.[0]?.url}
            icon={<HomeOutlined />}
          />
          <div>
            <div style={{ fontWeight: 'bold' }}>{hotel?.name}</div>
            <Text type="secondary" style={{ fontSize: 12 }}>
              {hotel?.address?.city}
            </Text>
          </div>
        </Space>
      ),
      width: 200,
    },
    {
      title: t('reviews.rating'),
      dataIndex: 'rating',
      key: 'rating',
      render: (rating) => (
        <Space>
          <Rate disabled defaultValue={rating} style={{ fontSize: 14 }} />
          <Text style={{ color: getRatingColor(rating), fontWeight: 'bold' }}>
            {rating}
          </Text>
        </Space>
      ),
      width: 150,
    },
    {
      title: t('reviews.comment'),
      dataIndex: 'comment',
      key: 'comment',
      render: (comment) => (
        <Paragraph
          ellipsis={{ rows: 2, expandable: true, symbol: 'more' }}
          style={{ marginBottom: 0, maxWidth: 300 }}
        >
          {comment}
        </Paragraph>
      ),
      width: 300,
    },
    {
      title: t('reviews.booking'),
      dataIndex: 'booking',
      key: 'booking',
      render: (booking) => (
        <div>
          <Text code style={{ fontSize: 11 }}>{booking?.bookingId}</Text>
          <br />
          <Text type="secondary" style={{ fontSize: 11 }}>
            {dayjs(booking?.checkInDate).format('DD/MM/YY')}
          </Text>
        </div>
      ),
      width: 120,
    },
    {
      title: t('reviews.status'),
      key: 'status',
      render: (_, record) => (
        <Tag color={getStatusColor(record.isApproved)}>
          {getStatusText(record.isApproved)}
        </Tag>
      ),
      width: 100,
    },
    {
      title: t('reviews.date'),
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (date) => dayjs(date).format('DD/MM/YY'),
      width: 100,
    },
    {
      title: t('common.actions'),
      key: 'actions',
      render: (_, record) => (
        <Space size="small">
          <Tooltip title={t('reviews.viewDetails')}>
            <Button
              type="text"
              icon={<EyeOutlined />}
              onClick={() => navigate(`/reviews/${record._id}`)}
            />
          </Tooltip>
          
          {record.isApproved === null && (
            <>
              <Tooltip title={t('reviews.approve')}>
                <Popconfirm
                  title={t('reviews.approveConfirm')}
                  onConfirm={() => handleApprove(record)}
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
              <Tooltip title={t('reviews.reject')}>
                <Popconfirm
                  title={t('reviews.rejectConfirm')}
                  onConfirm={() => handleReject(record)}
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
          
          <Tooltip title={t('reviews.deleteReview')}>
            <Popconfirm
              title={t('reviews.deleteConfirm')}
              onConfirm={() => handleDelete(record)}
              okText={t('common.yes')}
              cancelText={t('common.no')}
            >
              <Button
                type="text"
                icon={<DeleteOutlined />}
                danger
              />
            </Popconfirm>
          </Tooltip>
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
          <Title level={2}>{t('reviews.title')}</Title>
        </Col>
      </Row>

      {/* Statistics */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Total Reviews"
              value={statistics?.total || 0}
              prefix={<StarOutlined />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Pending"
              value={statistics?.pending || 0}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Approved"
              value={statistics?.approved || 0}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title="Average Rating"
              value={statistics?.averageRating || 0}
              precision={1}
              prefix={<StarOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
      </Row>

      <Card>
        <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
          <Col xs={24} sm={12} md={8}>
            <Search
              placeholder={t('reviews.searchPlaceholder')}
              onSearch={handleSearch}
              style={{ width: '100%' }}
            />
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('reviews.status')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('isApproved', value)}
            >
              <Option value={true}>{t('reviews.approved')}</Option>
              <Option value={false}>{t('reviews.rejected')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('reviews.rating')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('rating', value)}
            >
              <Option value={5}>5 Stars</Option>
              <Option value={4}>4 Stars</Option>
              <Option value={3}>3 Stars</Option>
              <Option value={2}>2 Stars</Option>
              <Option value={1}>1 Star</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder="Sort By"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('sortBy', value)}
            >
              <Option value="newest">Newest First</Option>
              <Option value="oldest">Oldest First</Option>
              <Option value="highest_rating">Highest Rating</Option>
              <Option value="lowest_rating">Lowest Rating</Option>
            </Select>
          </Col>
        </Row>

        <Table
          rowSelection={rowSelection}
          columns={columns}
          dataSource={reviews}
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
          scroll={{ x: 1400 }}
        />
      </Card>
    </div>
  );
};

export default ReviewList;
