import React, { useState, useEffect } from 'react';
import {
  Card,
  Table,
  Row,
  Col,
  Typography,
  Tag,
  Select,
  DatePicker,
  Button,
  Space,
  Statistic,
  Input,
  Modal,
  Descriptions,
  Tooltip,
  message,
} from 'antd';
import {
  SearchOutlined,
  EyeOutlined,
  DownloadOutlined,
  ReloadOutlined,
  CreditCardOutlined,
  DollarOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import dayjs from 'dayjs';
import { formatCurrency } from '../../utils/format';
import api from '../../services/api';

const { Title, Text } = Typography;
const { Option } = Select;
const { RangePicker } = DatePicker;

const Payments = () => {
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);
  const [payments, setPayments] = useState([]);
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [modalVisible, setModalVisible] = useState(false);
  const [filters, setFilters] = useState({
    search: '',
    status: null,
    method: null,
    dateRange: null,
  });

  const load = async () => {
    try {
      setLoading(true);
      // Fetch recent bookings, include paid and pending
      const { data } = await api.get('/admin/bookings', {
        params: { limit: 100 },
      });
      const items = (data.bookings || []).map((b) => ({
        id: b.transactionId || b.paymentDetails?.vnp_TransactionNo || b._id,
        bookingId: b.bookingNumber || b._id,
        amount: b.totalAmount,
        currency: b.currency || 'VND',
        status: mapPaymentStatus(b.paymentStatus),
        method: mapPaymentMethod(b.paymentMethod),
        gatewayTransactionId: b.paymentDetails?.vnp_TransactionNo || b.transactionId,
        customerName: `${b.customer?.firstName || ''} ${b.customer?.lastName || ''}`.trim(),
        customerEmail: b.customer?.email,
        hotelName: b.hotel?.name,
        createdAt: b.createdAt,
        completedAt: b.paidAt || null,
        refundedAmount: b.paymentStatus === 'refunded' ? (b.refundAmount || 0) : 0,
      }));
      setPayments(items);
    } catch (e) {
      message.error(e?.response?.data?.message || 'Failed to load payments');
    } finally {
      setLoading(false);
    }
  };

  // Load payments from bookings as there is no dedicated payments list endpoint
  useEffect(() => {
    load();
  }, []);

  const mapPaymentStatus = (status) => {
    switch (status) {
      case 'paid':
        return 'completed';
      case 'pending':
        return 'pending';
      case 'failed':
        return 'failed';
      case 'refunded':
        return 'refunded';
      default:
        return 'pending';
    }
  };

  const mapPaymentMethod = (method) => {
    switch (method) {
      case 'vnpay':
        return 'e_wallet';
      case 'stripe':
        return 'credit_card';
      case 'cash':
        return 'cash';
      default:
        return 'credit_card';
    }
  };

  const getStatusTag = (status) => {
    const statusConfig = {
      completed: { color: 'green', icon: <CheckCircleOutlined />, text: t('paymentsManagement.paymentStatus.completed') },
      pending: { color: 'orange', icon: <ClockCircleOutlined />, text: t('paymentsManagement.paymentStatus.pending') },
      failed: { color: 'red', icon: <CloseCircleOutlined />, text: t('paymentsManagement.paymentStatus.failed') },
      refunded: { color: 'purple', icon: <ReloadOutlined />, text: t('paymentsManagement.paymentStatus.refunded') },
    };

    const config = statusConfig[status] || statusConfig.pending;
    return (
      <Tag color={config.color} icon={config.icon}>
        {config.text}
      </Tag>
    );
  };

  const getMethodTag = (method) => {
    const methodConfig = {
      credit_card: { color: 'blue', text: t('paymentsManagement.paymentMethod.creditCard') },
      bank_transfer: { color: 'green', text: t('paymentsManagement.paymentMethod.bankTransfer') },
      e_wallet: { color: 'purple', text: t('paymentsManagement.paymentMethod.eWallet') },
      cash: { color: 'gray', text: t('paymentsManagement.paymentMethod.cash') },
    };

    const config = methodConfig[method] || methodConfig.credit_card;
    return <Tag color={config.color}>{config.text}</Tag>;
  };

  const columns = [
    {
      title: t('paymentsManagement.paymentId'),
      dataIndex: 'id',
      key: 'id',
      render: (text) => <Text copyable>{text}</Text>,
    },
    {
      title: t('paymentsManagement.booking'),
      dataIndex: 'bookingId',
      key: 'bookingId',
      render: (text, record) => (
        <div>
          <div><Text strong>{text}</Text></div>
          <div><Text type="secondary">{record.hotelName}</Text></div>
        </div>
      ),
    },
    {
      title: t('paymentsManagement.customer'),
      dataIndex: 'customerName',
      key: 'customer',
      render: (text, record) => (
        <div>
          <div>{text}</div>
          <div><Text type="secondary">{record.customerEmail}</Text></div>
        </div>
      ),
    },
    {
      title: t('paymentsManagement.amount'),
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, record) => (
        <div>
          <div><Text strong>{formatCurrency(amount)}</Text></div>
          {record.refundedAmount > 0 && (
            <div><Text type="danger">-{formatCurrency(record.refundedAmount)}</Text></div>
          )}
        </div>
      ),
    },
    {
      title: t('paymentsManagement.method'),
      dataIndex: 'method',
      key: 'method',
      render: getMethodTag,
    },
    {
      title: t('paymentsManagement.status'),
      dataIndex: 'status',
      key: 'status',
      render: getStatusTag,
    },
    {
      title: t('paymentsManagement.date'),
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (date) => dayjs(date).format('DD/MM/YYYY HH:mm'),
    },
    {
      title: t('common.actions'),
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Tooltip title={t('common.view')}>
            <Button
              icon={<EyeOutlined />}
              onClick={() => {
                setSelectedPayment(record);
                setModalVisible(true);
              }}
            />
          </Tooltip>
        </Space>
      ),
    },
  ];

  const handleSearch = (value) => {
    setFilters({ ...filters, search: value });
  };

  const handleStatusFilter = (status) => {
    setFilters({ ...filters, status });
  };

  const handleMethodFilter = (method) => {
    setFilters({ ...filters, method });
  };

  const handleDateRangeFilter = (dates) => {
    setFilters({ ...filters, dateRange: dates });
  };

  const filteredPayments = payments.filter(payment => {
    const q = (filters.search || '').toString().toLowerCase();
    const idStr = (payment.id || '').toString().toLowerCase();
    const nameStr = (payment.customerName || '').toLowerCase();
    const emailStr = (payment.customerEmail || '').toLowerCase();

    const matchesSearch = !filters.search ||
      idStr.includes(q) ||
      nameStr.includes(q) ||
      emailStr.includes(q);

    const matchesStatus = !filters.status || payment.status === filters.status;
    const matchesMethod = !filters.method || payment.method === filters.method;

    const created = dayjs(payment.createdAt);
    const matchesDateRange = !filters.dateRange || (
      created.isSame(filters.dateRange[0], 'day') || created.isAfter(filters.dateRange[0])
    ) && (
      created.isSame(filters.dateRange[1], 'day') || created.isBefore(filters.dateRange[1])
    );

    return matchesSearch && matchesStatus && matchesMethod && matchesDateRange;
  });

  // Calculate statistics
  const stats = {
    totalPayments: payments.length,
    completedPayments: payments.filter(p => p.status === 'completed').length,
    totalAmount: payments.filter(p => p.status === 'completed').reduce((sum, p) => sum + p.amount, 0),
    refundedAmount: payments.reduce((sum, p) => sum + p.refundedAmount, 0),
  };

  return (
    <div>
      {/* Header */}
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Title level={2}>
            <CreditCardOutlined /> {t('paymentsManagement.title')}
          </Title>
        </Col>
        <Col>
          <Space>
            <Button icon={<DownloadOutlined />}>
              {t('common.export')}
            </Button>
            <Button 
              type="primary" 
              icon={<ReloadOutlined />}
              onClick={load}
              loading={loading}
            >
              {t('common.refresh')}
            </Button>
          </Space>
        </Col>
      </Row>

      {/* Statistics */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('paymentsManagement.stats.totalPayments')}
              value={stats.totalPayments}
              prefix={<CreditCardOutlined />}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('paymentsManagement.stats.completedPayments')}
              value={stats.completedPayments}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: '#3f8600' }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('paymentsManagement.stats.totalAmount')}
              value={stats.totalAmount}
              formatter={formatCurrency}
              prefix={<DollarOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            <Statistic
              title={t('paymentsManagement.stats.refundedAmount')}
              value={stats.refundedAmount}
              formatter={formatCurrency}
              prefix={<ReloadOutlined />}
              valueStyle={{ color: '#cf1322' }}
            />
          </Card>
        </Col>
      </Row>

      {/* Filters */}
      <Card style={{ marginBottom: 24 }}>
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={8} md={6}>
            <Input
              placeholder={t('paymentsManagement.searchPlaceholder')}
              prefix={<SearchOutlined />}
              value={filters.search}
              onChange={(e) => handleSearch(e.target.value)}
            />
          </Col>
          <Col xs={24} sm={8} md={4}>
            <Select
              placeholder={t('paymentsManagement.filterByStatus')}
              value={filters.status}
              onChange={handleStatusFilter}
              style={{ width: '100%' }}
              allowClear
            >
              <Option value="completed">{t('paymentsManagement.paymentStatus.completed')}</Option>
              <Option value="pending">{t('paymentsManagement.paymentStatus.pending')}</Option>
              <Option value="failed">{t('paymentsManagement.paymentStatus.failed')}</Option>
              <Option value="refunded">{t('paymentsManagement.paymentStatus.refunded')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={8} md={4}>
            <Select
              placeholder={t('paymentsManagement.filterByMethod')}
              value={filters.method}
              onChange={handleMethodFilter}
              style={{ width: '100%' }}
              allowClear
            >
              <Option value="credit_card">{t('paymentsManagement.paymentMethod.creditCard')}</Option>
              <Option value="e_wallet">{t('paymentsManagement.paymentMethod.eWallet')}</Option>
              <Option value="cash">{t('paymentsManagement.paymentMethod.cash')}</Option>
            </Select>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <RangePicker
              placeholder={[t('common.startDate'), t('common.endDate')]}
              value={filters.dateRange}
              onChange={handleDateRangeFilter}
              style={{ width: '100%' }}
            />
          </Col>
        </Row>
      </Card>

      {/* Payments Table */}
      <Card>
        <Table
          columns={columns}
          dataSource={filteredPayments}
          rowKey="id"
          loading={loading}
          pagination={{
            total: filteredPayments.length,
            pageSize: 10,
            showSizeChanger: true,
            showQuickJumper: true,
            showTotal: (total, range) =>
              t('common.pagination.total', { 
                start: range[0], 
                end: range[1], 
                total 
              }),
          }}
        />
      </Card>

      {/* Payment Detail Modal */}
      <Modal
        title={t('paymentsManagement.paymentDetails')}
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        footer={[
          <Button key="close" onClick={() => setModalVisible(false)}>
            {t('common.close')}
          </Button>,
        ]}
        width={600}
      >
        {selectedPayment && (
          <Descriptions column={2} bordered>
            <Descriptions.Item label={t('paymentsManagement.paymentId')} span={2}>
              <Text copyable>{selectedPayment.id}</Text>
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.booking')}>
              {selectedPayment.bookingId}
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.status')}>
              {getStatusTag(selectedPayment.status)}
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.amount')}>
              {formatCurrency(selectedPayment.amount)}
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.method')}>
              {getMethodTag(selectedPayment.method)}
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.customer')} span={2}>
              <div>
                <div>{selectedPayment.customerName}</div>
                <div><Text type="secondary">{selectedPayment.customerEmail}</Text></div>
              </div>
            </Descriptions.Item>
            <Descriptions.Item label={t('hotels.name')} span={2}>
              {selectedPayment.hotelName}
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.gatewayTransactionId')} span={2}>
              <Text copyable>{selectedPayment.gatewayTransactionId}</Text>
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.createdAt')}>
              {dayjs(selectedPayment.createdAt).format('DD/MM/YYYY HH:mm:ss')}
            </Descriptions.Item>
            <Descriptions.Item label={t('paymentsManagement.completedAt')}>
              {selectedPayment.completedAt 
                ? dayjs(selectedPayment.completedAt).format('DD/MM/YYYY HH:mm:ss')
                : '-'
              }
            </Descriptions.Item>
            {selectedPayment.refundedAmount > 0 && (
              <Descriptions.Item label={t('paymentsManagement.refundedAmount')} span={2}>
                <Text type="danger">{formatCurrency(selectedPayment.refundedAmount)}</Text>
              </Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Modal>
    </div>
  );
};

export default Payments;
