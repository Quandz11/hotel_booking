import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate, useParams } from 'react-router-dom';
import { Card, Table, Button, Tag, Typography, Space, Tooltip, Input, Select, Row, Col, InputNumber } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { fetchRoomsByHotel, deleteRoom } from '../../store/slices/roomSlice';
import { formatCurrency } from '../../utils/format';
import { useTranslation } from 'react-i18next';

const { Title, Text } = Typography;

const RoomList = () => {
  const { id: hotelId } = useParams();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { rooms, loading } = useSelector((s) => s.rooms);
  const [filters, setFilters] = React.useState({ search: '', status: true, type: null, minPrice: null, maxPrice: null });

  useEffect(() => {
    if (hotelId) dispatch(fetchRoomsByHotel(hotelId));
  }, [dispatch, hotelId]);

  const handleDelete = async (room) => {
    await dispatch(deleteRoom(room._id));
  };

  const filteredRooms = rooms.filter((r) => {
    const q = (filters.search || '').toLowerCase();
    const matchesSearch = !filters.search || (r.name || '').toLowerCase().includes(q);
    const matchesStatus = filters.status === null || r.isActive === filters.status;
    const matchesType = !filters.type || r.type === filters.type;
    const price = r.basePrice || 0;
    const matchesMin = filters.minPrice == null || price >= filters.minPrice;
    const matchesMax = filters.maxPrice == null || price <= filters.maxPrice;
    return matchesSearch && matchesStatus && matchesType && matchesMin && matchesMax;
  });

  const columns = [
    { title: t('rooms.name'), dataIndex: 'name', key: 'name' },
    { title: t('rooms.type'), dataIndex: 'type', key: 'type' },
    { title: t('rooms.maxGuests'), dataIndex: 'maxGuests', key: 'maxGuests', width: 100 },
    { title: t('rooms.beds'), key: 'beds', render: (_, r) => `${r.bedCount} ${r.bedType}` },
    { title: t('rooms.basePrice'), dataIndex: 'basePrice', key: 'basePrice', render: (v) => formatCurrency(v), width: 120 },
    { title: t('rooms.weekendPrice'), dataIndex: 'weekendPrice', key: 'weekendPrice', render: (v) => formatCurrency(v), width: 140 },
    { title: t('rooms.totalRooms'), dataIndex: 'totalRooms', key: 'totalRooms', width: 110 },
    { title: t('rooms.status'), dataIndex: 'isActive', key: 'isActive', width: 100, render: (v) => <Tag color={v ? 'green' : 'default'}>{v ? t('rooms.active') : t('rooms.inactive')}</Tag> },
    { title: t('common.actions'), key: 'actions', width: 120,
      render: (_, r) => (
        <Space>
          <Tooltip title={t('common.edit')}>
            <Button size="small" icon={<EditOutlined />} onClick={() => navigate(`/hotels/${hotelId}/rooms/${r._id}/edit`)} />
          </Tooltip>
          <Tooltip title={t('common.delete')}>
            <Button size="small" danger icon={<DeleteOutlined />} onClick={() => handleDelete(r)} />
          </Tooltip>
        </Space>
      )
    }
  ];

  return (
    <div>
      <Space style={{ width: '100%', justifyContent: 'space-between', marginBottom: 16 }}>
        <Title level={3}>{t('rooms.title')}</Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate(`/hotels/${hotelId}/rooms/new`)}>{t('rooms.addRoom')}</Button>
      </Space>
      <Card style={{ marginBottom: 16 }}>
        <Row gutter={[16, 16]}>
          <Col xs={24} md={8}>
            <Input
              placeholder={t('rooms.searchPlaceholder') || t('common.search')}
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            />
          </Col>
          <Col xs={24} md={5}>
            <Select
              placeholder={t('rooms.filter.type') || t('rooms.type')}
              value={filters.type}
              allowClear
              style={{ width: '100%' }}
              onChange={(value) => setFilters({ ...filters, type: value })}
            >
              {['standard','deluxe','suite','executive','presidential'].map(val => (
                <Select.Option key={val} value={val}>{val}</Select.Option>
              ))}
            </Select>
          </Col>
          <Col xs={24} md={5}>
            <Select
              placeholder={t('rooms.filter.status') || t('rooms.status')}
              value={filters.status}
              allowClear
              style={{ width: '100%' }}
              onChange={(value) => setFilters({ ...filters, status: value })}
            >
              <Select.Option value={true}>{t('rooms.active')}</Select.Option>
              <Select.Option value={false}>{t('rooms.inactive')}</Select.Option>
            </Select>
          </Col>
          <Col xs={24} md={3}>
            <InputNumber
              min={0}
              placeholder={t('rooms.filter.minPrice') || 'Min'}
              value={filters.minPrice}
              style={{ width: '100%' }}
              onChange={(v) => setFilters({ ...filters, minPrice: v })}
            />
          </Col>
          <Col xs={24} md={3}>
            <InputNumber
              min={0}
              placeholder={t('rooms.filter.maxPrice') || 'Max'}
              value={filters.maxPrice}
              style={{ width: '100%' }}
              onChange={(v) => setFilters({ ...filters, maxPrice: v })}
            />
          </Col>
        </Row>
      </Card>
      <Card>
        <Table
          columns={columns}
          dataSource={filteredRooms}
          rowKey="_id"
          loading={loading}
          pagination={{ pageSize: 10 }}
        />
      </Card>
    </div>
  );
};

export default RoomList;
