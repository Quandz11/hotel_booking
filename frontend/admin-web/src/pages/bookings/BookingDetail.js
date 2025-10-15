import React, { useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Tag,
  Space,
  Button,
  Popconfirm,
  message,
  Descriptions,
  Timeline,
  Avatar,
  Divider,
  Steps,
  Alert,
} from 'antd';
import {
  UserOutlined,
  HomeOutlined,
  CalendarOutlined,
  DollarOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { fetchBookingById, updateBookingStatus } from '../../store/slices/bookingSlice';
import { formatCurrency } from '../../utils/format';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;
const { Step } = Steps;

const BookingDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { currentBooking: booking, loading } = useSelector((state) => state.bookings);
  const { user } = useSelector((state) => state.auth);

  useEffect(() => {
    if (id) {
      dispatch(fetchBookingById(id));
    }
  }, [dispatch, id]);

  const canManage = user?.role === 'admin' || user?.role === 'hotel_owner';

  const handleStatusUpdate = async (newStatus) => {
    try {
      await dispatch(updateBookingStatus({ id, status: newStatus })).unwrap();
      message.success(t('messages.updateSuccess'));
      dispatch(fetchBookingById(id));
    } catch (err) {
      message.error(typeof err === 'string' ? err : t('errors.somethingWentWrong'));
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: 'warning',
      confirmed: 'success',
      cancelled: 'error',
      completed: 'default',
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

  const getBookingSteps = () => {
    if (!booking) return [];
    
    const steps = [
      {
        title: 'Booking Created',
        status: 'finish',
        icon: <CheckCircleOutlined />,
        description: dayjs(booking.createdAt).format('DD/MM/YYYY HH:mm'),
      },
    ];

    if (booking.status === 'confirmed') {
      steps.push({
        title: 'Booking Confirmed',
        status: 'finish',
        icon: <CheckCircleOutlined />,
        description: booking.confirmedAt ? dayjs(booking.confirmedAt).format('DD/MM/YYYY HH:mm') : 'Confirmed',
      });
    } else if (booking.status === 'cancelled') {
      steps.push({
        title: 'Booking Cancelled',
        status: 'error',
        icon: <CloseCircleOutlined />,
        description: booking.cancelledAt ? dayjs(booking.cancelledAt).format('DD/MM/YYYY HH:mm') : 'Cancelled',
      });
      return steps;
    } else {
      steps.push({
        title: 'Awaiting Confirmation',
        status: 'process',
        icon: <ClockCircleOutlined />,
      });
    }

    if (booking.status === 'confirmed') {
      const isCheckedIn = dayjs().isAfter(dayjs(booking.checkInDate));
      const isCheckedOut = dayjs().isAfter(dayjs(booking.checkOutDate));

      steps.push({
        title: 'Check-in',
        status: isCheckedIn ? 'finish' : 'wait',
        icon: isCheckedIn ? <CheckCircleOutlined /> : <ClockCircleOutlined />,
        description: dayjs(booking.checkInDate).format('DD/MM/YYYY'),
      });

      steps.push({
        title: 'Check-out',
        status: isCheckedOut ? 'finish' : 'wait',
        icon: isCheckedOut ? <CheckCircleOutlined /> : <ClockCircleOutlined />,
        description: dayjs(booking.checkOutDate).format('DD/MM/YYYY'),
      });

      if (booking.status === 'completed') {
        steps.push({
          title: 'Completed',
          status: 'finish',
          icon: <CheckCircleOutlined />,
          description: booking.completedAt ? dayjs(booking.completedAt).format('DD/MM/YYYY HH:mm') : 'Completed',
        });
      }
    }

    return steps;
  };

  if (loading || !booking) {
    return <Card loading />;
  }

  const totalNights = dayjs(booking.checkOutDate).diff(dayjs(booking.checkInDate), 'day');

  return (
    <div>
      {/* Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Space>
            <Button onClick={() => navigate('/bookings')}>
              ← {t('common.back')}
            </Button>
            <Title level={2} style={{ margin: 0 }}>
              Booking {booking.bookingNumber || booking.bookingId}
            </Title>
            <Tag color={getStatusColor(booking.status)}>
              {t(`bookings.status.${booking.status}`)}
            </Tag>
          </Space>
        </Col>
        <Col>
          {canManage && booking.status === 'pending' && (
            <Space>
              <Popconfirm
                title={t('bookings.confirmBooking')}
                onConfirm={() => handleStatusUpdate('confirmed')}
                okText={t('common.yes')}
                cancelText={t('common.no')}
              >
                <Button type="primary" icon={<CheckCircleOutlined />}>{t('bookings.confirm')}</Button>
              </Popconfirm>
              <Popconfirm
                title={t('bookings.cancelBooking')}
                onConfirm={() => handleStatusUpdate('cancelled')}
                okText={t('common.yes')}
                cancelText={t('common.no')}
              >
                <Button danger icon={<CloseCircleOutlined />}>{t('bookings.cancel')}</Button>
              </Popconfirm>
            </Space>
          )}
        </Col>
      </Row>

      {/* Status Alert */}
      {booking.status === 'cancelled' && booking.cancellationReason && (
        <Alert
          message="Booking Cancelled"
          description={`Reason: ${booking.cancellationReason}`}
          type="error"
          style={{ marginBottom: 24 }}
        />
      )}

      <Row gutter={[24, 24]}>
        {/* Booking Progress */}
        <Col xs={24}>
          <Card title="Booking Status">
            <Steps current={getBookingSteps().findIndex(step => step.status === 'process')}>
              {getBookingSteps().map((step, index) => (
                <Step
                  key={index}
                  title={step.title}
                  status={step.status}
                  icon={step.icon}
                  description={step.description}
                />
              ))}
            </Steps>
          </Card>
        </Col>

        {/* Guest Information */}
        <Col xs={24} lg={12}>
          <Card title={t('bookings.customerInfo')}>
            <Space direction="vertical" style={{ width: '100%' }}>
              <Space>
                <Avatar 
                  size={48} 
                  src={booking.user?.avatar?.url}
                  icon={<UserOutlined />} 
                />
                <div>
                  <div style={{ fontWeight: 'bold', fontSize: 16 }}>
                    {booking.user?.firstName} {booking.user?.lastName}
                  </div>
                  <Text type="secondary">{booking.user?.email}</Text>
                  <br />
                  <Text type="secondary">{booking.user?.phone}</Text>
                </div>
              </Space>
              
              <Divider />
              
              <Descriptions column={1} size="small">
                <Descriptions.Item label="User ID">
                  <Text code>{booking.user?._id}</Text>
                </Descriptions.Item>
                <Descriptions.Item label="Adults">
                  {booking.guests?.adults || 0}
                </Descriptions.Item>
                <Descriptions.Item label="Children">
                  {booking.guests?.children || 0}
                </Descriptions.Item>
                {booking.specialRequests && (
                  <Descriptions.Item label="Special Requests">
                    <Paragraph>{booking.specialRequests}</Paragraph>
                  </Descriptions.Item>
                )}
              </Descriptions>
            </Space>
          </Card>
        </Col>

        {/* Hotel Information */}
        <Col xs={24} lg={12}>
          <Card title={t('bookings.hotelInfo')}>
            <Space direction="vertical" style={{ width: '100%' }}>
              <Space>
                <Avatar 
                  size={48} 
                  src={booking.hotel?.images?.[0]?.url}
                  icon={<HomeOutlined />} 
                />
                <div>
                  <div style={{ fontWeight: 'bold', fontSize: 16 }}>
                    {booking.hotel?.name}
                  </div>
                  <Text type="secondary">
                    {booking.hotel?.address?.street}
                  </Text>
                  <br />
                  <Text type="secondary">
                    {booking.hotel?.address?.city}, {booking.hotel?.address?.country}
                  </Text>
                </div>
              </Space>
              
              <Divider />
              
              <Descriptions column={1} size="small">
                <Descriptions.Item label="Hotel ID">
                  <Text code>{booking.hotel?._id}</Text>
                </Descriptions.Item>
                <Descriptions.Item label="Contact">
                  {booking.hotel?.contactInfo?.phone}
                </Descriptions.Item>
                <Descriptions.Item label="Email">
                  {booking.hotel?.contactInfo?.email}
                </Descriptions.Item>
              </Descriptions>
            </Space>
          </Card>
        </Col>

        {/* Room Information */}
        <Col xs={24} lg={12}>
          <Card title={t('bookings.roomInfo')}>
            <Descriptions column={1}>
              <Descriptions.Item label="Room Type">
                <Text strong>{booking.room?.type}</Text>
              </Descriptions.Item>
              <Descriptions.Item label="Room Number">
                {booking.room?.roomNumber}
              </Descriptions.Item>
              <Descriptions.Item label="Capacity">
                {booking.room?.capacity} guests
              </Descriptions.Item>
              <Descriptions.Item label="Price per Night">
                {formatCurrency(booking.room?.pricePerNight)}
              </Descriptions.Item>
              {booking.room?.amenities && booking.room.amenities.length > 0 && (
                <Descriptions.Item label="Room Amenities">
                  <Space wrap>
                    {booking.room.amenities.map((amenity, index) => (
                      <Tag key={index}>{amenity}</Tag>
                    ))}
                  </Space>
                </Descriptions.Item>
              )}
            </Descriptions>
          </Card>
        </Col>

        {/* Booking Details */}
        <Col xs={24} lg={12}>
          <Card title={t('bookings.bookingDetails')}>
            <Descriptions column={1}>
              <Descriptions.Item label="Check-in Date">
                <Space>
                  <CalendarOutlined />
                  <Text strong>{dayjs(booking.checkInDate).format('DD/MM/YYYY')}</Text>
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Check-out Date">
                <Space>
                  <CalendarOutlined />
                  <Text strong>{dayjs(booking.checkOutDate).format('DD/MM/YYYY')}</Text>
                </Space>
              </Descriptions.Item>
              <Descriptions.Item label="Total Nights">
                {totalNights} nights
              </Descriptions.Item>
              <Descriptions.Item label="Booking Date">
                {dayjs(booking.createdAt).format('DD/MM/YYYY HH:mm')}
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>

        {/* Payment Information */}
        <Col xs={24}>
          <Card title={t('bookings.paymentInfo')}>
            <Row gutter={[24, 16]}>
              <Col xs={24} md={12}>
                <Descriptions column={1}>
                  <Descriptions.Item label="Room Rate">
                    {formatCurrency(booking.room?.pricePerNight)} × {totalNights} nights
                  </Descriptions.Item>
                  <Descriptions.Item label="Subtotal">
                    {formatCurrency(booking.subtotal || (booking.room?.pricePerNight * totalNights))}
                  </Descriptions.Item>
                  {booking.taxes > 0 && (
                    <Descriptions.Item label="Taxes & Fees">
                      {formatCurrency(booking.taxes)}
                    </Descriptions.Item>
                  )}
                  {booking.discount > 0 && (
                    <Descriptions.Item label="Discount">
                      -{formatCurrency(booking.discount)}
                    </Descriptions.Item>
                  )}
                  <Descriptions.Item label="Total Amount">
                    <Text strong style={{ fontSize: 18 }}>
                      {formatCurrency(booking.totalAmount)}
                    </Text>
                  </Descriptions.Item>
                </Descriptions>
              </Col>
              <Col xs={24} md={12}>
                <Descriptions column={1}>
                  <Descriptions.Item label="Payment Status">
                    <Tag color={getPaymentStatusColor(booking.paymentStatus)}>
                      {booking.paymentStatus}
                    </Tag>
                  </Descriptions.Item>
                  <Descriptions.Item label="Payment Method">
                    {booking.paymentMethod || 'N/A'}
                  </Descriptions.Item>
                  {booking.paymentDate && (
                    <Descriptions.Item label="Payment Date">
                      {dayjs(booking.paymentDate).format('DD/MM/YYYY HH:mm')}
                    </Descriptions.Item>
                  )}
                  {booking.transactionId && (
                    <Descriptions.Item label="Transaction ID">
                      <Text code>{booking.transactionId}</Text>
                    </Descriptions.Item>
                  )}
                </Descriptions>
              </Col>
            </Row>
          </Card>
        </Col>

        {/* Activity Timeline */}
        <Col xs={24}>
          <Card title="Activity Timeline">
            <Timeline>
              <Timeline.Item color="green">
                <Text strong>Booking Created</Text>
                <br />
                <Text type="secondary">{dayjs(booking.createdAt).format('DD/MM/YYYY HH:mm')}</Text>
              </Timeline.Item>
              
              {booking.confirmedAt && (
                <Timeline.Item color="blue">
                  <Text strong>Booking Confirmed</Text>
                  <br />
                  <Text type="secondary">{dayjs(booking.confirmedAt).format('DD/MM/YYYY HH:mm')}</Text>
                </Timeline.Item>
              )}
              
              {booking.paymentDate && (
                <Timeline.Item color="green">
                  <Text strong>Payment Received</Text>
                  <br />
                  <Text type="secondary">{dayjs(booking.paymentDate).format('DD/MM/YYYY HH:mm')}</Text>
                </Timeline.Item>
              )}
              
              {booking.cancelledAt && (
                <Timeline.Item color="red">
                  <Text strong>Booking Cancelled</Text>
                  <br />
                  <Text type="secondary">{dayjs(booking.cancelledAt).format('DD/MM/YYYY HH:mm')}</Text>
                  {booking.cancellationReason && (
                    <>
                      <br />
                      <Text type="secondary">Reason: {booking.cancellationReason}</Text>
                    </>
                  )}
                </Timeline.Item>
              )}
              
              {booking.completedAt && (
                <Timeline.Item color="green">
                  <Text strong>Booking Completed</Text>
                  <br />
                  <Text type="secondary">{dayjs(booking.completedAt).format('DD/MM/YYYY HH:mm')}</Text>
                </Timeline.Item>
              )}
            </Timeline>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default BookingDetail;
