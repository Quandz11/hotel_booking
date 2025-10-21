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
  Rate,
  Tooltip,
  Popconfirm,
} from 'antd';
import {
  PlusOutlined,
  SearchOutlined,
  EyeOutlined,
  EditOutlined,
  DeleteOutlined,
  CheckOutlined,
  CloseOutlined,
  HomeOutlined,
  StarFilled,
  StarOutlined,
  EnvironmentOutlined,
  UserOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { fetchHotels, approveHotel, deleteHotel, setFilters } from '../../store/slices/hotelSlice';
import dayjs from 'dayjs';

const { Search } = Input;
const { Option } = Select;
const { Title, Text } = Typography;

const HotelList = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { hotels, pagination, loading, filters } = useSelector((state) => state.hotels);
  const [selectedRowKeys, setSelectedRowKeys] = useState([]);
  const [rejectionModalVisible, setRejectionModalVisible] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [currentHotel, setCurrentHotel] = useState(null);

  useEffect(() => {
    dispatch(fetchHotels({ 
      page: pagination.page, 
      limit: pagination.limit,
      ...filters 
    }));
  }, [dispatch, pagination.page, pagination.limit, filters]);

  const handleTableChange = (paginationInfo) => {
    dispatch(fetchHotels({
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

  const handleApprove = async (hotel) => {
    try {
      await dispatch(approveHotel({ 
        id: hotel._id, 
        data: { isApproved: true } 
      })).unwrap();
      message.success(t('hotels.approveSuccess'));
    } catch (error) {
      message.error(error);
    }
  };

  const handleReject = (hotel) => {
    setCurrentHotel(hotel);
    setRejectionModalVisible(true);
  };

  const handleRejectConfirm = async () => {
    try {
      await dispatch(approveHotel({ 
        id: currentHotel._id, 
        data: { 
          isApproved: false, 
          rejectionReason 
        } 
      })).unwrap();
      message.success(t('hotels.rejectSuccess'));
      setRejectionModalVisible(false);
      setRejectionReason('');
      setCurrentHotel(null);
    } catch (error) {
      message.error(error);
    }
  };

  const handleDelete = async (hotel) => {
    try {
      await dispatch(deleteHotel(hotel._id)).unwrap();
      message.success(t('hotels.deleteSuccess'));
    } catch (error) {
      message.error(error);
    }
  };

  const getStatusColor = (isApproved, isActive) => {
    if (!isActive) return 'default';
    if (isApproved === true) return 'success';
    if (isApproved === false) return 'warning';
    return 'warning';
  };

  const getStatusText = (isApproved, isActive) => {
    if (!isActive) return t('hotels.inactive') || 'Inactive';
    if (isApproved === true) return t('hotels.approved');
    if (isApproved === false) return t('hotels.pending');
    return t('hotels.pending');
  };

  const columns = [
    {
      title: t('hotels.hotelInfo'),
      key: 'hotelInfo',
      render: (_, record) => (
        <Card size="small" style={{ margin: 0 }}>
          <Row gutter={16} align="middle">
            <Col flex="none">
              <Avatar
                size={60}
                src={record.images?.[0]?.url}
                icon={<HomeOutlined />}
                style={{ borderRadius: 8 }}
              />
            </Col>
            <Col flex="auto">
              <Space direction="vertical" size="small" style={{ width: '100%' }}>
                <div>
                  <Text strong style={{ fontSize: 18 }}>
                    {record.name}
                  </Text>
                  <Tag 
                    color={getStatusColor(record.isApproved, record.isActive)} 
                    style={{ marginLeft: 8 }}
                  >
                    {getStatusText(record.isApproved, record.isActive)}
                  </Tag>
                  {record.starRating && (
                    <Space style={{ marginLeft: 8 }}>
                      {[...Array(record.starRating)].map((_, i) => (
                        <StarFilled key={i} style={{ color: '#fadb14', fontSize: 12 }} />
                      ))}
                    </Space>
                  )}
                </div>
                
                <Space size="middle" wrap>
                  <Space size="small">
                    <EnvironmentOutlined style={{ color: '#1890ff' }} />
                    <Text style={{ fontSize: 12 }}>
                      {record.address?.city}, {record.address?.country}
                    </Text>
                  </Space>
                  
                  <Space size="small">
                    <UserOutlined style={{ color: '#52c41a' }} />
                    <Text style={{ fontSize: 12 }}>
                      {record.owner?.firstName} {record.owner?.lastName}
                    </Text>
                  </Space>
                  
                  <Space size="small">
                    <HomeOutlined style={{ color: '#722ed1' }} />
                    <Text style={{ fontSize: 12 }}>
                      {record.totalRooms || 0} rooms
                    </Text>
                  </Space>
                  
                  {record.averageRating && (
                    <Space size="small">
                      <StarOutlined style={{ color: '#fadb14' }} />
                      <Text style={{ fontSize: 12 }}>
                        {record.averageRating.toFixed(1)} ({record.totalReviews || 0} reviews)
                      </Text>
                    </Space>
                  )}
                </Space>

                <Row justify="space-between" align="middle">
                  <Col>
                    <Space size="middle">
                      <Text style={{ fontSize: 11 }} type="secondary">
                        Created: {dayjs(record.createdAt).format('DD/MM/YYYY')}
                      </Text>
                      
                      {record.lastUpdated && (
                        <Text style={{ fontSize: 11 }} type="secondary">
                          Updated: {dayjs(record.lastUpdated).format('DD/MM/YYYY')}
                        </Text>
                      )}
                    </Space>
                  </Col>
                  
                  <Col>
                    <Space size="small">
                      <Tooltip title={t('hotels.viewDetails')}>
                        <Button
                          size="small"
                          icon={<EyeOutlined />}
                          onClick={() => navigate(`/hotels/${record._id}`)}
                        />
                      </Tooltip>
                      <Tooltip title="Manage Rooms">
                        <Button
                          size="small"
                          icon={<HomeOutlined />}
                          onClick={() => navigate(`/hotels/${record._id}/rooms`)}
                        />
                      </Tooltip>
                      <Tooltip title={t('hotels.editHotel')}>
                        <Button
                          size="small"
                          icon={<EditOutlined />}
                          onClick={() => navigate(`/hotels/${record._id}/edit`)}
                        />
                      </Tooltip>
                      
                      {record.isApproved === false && (
                        <>
                          <Tooltip title={t('hotels.approve')}>
                            <Popconfirm
                              title={t('hotels.approveConfirm')}
                              onConfirm={() => handleApprove(record)}
                              okText={t('common.yes')}
                              cancelText={t('common.no')}
                            >
                              <Button
                                size="small"
                                icon={<CheckOutlined />}
                                style={{ color: '#52c41a' }}
                              />
                            </Popconfirm>
                          </Tooltip>
                          <Tooltip title={t('hotels.reject')}>
                            <Button
                              size="small"
                              icon={<CloseOutlined />}
                              style={{ color: '#f5222d' }}
                              onClick={() => {
                                setCurrentHotel(record);
                                setRejectionModalVisible(true);
                              }}
                            />
                          </Tooltip>
                        </>
                      )}
                      
                      <Tooltip title={t('hotels.deleteHotel')}>
                        <Popconfirm
                          title={t('hotels.deleteConfirm')}
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

                {/* Additional info */}
                {record.amenities && record.amenities.length > 0 && (
                  <div>
                    <Text style={{ fontSize: 11 }} type="secondary">
                      Amenities: {record.amenities.slice(0, 3).join(', ')}
                      {record.amenities.length > 3 && ` +${record.amenities.length - 3} more`}
                    </Text>
                  </div>
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
          <Title level={2}>{t('hotels.title')}</Title>
        </Col>
        <Col>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/hotels/new')}
          >
            {t('hotels.addHotel')}
          </Button>
        </Col>
      </Row>

      <Card>
        <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
          <Col xs={24} sm={12} md={8}>
            <Search
              placeholder={t('common.search')}
              onSearch={handleSearch}
              style={{ width: '100%' }}
            />
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('hotels.status')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('isApproved', value)}
            >
              <Option value={true}>{t('hotels.approved')}</Option>
              <Option value={false}>{t('hotels.pending')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder={t('hotels.starRating')}
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('starRating', value)}
            >
              <Option value={5}>5 Stars</Option>
              <Option value={4}>4 Stars</Option>
              <Option value={3}>3 Stars</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={4}>
            <Select
              placeholder="Active Status"
              style={{ width: '100%' }}
              allowClear
              onChange={(value) => handleFilterChange('isActive', value)}
            >
              <Option value={true}>Active</Option>
              <Option value={false}>Inactive</Option>
            </Select>
          </Col>
        </Row>

        <Table
          rowSelection={rowSelection}
          columns={columns}
          dataSource={hotels}
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

      {/* Rejection Modal */}
      <Modal
        title={t('hotels.rejectionReason')}
        open={rejectionModalVisible}
        onOk={handleRejectConfirm}
        onCancel={() => {
          setRejectionModalVisible(false);
          setRejectionReason('');
          setCurrentHotel(null);
        }}
        okText={t('hotels.reject')}
        cancelText={t('common.cancel')}
      >
        <Input.TextArea
          rows={4}
          value={rejectionReason}
          onChange={(e) => setRejectionReason(e.target.value)}
          placeholder="Enter rejection reason..."
        />
      </Modal>
    </div>
  );
};

export default HotelList;
