import React, { useEffect, useState } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Tag,
  Space,
  Button,
  Rate,
  Carousel,
  Descriptions,
  Table,
  Avatar,
  Modal,
  message,
  Divider,
  Tooltip,
  Image,
  Input,
} from 'antd';
import {
  EditOutlined,
  DeleteOutlined,
  CheckOutlined,
  CloseOutlined,
  EnvironmentOutlined,
  PhoneOutlined,
  MailOutlined,
  UserOutlined,
  CalendarOutlined,
  StarOutlined,
  HomeOutlined,
} from '@ant-design/icons';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { fetchHotelById, approveHotel, deleteHotel } from '../../store/slices/hotelSlice';
import { formatCurrency } from '../../utils/format';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

const HotelDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { currentHotel: hotel, loading } = useSelector((state) => state.hotels);
  const [rejectionModalVisible, setRejectionModalVisible] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');

  useEffect(() => {
    if (id) {
      dispatch(fetchHotelById(id));
    }
  }, [dispatch, id]);

  const handleApprove = async () => {
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

  const handleReject = () => {
    setRejectionModalVisible(true);
  };

  const handleRejectConfirm = async () => {
    try {
      await dispatch(approveHotel({ 
        id: hotel._id, 
        data: { 
          isApproved: false, 
          rejectionReason 
        } 
      })).unwrap();
      message.success(t('hotels.rejectSuccess'));
      setRejectionModalVisible(false);
      setRejectionReason('');
    } catch (error) {
      message.error(error);
    }
  };

  const handleDelete = async () => {
    Modal.confirm({
      title: t('hotels.deleteConfirm'),
      content: t('hotels.deleteConfirmMessage'),
      okText: t('common.yes'),
      cancelText: t('common.no'),
      okType: 'danger',
      onOk: async () => {
        try {
          await dispatch(deleteHotel(hotel._id)).unwrap();
          message.success(t('hotels.deleteSuccess'));
          navigate('/hotels');
        } catch (error) {
          message.error(error);
        }
      },
    });
  };

  const getStatusColor = (isApproved, isActive) => {
    if (!isActive) return 'default';
    if (isApproved === true) return 'success';
    if (isApproved === false) return 'error';
    return 'warning';
  };

  const getStatusText = (isApproved, isActive) => {
    if (!isActive) return 'Inactive';
    if (isApproved === true) return t('hotels.approved');
    if (isApproved === false) return t('hotels.rejected');
    return t('hotels.pending');
  };

  const roomColumns = [
    {
      title: t('hotels.roomType'),
      dataIndex: 'type',
      key: 'type',
    },
    {
      title: t('hotels.roomNumber'),
      dataIndex: 'roomNumber',
      key: 'roomNumber',
    },
    {
      title: t('hotels.capacity'),
      dataIndex: 'capacity',
      key: 'capacity',
      render: (capacity) => `${capacity} guests`,
    },
    {
      title: t('hotels.pricePerNight'),
      dataIndex: 'pricePerNight',
      key: 'pricePerNight',
      render: (price) => formatCurrency(price),
    },
    {
      title: t('hotels.status'),
      dataIndex: 'isAvailable',
      key: 'status',
      render: (isAvailable) => (
        <Tag color={isAvailable ? 'success' : 'default'}>
          {isAvailable ? 'Available' : 'Unavailable'}
        </Tag>
      ),
    },
  ];

  const reviewColumns = [
    {
      title: t('hotels.customer'),
      dataIndex: 'user',
      key: 'user',
      render: (user) => (
        <Space>
          <Avatar icon={<UserOutlined />} />
          <div>
            <div>{user?.firstName} {user?.lastName}</div>
            <Text type="secondary" style={{ fontSize: 12 }}>{user?.email}</Text>
          </div>
        </Space>
      ),
    },
    {
      title: t('hotels.rating'),
      dataIndex: 'rating',
      key: 'rating',
      render: (rating) => <Rate disabled defaultValue={rating} />,
    },
    {
      title: t('hotels.comment'),
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
      title: t('hotels.date'),
      dataIndex: 'createdAt',
      key: 'date',
      render: (date) => dayjs(date).format('DD/MM/YYYY'),
    },
  ];

  if (loading || !hotel) {
    return <Card loading />;
  }

  return (
    <div>
      {/* Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Space>
            <Button onClick={() => navigate('/hotels')}>
              ← {t('common.back')}
            </Button>
            <Title level={2} style={{ margin: 0 }}>
              {hotel.name}
            </Title>
            <Tag color={getStatusColor(hotel.isApproved, hotel.isActive)}>
              {getStatusText(hotel.isApproved, hotel.isActive)}
            </Tag>
          </Space>
        </Col>
        <Col>
          <Space>
            {hotel.isApproved === null && (
              <>
                <Button
                  type="primary"
                  icon={<CheckOutlined />}
                  onClick={handleApprove}
                  style={{ backgroundColor: '#52c41a', borderColor: '#52c41a' }}
                >
                  {t('hotels.approve')}
                </Button>
                <Button
                  danger
                  icon={<CloseOutlined />}
                  onClick={handleReject}
                >
                  {t('hotels.reject')}
                </Button>
              </>
            )}
            <Button
              icon={<EditOutlined />}
              onClick={() => navigate(`/hotels/${id}/edit`)}
            >
              {t('hotels.editHotel')}
            </Button>
            <Button
              danger
              icon={<DeleteOutlined />}
              onClick={handleDelete}
            >
              {t('hotels.deleteHotel')}
            </Button>
          </Space>
        </Col>
      </Row>

      <Row gutter={[24, 24]}>
        {/* Images */}
        <Col xs={24} lg={12}>
          <Card title={t('hotels.images')}>
            {hotel.images && hotel.images.length > 0 ? (
              <Carousel autoplay>
                {hotel.images.map((image, index) => (
                  <div key={index}>
                    <Image
                      src={image.url}
                      alt={`Hotel ${index + 1}`}
                      style={{
                        width: '100%',
                        height: 300,
                        objectFit: 'cover',
                      }}
                    />
                  </div>
                ))}
              </Carousel>
            ) : (
              <div
                style={{
                  height: 300,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  backgroundColor: '#f5f5f5',
                }}
              >
                <HomeOutlined style={{ fontSize: 48, color: '#d9d9d9' }} />
              </div>
            )}
          </Card>
        </Col>

        {/* Basic Information */}
        <Col xs={24} lg={12}>
          <Card title={t('hotels.basicInfo')}>
            <Descriptions column={1}>
              <Descriptions.Item label={t('hotels.starRating')}>
                <Rate disabled defaultValue={hotel.starRating} />
              </Descriptions.Item>
              <Descriptions.Item label={t('hotels.averageRating')}>
                <Space>
                  <Rate disabled defaultValue={hotel.averageRating} />
                  <Text>({hotel.totalReviews} reviews)</Text>
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label={t('hotels.totalRooms')}>
                {hotel.totalRooms}
              </Descriptions.Item>
              <Descriptions.Item label={t('hotels.createdAt')}>
                {dayjs(hotel.createdAt).format('DD/MM/YYYY HH:mm')}
              </Descriptions.Item>
              <Descriptions.Item label={t('hotels.updatedAt')}>
                {dayjs(hotel.updatedAt).format('DD/MM/YYYY HH:mm')}
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>

        {/* Description */}
        <Col xs={24}>
          <Card title={t('hotels.description')}>
            <Paragraph>{hotel.description}</Paragraph>
          </Card>
        </Col>

        {/* Address & Contact */}
        <Col xs={24} lg={12}>
          <Card title={t('hotels.addressContact')}>
            <Space direction="vertical" style={{ width: '100%' }}>
              <Space>
                <EnvironmentOutlined />
                <div>
                  <div>{hotel.address?.street}</div>
                  <Text type="secondary">
                    {hotel.address?.city}, {hotel.address?.state} {hotel.address?.zipCode}
                  </Text>
                  <br />
                  <Text type="secondary">{hotel.address?.country}</Text>
                </div>
              </Space>
              {hotel.contactInfo?.phone && (
                <Space>
                  <PhoneOutlined />
                  <Text>{hotel.contactInfo.phone}</Text>
                </Space>
              )}
              {hotel.contactInfo?.email && (
                <Space>
                  <MailOutlined />
                  <Text>{hotel.contactInfo.email}</Text>
                </Space>
              )}
            </Space>
          </Card>
        </Col>

        {/* Owner Information */}
        <Col xs={24} lg={12}>
          <Card title={t('hotels.ownerInfo')}>
            <Space direction="vertical" style={{ width: '100%' }}>
              <Space>
                <Avatar size={48} icon={<UserOutlined />} />
                <div>
                  <div style={{ fontWeight: 'bold' }}>
                    {hotel.owner?.firstName} {hotel.owner?.lastName}
                  </div>
                  <Text type="secondary">{hotel.owner?.email}</Text>
                  <br />
                  <Text type="secondary">{hotel.owner?.phone}</Text>
                </div>
              </Space>
              <Descriptions size="small" column={1}>
                <Descriptions.Item label="User ID">
                  {hotel.owner?._id}
                </Descriptions.Item>
                <Descriptions.Item label="Role">
                  <Tag>{hotel.owner?.role}</Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Joined">
                  {dayjs(hotel.owner?.createdAt).format('DD/MM/YYYY')}
                </Descriptions.Item>
              </Descriptions>
            </Space>
          </Card>
        </Col>

        {/* Amenities */}
        {hotel.amenities && hotel.amenities.length > 0 && (
          <Col xs={24}>
            <Card title={t('hotels.amenities')}>
              <Space wrap>
                {hotel.amenities.map((amenity, index) => (
                  <Tag key={index} color="blue">
                    {amenity}
                  </Tag>
                ))}
              </Space>
            </Card>
          </Col>
        )}

        {/* Rooms */}
        {hotel.rooms && hotel.rooms.length > 0 && (
          <Col xs={24}>
            <Card title={`${t('hotels.rooms')} (${hotel.rooms.length})`}>
              <Table
                columns={roomColumns}
                dataSource={hotel.rooms}
                rowKey="_id"
                pagination={false}
                size="middle"
              />
            </Card>
          </Col>
        )}

        {/* Reviews */}
        {hotel.reviews && hotel.reviews.length > 0 && (
          <Col xs={24}>
            <Card title={`${t('hotels.reviews')} (${hotel.reviews.length})`}>
              <Table
                columns={reviewColumns}
                dataSource={hotel.reviews}
                rowKey="_id"
                pagination={{ pageSize: 5 }}
                size="middle"
              />
            </Card>
          </Col>
        )}

        {/* Rejection Reason */}
        {hotel.isApproved === false && hotel.rejectionReason && (
          <Col xs={24}>
            <Card title={t('hotels.rejectionReason')}>
              <Text type="danger">{hotel.rejectionReason}</Text>
            </Card>
          </Col>
        )}
      </Row>

      {/* Rejection Modal */}
      <Modal
        title={t('hotels.rejectionReason')}
        open={rejectionModalVisible}
        onOk={handleRejectConfirm}
        onCancel={() => {
          setRejectionModalVisible(false);
          setRejectionReason('');
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

export default HotelDetail;
