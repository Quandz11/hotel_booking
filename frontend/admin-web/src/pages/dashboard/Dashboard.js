import React, { useEffect } from 'react';
import { Row, Col, Card, Statistic, Typography, Table, Tag, Space, Progress, Button } from 'antd';
import {
  HomeOutlined,
  UserOutlined,
  CalendarOutlined,
  DollarOutlined,
  ArrowUpOutlined,
  ArrowDownOutlined,
  GlobalOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { fetchDashboardStats } from '../../store/slices/dashboardSlice';

const { Title, Text } = Typography;

const Dashboard = () => {
  const dispatch = useDispatch();
  const { stats, loading } = useSelector((state) => state.dashboard);
  const { t, i18n } = useTranslation();

  useEffect(() => {
    dispatch(fetchDashboardStats());
  }, [dispatch]);

  const { overview, recent, bookingStats, monthlyRevenue, topHotels } = stats;

  const handleLanguageToggle = () => {
    const nextLanguage = i18n.language === 'vi' ? 'en' : 'vi';
    i18n.changeLanguage(nextLanguage);
    localStorage.setItem('language', nextLanguage);
  };

  const languageButtonLabel =
    i18n.language === 'vi' ? 'Switch to English' : 'Switch to Vietnamese';

  // Format number with K, M suffix
  const formatNumber = (num) => {
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + 'M';
    }
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'K';
    }
    return num?.toString();
  };

  // Overview cards data
  const overviewCards = [
    {
      title: t('dashboard.totalHotels'),
      value: overview?.totalHotels || 0,
      icon: <HomeOutlined style={{ color: '#1890ff' }} />,
      color: '#1890ff',
      change: recent?.newHotels || 0,
    },
    {
      title: t('dashboard.totalUsers'),
      value: overview?.totalUsers || 0,
      icon: <UserOutlined style={{ color: '#52c41a' }} />,
      color: '#52c41a',
      change: recent?.newUsers || 0,
    },
    {
      title: t('dashboard.totalBookings'),
      value: overview?.totalBookings || 0,
      icon: <CalendarOutlined style={{ color: '#faad14' }} />,
      color: '#faad14',
      change: recent?.newBookings || 0,
    },
    {
      title: t('dashboard.totalRevenue'),
      value: formatNumber(recent?.revenue || 0),
      icon: <DollarOutlined style={{ color: '#f5222d' }} />,
      color: '#f5222d',
      suffix: '$',
      change: 15.3,
    },
  ];

  // Booking status colors
  const statusColors = {
    confirmed: '#52c41a',
    pending: '#faad14',
    cancelled: '#f5222d',
    checked_in: '#1890ff',
    checked_out: '#722ed1',
  };

  // Top hotels table columns
  const hotelColumns = [
    {
      title: t('hotels.hotelName'),
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: t('dashboard.totalRevenue'),
      dataIndex: 'totalRevenue',
      key: 'totalRevenue',
      render: (value) => `$${formatNumber(value)}`,
    },
    {
      title: t('dashboard.totalBookings'),
      dataIndex: 'totalBookings',
      key: 'totalBookings',
    },
    {
      title: t('hotels.averageRating'),
      dataIndex: 'averageRating',
      key: 'averageRating',
      render: (value) => (
        <Space>
          <span>{value?.toFixed(1)}</span>
          <Progress
            percent={(value / 5) * 100}
            showInfo={false}
            size="small"
            strokeColor="#faad14"
          />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Title level={2} style={{ marginBottom: 0 }}>
            {t('dashboard.title')}
          </Title>
        </Col>
        <Col>
          <Button icon={<GlobalOutlined />} onClick={handleLanguageToggle}>
            {languageButtonLabel}
          </Button>
        </Col>
      </Row>

      {/* Overview Cards */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        {overviewCards.map((card, index) => (
          <Col xs={24} sm={12} lg={6} key={index}>
            <Card className="dashboard-card">
              <Statistic
                title={card.title}
                value={card.value}
                prefix={card.icon}
                suffix={card.suffix}
                valueStyle={{ color: card.color }}
              />
              <div style={{ marginTop: 16, display: 'flex', alignItems: 'center' }}>
                {card.change > 0 ? (
                  <ArrowUpOutlined style={{ color: '#52c41a', marginRight: 4 }} />
                ) : (
                  <ArrowDownOutlined style={{ color: '#f5222d', marginRight: 4 }} />
                )}
                <Text type={card.change > 0 ? 'success' : 'danger'}>
                  {Math.abs(card.change)} this month
                </Text>
              </div>
            </Card>
          </Col>
        ))}
      </Row>

      <Row gutter={[16, 16]}>
        {/* Monthly Revenue Chart */}
        <Col xs={24} lg={16}>
          <Card title={t('dashboard.revenueGrowth')} className="dashboard-card">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={monthlyRevenue}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="_id" 
                  tickFormatter={(value) => `${value.month}/${value.year}`}
                />
                <YAxis tickFormatter={formatNumber} />
                <Tooltip 
                  formatter={(value) => [`$${formatNumber(value)}`, 'Revenue']}
                  labelFormatter={(value) => `${value.month}/${value.year}`}
                />
                <Legend />
                <Line 
                  type="monotone" 
                  dataKey="revenue" 
                  stroke="#1890ff" 
                  strokeWidth={2}
                  dot={{ fill: '#1890ff' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </Card>
        </Col>

        {/* Booking Status Pie Chart */}
        <Col xs={24} lg={8}>
          <Card title={t('dashboard.bookingTrends')} className="dashboard-card">
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={bookingStats}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="count"
                  nameKey="_id"
                >
                  {bookingStats?.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={statusColors[entry._id] || '#8884d8'} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        {/* Top Performing Hotels */}
        <Col xs={24} lg={12}>
          <Card title={t('dashboard.topPerformingHotels')} className="dashboard-card">
            <Table
              dataSource={topHotels}
              columns={hotelColumns}
              pagination={false}
              size="small"
              rowKey="_id"
              loading={loading}
            />
          </Card>
        </Col>

        {/* Recent Activity */}
        <Col xs={24} lg={12}>
          <Card title={t('dashboard.recentActivity')} className="dashboard-card">
            <div style={{ marginBottom: 16 }}>
              <Row justify="space-between">
                <Text strong>{t('dashboard.pendingApprovals')}</Text>
                <Tag color="orange">{overview?.pendingHotels || 0}</Tag>
              </Row>
            </div>
            <div style={{ marginBottom: 16 }}>
              <Row justify="space-between">
                <Text strong>{t('dashboard.newRegistrations')}</Text>
                <Tag color="blue">{recent?.newUsers || 0}</Tag>
              </Row>
            </div>
            <div style={{ marginBottom: 16 }}>
              <Row justify="space-between">
                <Text strong>{t('reports.overview.activeHotels')}</Text>
                <Tag color="green">{overview?.approvedHotels || 0}</Tag>
              </Row>
            </div>
            <div>
              <Row justify="space-between">
                <Text strong>{t('hotels.totalRooms')}</Text>
                <Tag color="purple">{overview?.totalRooms || 0}</Tag>
              </Row>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default Dashboard;
