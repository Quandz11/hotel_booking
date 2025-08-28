import React, { useState, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Typography,
  Select,
  DatePicker,
  Button,
  Space,
  Statistic,
  Table,
  Tabs,
  Progress,
  Tag,
} from 'antd';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
} from 'recharts';
import {
  DownloadOutlined,
  CalendarOutlined,
  DollarOutlined,
  UserOutlined,
  HomeOutlined,
  StarOutlined,
  LineChartOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { 
  fetchRevenueReport,
  fetchBookingReport,
  fetchUserReport,
  fetchHotelReport,
  exportReport 
} from '../../store/slices/reportSlice';
import { formatCurrency } from '../../utils/format';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { Option } = Select;
const { RangePicker } = DatePicker;
const { TabPane } = Tabs;

const Reports = () => {
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { 
    revenueReport,
    bookingReport,
    userReport,
    hotelReport,
    loading 
  } = useSelector((state) => state.reports);

  // Extract data for easier use
  const overview = {
    totalRevenue: revenueReport.summary?.totalRevenue || 0,
    totalBookings: revenueReport.summary?.totalBookings || 0,
    activeHotels: hotelReport.summary?.activeHotels || 0,
    newUsers: userReport.summary?.newUsers || 0,
    revenueGrowth: revenueReport.summary?.growth || 0,
    bookingGrowth: 0, // TODO: Calculate
    hotelGrowth: hotelReport.summary?.totalHotels || 0,
    userGrowth: userReport.summary?.growth || 0
  };

  const revenue = {
    chartData: revenueReport.data || [],
    dailyAverage: revenueReport.summary?.averageBookingValue || 0,
    peakDay: { amount: 0 } // TODO: Calculate from data
  };

  const bookings = {
    confirmed: bookingReport.summary?.confirmedBookings || 0,
    pending: bookingReport.summary?.pendingBookings || 0,
    cancelled: bookingReport.summary?.cancelledBookings || 0,
    completed: 0 // TODO: Add completed status
  };

  const hotels = {
    topHotels: hotelReport.data || [],
    summary: hotelReport.summary || {}
  };

  const users = {
    topUsers: userReport.data || [],
    summary: userReport.summary || {}
  };

  const reviews = {
    topReviews: [],
    summary: { totalReviews: 0, averageRating: 0 }
  };

  const [dateRange, setDateRange] = useState([
    dayjs().subtract(30, 'day'),
    dayjs()
  ]);
  const [reportType, setReportType] = useState('overview');

  useEffect(() => {
    const params = {
      startDate: dateRange[0].toISOString(),
      endDate: dateRange[1].toISOString(),
    };
    
    dispatch(fetchRevenueReport(params));
    dispatch(fetchBookingReport(params));
    dispatch(fetchUserReport(params));
    dispatch(fetchHotelReport(params));
  }, [dispatch, dateRange, reportType]);

  const handleDateRangeChange = (dates) => {
    if (dates && dates.length === 2) {
      setDateRange(dates);
    }
  };

  const handleExport = (type) => {
    const params = {
      startDate: dateRange[0].toISOString(),
      endDate: dateRange[1].toISOString(),
      type,
      format: 'excel'
    };
    dispatch(exportReport(params));
  };

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

  // Revenue Chart Data
  const revenueChartData = revenue?.chartData || [];
  
  // Booking Status Distribution
  const bookingStatusData = [
    { name: 'Confirmed', value: bookings?.confirmed || 0, color: '#52c41a' },
    { name: 'Pending', value: bookings?.pending || 0, color: '#faad14' },
    { name: 'Cancelled', value: bookings?.cancelled || 0, color: '#f5222d' },
    { name: 'Completed', value: bookings?.completed || 0, color: '#1890ff' },
  ];

  // Top Hotels Data
  const topHotelsColumns = [
    {
      title: 'Hotel Name',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: 'Bookings',
      dataIndex: 'bookings',
      key: 'bookings',
      sorter: true,
    },
    {
      title: 'Revenue',
      dataIndex: 'revenue',
      key: 'revenue',
      render: (value) => formatCurrency(value),
      sorter: true,
    },
    {
      title: 'Rating',
      dataIndex: 'averageRating',
      key: 'rating',
      render: (value) => `${value?.toFixed(1) || '0.0'}★`,
    },
    {
      title: 'Occupancy',
      dataIndex: 'occupancyRate',
      key: 'occupancy',
      render: (value) => (
        <Progress 
          percent={value} 
          size="small" 
          format={percent => `${percent}%`}
        />
      ),
    },
  ];

  return (
    <div>
      {/* Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Title level={2}>{t('reports.title')}</Title>
        </Col>
        <Col>
          <Space>
            <RangePicker
              value={dateRange}
              onChange={handleDateRangeChange}
              format="DD/MM/YYYY"
            />
            <Select
              value={reportType}
              onChange={setReportType}
              style={{ width: 150 }}
            >
              <Option value="overview">Overview</Option>
              <Option value="revenue">Revenue</Option>
              <Option value="bookings">Bookings</Option>
              <Option value="hotels">Hotels</Option>
              <Option value="users">Users</Option>
            </Select>
            <Button 
              type="primary" 
              icon={<DownloadOutlined />}
              onClick={() => handleExport(reportType)}
            >
              Export
            </Button>
          </Space>
        </Col>
      </Row>

      {/* Overview Statistics */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('reports.overview.totalRevenue')}
              value={overview?.totalRevenue || 0}
              formatter={(value) => formatCurrency(value)}
              prefix={<DollarOutlined />}
              valueStyle={{ color: '#3f8600' }}
            />
            <div style={{ marginTop: 8 }}>
              <Text type={overview?.revenueGrowth >= 0 ? 'success' : 'danger'}>
                {overview?.revenueGrowth >= 0 ? '+' : ''}{overview?.revenueGrowth}% {t('reports.overview.vsLastPeriod')}
              </Text>
            </div>
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('reports.overview.totalBookings')}
              value={overview?.totalBookings || 0}
              prefix={<CalendarOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
            <div style={{ marginTop: 8 }}>
              <Text type={overview?.bookingGrowth >= 0 ? 'success' : 'danger'}>
                {overview?.bookingGrowth >= 0 ? '+' : ''}{overview?.bookingGrowth}% {t('reports.overview.vsLastPeriod')}
              </Text>
            </div>
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('reports.overview.activeHotels')}
              value={overview?.activeHotels || 0}
              prefix={<HomeOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
            <div style={{ marginTop: 8 }}>
              <Text type="secondary">
                {overview?.hotelGrowth || 0} {t('reports.overview.newThisPeriod')}
              </Text>
            </div>
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('reports.overview.newUsers')}
              value={overview?.newUsers || 0}
              prefix={<UserOutlined />}
              valueStyle={{ color: '#fa541c' }}
            />
            <div style={{ marginTop: 8 }}>
              <Text type={overview?.userGrowth >= 0 ? 'success' : 'danger'}>
                {overview?.userGrowth >= 0 ? '+' : ''}{overview?.userGrowth}% {t('reports.overview.vsLastPeriod')}
              </Text>
            </div>
          </Card>
        </Col>
      </Row>

      {/* Main Charts */}
      <Tabs defaultActiveKey="revenue">
        <TabPane tab="Revenue Analysis" key="revenue">
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={16}>
              <Card title="Revenue Trend" extra={<LineChartOutlined />}>
                <ResponsiveContainer width="100%" height={400}>
                  <AreaChart data={revenueChartData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis tickFormatter={(value) => formatCurrency(value)} />
                    <Tooltip 
                      formatter={(value) => [formatCurrency(value), 'Revenue']}
                      labelFormatter={(label) => `Date: ${label}`}
                    />
                    <Area 
                      type="monotone" 
                      dataKey="revenue" 
                      stroke="#1890ff" 
                      fill="#1890ff" 
                      fillOpacity={0.3}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24} lg={8}>
              <Card title="Revenue Distribution">
                <Row gutter={[16, 16]}>
                  <Col span={24}>
                    <Statistic
                      title="Daily Average"
                      value={revenue?.dailyAverage || 0}
                      formatter={(value) => formatCurrency(value)}
                    />
                  </Col>
                  <Col span={24}>
                    <Statistic
                      title="Peak Day Revenue"
                      value={revenue?.peakDay?.amount || 0}
                      formatter={(value) => formatCurrency(value)}
                    />
                    <Text type="secondary">
                      {revenue?.peakDay?.date}
                    </Text>
                  </Col>
                  <Col span={24}>
                    <div>
                      <Text strong>Revenue Sources:</Text>
                      {revenue?.sources?.map((source, index) => (
                        <div key={index} style={{ marginTop: 8 }}>
                          <Text>{source.name}: </Text>
                          <Text strong>{formatCurrency(source.amount)}</Text>
                          <Progress 
                            percent={source.percentage} 
                            size="small" 
                            showInfo={false}
                            style={{ marginTop: 4 }}
                          />
                        </div>
                      ))}
                    </div>
                  </Col>
                </Row>
              </Card>
            </Col>
          </Row>
        </TabPane>

        <TabPane tab="Booking Analysis" key="bookings">
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={12}>
              <Card title="Booking Status Distribution">
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={bookingStatusData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {bookingStatusData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="Booking Trends">
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={bookings?.chartData || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="bookings" stroke="#1890ff" />
                    <Line type="monotone" dataKey="cancellations" stroke="#f5222d" />
                  </LineChart>
                </ResponsiveContainer>
              </Card>
            </Col>
          </Row>
        </TabPane>

        <TabPane tab="Hotel Performance" key="hotels">
          <Row gutter={[16, 16]}>
            <Col xs={24}>
              <Card title="Top Performing Hotels">
                <Table
                  columns={topHotelsColumns}
                  dataSource={hotels?.topHotels || []}
                  rowKey="id"
                  pagination={{ pageSize: 10 }}
                  loading={loading}
                />
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="Hotel Category Distribution">
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={hotels?.categoryData || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="category" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="count" fill="#1890ff" />
                  </BarChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="Average Occupancy Rate">
                <div style={{ padding: '20px 0' }}>
                  <Progress 
                    type="circle" 
                    percent={hotels?.averageOccupancy || 0}
                    size={180}
                    format={percent => (
                      <div style={{ textAlign: 'center' }}>
                        <div style={{ fontSize: 24, fontWeight: 'bold' }}>{percent}%</div>
                        <div style={{ fontSize: 12, color: '#666' }}>Occupancy</div>
                      </div>
                    )}
                  />
                </div>
                <Row gutter={16} style={{ marginTop: 20 }}>
                  <Col span={12}>
                    <Statistic
                      title="Best Performer"
                      value={`${hotels?.bestOccupancy?.rate || 0}%`}
                      valueStyle={{ color: '#3f8600' }}
                    />
                    <Text type="secondary">{hotels?.bestOccupancy?.hotel}</Text>
                  </Col>
                  <Col span={12}>
                    <Statistic
                      title="Needs Attention"
                      value={`${hotels?.worstOccupancy?.rate || 0}%`}
                      valueStyle={{ color: '#cf1322' }}
                    />
                    <Text type="secondary">{hotels?.worstOccupancy?.hotel}</Text>
                  </Col>
                </Row>
              </Card>
            </Col>
          </Row>
        </TabPane>

        <TabPane tab="User Analytics" key="users">
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={12}>
              <Card title="User Registration Trend">
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={users?.registrationData || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Area type="monotone" dataKey="registrations" stroke="#722ed1" fill="#722ed1" />
                  </AreaChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="User Role Distribution">
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={users?.roleData || []}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {(users?.roleData || []).map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24}>
              <Card title="User Activity Metrics">
                <Row gutter={[16, 16]}>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="Active Users (30d)"
                      value={users?.activeUsers || 0}
                      valueStyle={{ color: '#1890ff' }}
                    />
                  </Col>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="New Registrations"
                      value={users?.newRegistrations || 0}
                      valueStyle={{ color: '#52c41a' }}
                    />
                  </Col>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="Avg. Session Duration"
                      value={`${users?.avgSessionDuration || 0}m`}
                      valueStyle={{ color: '#722ed1' }}
                    />
                  </Col>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="Return Rate"
                      value={`${users?.returnRate || 0}%`}
                      valueStyle={{ color: '#fa541c' }}
                    />
                  </Col>
                </Row>
              </Card>
            </Col>
          </Row>
        </TabPane>

        <TabPane tab="Review Analytics" key="reviews">
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={12}>
              <Card title="Review Rating Distribution">
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={reviews?.ratingData || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="rating" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="count" fill="#faad14" />
                  </BarChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card title="Review Timeline">
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={reviews?.timelineData || []}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Line type="monotone" dataKey="reviews" stroke="#1890ff" />
                    <Line type="monotone" dataKey="averageRating" stroke="#52c41a" />
                  </LineChart>
                </ResponsiveContainer>
              </Card>
            </Col>
            <Col xs={24}>
              <Card title="Review Statistics">
                <Row gutter={[16, 16]}>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="Total Reviews"
                      value={reviews?.total || 0}
                      prefix={<StarOutlined />}
                    />
                  </Col>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="Average Rating"
                      value={reviews?.averageRating || 0}
                      precision={1}
                      suffix="/ 5"
                      valueStyle={{ color: '#faad14' }}
                    />
                  </Col>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="Response Rate"
                      value={`${reviews?.responseRate || 0}%`}
                      valueStyle={{ color: '#1890ff' }}
                    />
                  </Col>
                  <Col xs={12} sm={6}>
                    <Statistic
                      title="Avg. Response Time"
                      value={`${reviews?.avgResponseTime || 0}h`}
                      valueStyle={{ color: '#722ed1' }}
                    />
                  </Col>
                </Row>
              </Card>
            </Col>
          </Row>
        </TabPane>
      </Tabs>
    </div>
  );
};

export default Reports;
