import React, { useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Tag,
  Space,
  Button,
  Descriptions,
  Avatar,
  Rate,
  Divider,
  Image,
  Timeline,
} from 'antd';
import {
  UserOutlined,
  HomeOutlined,
  CalendarOutlined,
  StarOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { fetchReviewById } from '../../store/slices/reviewSlice';
import dayjs from 'dayjs';

const { Title, Text, Paragraph } = Typography;

const ReviewDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { currentReview: review, loading } = useSelector((state) => state.reviews);

  useEffect(() => {
    if (id) {
      dispatch(fetchReviewById(id));
    }
  }, [dispatch, id]);

  const getStatusColor = (isApproved) => {
    if (isApproved === true) return 'success';
    if (isApproved === false) return 'error';
    return 'warning';
  };

  const getStatusText = (isApproved) => {
    if (isApproved === true) return t('reviews.approved');
    if (isApproved === false) return t('reviews.rejected');
    return t('reviews.pending');
  };

  const getRatingColor = (rating) => {
    if (rating >= 4) return '#52c41a';
    if (rating >= 3) return '#faad14';
    return '#f5222d';
  };

  if (loading || !review) {
    return <Card loading />;
  }

  return (
    <div>
      {/* Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Space>
            <Button onClick={() => navigate('/reviews')}>
              ← {t('common.back')}
            </Button>
            <Title level={2} style={{ margin: 0 }}>
              Review Details
            </Title>
            <Tag color={getStatusColor(review.isApproved)}>
              {getStatusText(review.isApproved)}
            </Tag>
          </Space>
        </Col>
      </Row>

      <Row gutter={[24, 24]}>
        {/* Review Content */}
        <Col xs={24} lg={16}>
          <Card title="Review Content">
            <Space direction="vertical" style={{ width: '100%' }}>
              {/* Rating */}
              <div style={{ textAlign: 'center', padding: '20px 0' }}>
                <Rate 
                  disabled 
                  defaultValue={review.rating} 
                  style={{ fontSize: 32 }}
                />
                <div style={{ marginTop: 8 }}>
                  <Text 
                    style={{ 
                      fontSize: 24, 
                      fontWeight: 'bold',
                      color: getRatingColor(review.rating)
                    }}
                  >
                    {review.rating}/5
                  </Text>
                </div>
              </div>

              <Divider />

              {/* Comment */}
              <div>
                <Title level={4}>Review Comment</Title>
                <Paragraph style={{ fontSize: 16, lineHeight: 1.6 }}>
                  {review.comment}
                </Paragraph>
              </div>

              {/* Review Images */}
              {review.images && review.images.length > 0 && (
                <div>
                  <Title level={4}>Review Images</Title>
                  <Row gutter={[16, 16]}>
                    {review.images.map((image, index) => (
                      <Col key={index} xs={12} sm={8} md={6}>
                        <Image
                          src={image.url}
                          alt={`Review image ${index + 1}`}
                          style={{ width: '100%', borderRadius: 8 }}
                        />
                      </Col>
                    ))}
                  </Row>
                </div>
              )}

              {/* Helpful Votes */}
              {review.helpfulVotes > 0 && (
                <div>
                  <Text type="secondary">
                    {review.helpfulVotes} people found this review helpful
                  </Text>
                </div>
              )}
            </Space>
          </Card>
        </Col>

        {/* Review Details */}
        <Col xs={24} lg={8}>
          <Space direction="vertical" style={{ width: '100%' }} size="large">
            {/* Reviewer Info */}
            <Card title="Reviewer Information">
              <Space direction="vertical" style={{ width: '100%' }}>
                <Space>
                  <Avatar 
                    size={48} 
                    src={review.user?.avatar?.url}
                    icon={<UserOutlined />} 
                  />
                  <div>
                    <div style={{ fontWeight: 'bold', fontSize: 16 }}>
                      {review.user?.firstName} {review.user?.lastName}
                    </div>
                    <Text type="secondary">{review.user?.email}</Text>
                  </div>
                </Space>
                
                <Descriptions column={1} size="small">
                  <Descriptions.Item label="User ID">
                    <Text code>{review.user?._id}</Text>
                  </Descriptions.Item>
                  <Descriptions.Item label="Member Since">
                    {dayjs(review.user?.createdAt).format('MMMM YYYY')}
                  </Descriptions.Item>
                  <Descriptions.Item label="Total Reviews">
                    {review.user?.totalReviews || 0}
                  </Descriptions.Item>
                  <Descriptions.Item label="Average Rating">
                    <Rate 
                      disabled 
                      defaultValue={review.user?.averageRating || 0} 
                      style={{ fontSize: 12 }}
                    />
                  </Descriptions.Item>
                </Descriptions>
              </Space>
            </Card>

            {/* Hotel Info */}
            <Card title="Hotel Information">
              <Space direction="vertical" style={{ width: '100%' }}>
                <Space>
                  <Avatar 
                    size={48} 
                    src={review.hotel?.images?.[0]?.url}
                    icon={<HomeOutlined />} 
                  />
                  <div>
                    <div style={{ fontWeight: 'bold', fontSize: 16 }}>
                      {review.hotel?.name}
                    </div>
                    <Text type="secondary">
                      {review.hotel?.address?.city}, {review.hotel?.address?.country}
                    </Text>
                  </div>
                </Space>
                
                <Descriptions column={1} size="small">
                  <Descriptions.Item label="Hotel ID">
                    <Text code>{review.hotel?._id}</Text>
                  </Descriptions.Item>
                  <Descriptions.Item label="Star Rating">
                    <Rate 
                      disabled 
                      defaultValue={review.hotel?.starRating} 
                      style={{ fontSize: 12 }}
                    />
                  </Descriptions.Item>
                  <Descriptions.Item label="Average Rating">
                    {review.hotel?.averageRating?.toFixed(1) || '0.0'}/5
                  </Descriptions.Item>
                  <Descriptions.Item label="Total Reviews">
                    {review.hotel?.totalReviews || 0}
                  </Descriptions.Item>
                </Descriptions>
              </Space>
            </Card>

            {/* Booking Info */}
            {review.booking && (
              <Card title="Related Booking">
                <Descriptions column={1} size="small">
                  <Descriptions.Item label="Booking ID">
                    <Text code>{review.booking.bookingId}</Text>
                  </Descriptions.Item>
                  <Descriptions.Item label="Check-in Date">
                    {dayjs(review.booking.checkInDate).format('DD/MM/YYYY')}
                  </Descriptions.Item>
                  <Descriptions.Item label="Check-out Date">
                    {dayjs(review.booking.checkOutDate).format('DD/MM/YYYY')}
                  </Descriptions.Item>
                  <Descriptions.Item label="Room Type">
                    {review.booking.room?.type}
                  </Descriptions.Item>
                  <Descriptions.Item label="Booking Status">
                    <Tag color="success">{review.booking.status}</Tag>
                  </Descriptions.Item>
                </Descriptions>
              </Card>
            )}

            {/* Review Timeline */}
            <Card title="Review Timeline">
              <Timeline size="small">
                <Timeline.Item 
                  color="green"
                  dot={<CheckCircleOutlined />}
                >
                  <div>
                    <Text strong>Review Submitted</Text>
                    <br />
                    <Text type="secondary" style={{ fontSize: 12 }}>
                      {dayjs(review.createdAt).format('DD/MM/YYYY HH:mm')}
                    </Text>
                  </div>
                </Timeline.Item>
                
                {review.isApproved === true && (
                  <Timeline.Item 
                    color="blue"
                    dot={<CheckCircleOutlined />}
                  >
                    <div>
                      <Text strong>Review Approved</Text>
                      <br />
                      <Text type="secondary" style={{ fontSize: 12 }}>
                        {review.approvedAt ? 
                          dayjs(review.approvedAt).format('DD/MM/YYYY HH:mm') : 
                          'Approved'
                        }
                      </Text>
                    </div>
                  </Timeline.Item>
                )}
                
                {review.isApproved === false && (
                  <Timeline.Item 
                    color="red"
                    dot={<CloseCircleOutlined />}
                  >
                    <div>
                      <Text strong>Review Rejected</Text>
                      <br />
                      <Text type="secondary" style={{ fontSize: 12 }}>
                        {review.rejectedAt ? 
                          dayjs(review.rejectedAt).format('DD/MM/YYYY HH:mm') : 
                          'Rejected'
                        }
                      </Text>
                      {review.rejectionReason && (
                        <>
                          <br />
                          <Text type="secondary" style={{ fontSize: 11 }}>
                            Reason: {review.rejectionReason}
                          </Text>
                        </>
                      )}
                    </div>
                  </Timeline.Item>
                )}
                
                {review.updatedAt && review.updatedAt !== review.createdAt && (
                  <Timeline.Item color="gray">
                    <div>
                      <Text strong>Last Updated</Text>
                      <br />
                      <Text type="secondary" style={{ fontSize: 12 }}>
                        {dayjs(review.updatedAt).format('DD/MM/YYYY HH:mm')}
                      </Text>
                    </div>
                  </Timeline.Item>
                )}
              </Timeline>
            </Card>
          </Space>
        </Col>
      </Row>
    </div>
  );
};

export default ReviewDetail;
