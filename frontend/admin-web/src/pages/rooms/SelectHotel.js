import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { Card, Table, Button, Typography } from 'antd';
import { useTranslation } from 'react-i18next';
import { fetchHotels } from '../../store/slices/hotelSlice';

const { Title } = Typography;

const SelectHotel = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { hotels, loading } = useSelector((s) => s.hotels);

  useEffect(() => {
    dispatch(fetchHotels({ page: 1, limit: 100 }));
  }, [dispatch]);

  const columns = [
    { title: t('hotels.hotelName'), dataIndex: 'name', key: 'name' },
    { title: t('hotels.owner'), key: 'owner', render: (_, r) => `${r.owner?.firstName || ''} ${r.owner?.lastName || ''}` },
    { title: t('common.actions'), key: 'actions', render: (_, r) => (
      <Button type="primary" onClick={() => navigate(`/rooms/${r._id}`)}>
        {t('rooms.manageRooms')}
      </Button>
    )},
  ];

  return (
    <div>
      <Title level={3}>{t('rooms.selectHotel')}</Title>
      <Card>
        <Table
          columns={columns}
          dataSource={hotels}
          rowKey="_id"
          loading={loading}
          pagination={{ pageSize: 10 }}
        />
      </Card>
    </div>
  );
};

export default SelectHotel;

