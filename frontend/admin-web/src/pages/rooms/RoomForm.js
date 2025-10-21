import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigate, useParams } from 'react-router-dom';
import { Form, Card, Row, Col, Input, Select, InputNumber, Button, Switch, Space, message, Upload } from 'antd';
import { SaveOutlined, UploadOutlined } from '@ant-design/icons';
import { createRoom, updateRoom, fetchRoomsByHotel } from '../../store/slices/roomSlice';
import { showFormErrors } from '../../utils/apiError';
import { useTranslation } from 'react-i18next';

const { Option } = Select;

const RoomForm = () => {
  const { id: hotelId, roomId } = useParams();
  const isEdit = !!roomId;
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [form] = Form.useForm();
  const { t } = useTranslation();
  const { rooms, loading } = useSelector((s) => s.rooms);
  const [fileList, setFileList] = useState([]);

  useEffect(() => {
    if (hotelId) dispatch(fetchRoomsByHotel(hotelId));
  }, [dispatch, hotelId]);

  useEffect(() => {
    if (isEdit) {
      const room = rooms.find(r => r._id === roomId);
      if (room) {
        form.setFieldsValue({
          hotel: room.hotel?._id || hotelId,
          name: room.name,
          type: room.type,
          description: room.description,
          maxGuests: room.maxGuests,
          bedType: room.bedType,
          bedCount: room.bedCount,
          basePrice: room.basePrice,
          weekendPrice: room.weekendPrice,
          currency: room.currency || 'VND',
          totalRooms: room.totalRooms,
          discountPercentage: room.discountPercentage || 0,
          specialOfferDescription: room.specialOfferDescription,
          isActive: room.isActive,
          amenities: room.amenities || [],
        });
        if (Array.isArray(room.images)) {
          setFileList(room.images.map((img, index) => ({
            uid: `${index}`,
            name: `image-${index}`,
            status: 'done',
            url: img.url,
          })));
        }
      }
    } else {
      form.setFieldsValue({ hotel: hotelId, currency: 'VND', isActive: true });
    }
  }, [isEdit, roomId, rooms, hotelId, form]);

  const onSubmit = async (values) => {
    try {
      const payload = { ...values, hotel: values.hotel || hotelId };
      // Map images from upload list
      const images = (fileList || [])
        .filter(f => f.status === 'done')
        .map(f => ({ url: f.url || f.response?.image?.url, publicId: f.response?.image?.publicId }))
        .filter(img => !!img.url);
      if (images.length) payload.images = images;
      if (isEdit) {
        await dispatch(updateRoom({ id: roomId, data: payload })).unwrap();
        message.success(t('rooms.updateSuccess'));
      } else {
        await dispatch(createRoom(payload)).unwrap();
        message.success(t('rooms.createSuccess'));
      }
      navigate(`/hotels/${hotelId}/rooms`);
    } catch (error) {
      showFormErrors(form, error, t('errors.validationError'));
    }
  };

  return (
    <Card title={isEdit ? t('rooms.editRoom') : t('rooms.addRoom')}>
      <Form form={form} layout="vertical" onFinish={onSubmit} initialValues={{ hotel: hotelId, currency: 'VND', isActive: true }}>
        <Row gutter={16}>
          <Col xs={24} md={12}>
            <Form.Item name="name" label={t('rooms.name')} rules={[{ required: true, message: t('validation.required') }]}>
              <Input placeholder={t('rooms.name')} />
            </Form.Item>
          </Col>
          <Col xs={24} md={12}>
            <Form.Item name="type" label={t('rooms.type')} rules={[{ required: true, message: t('validation.required') }]}>
              <Select placeholder={t('rooms.type')}>
                <Option value="standard">Standard</Option>
                <Option value="deluxe">Deluxe</Option>
                <Option value="suite">Suite</Option>
                <Option value="executive">Executive</Option>
                <Option value="presidential">Presidential</Option>
              </Select>
            </Form.Item>
          </Col>
        </Row>

        <Form.Item label={t('rooms.images')}>
          <Upload
            name="image"
            action="/api/upload/image"
            listType="picture-card"
            fileList={fileList}
            headers={{ Authorization: `Bearer ${localStorage.getItem('token') || ''}` }}
            onChange={({ file, fileList: fl }) => {
              // Map response url for preview
              const mapped = fl.map((f) => {
                const url = f.url || f.response?.image?.url;
                return url ? { ...f, url } : f;
              });
              setFileList(mapped);
            }}
          >
            <Button icon={<UploadOutlined />}>{t('rooms.uploadImages') || t('common.add')}</Button>
          </Upload>
        </Form.Item>

        <Form.Item name="description" label={t('rooms.description')}>
          <Input.TextArea rows={3} placeholder={t('rooms.description')} />
        </Form.Item>

        <Row gutter={16}>
          <Col xs={24} md={6}>
            <Form.Item name="maxGuests" label={t('rooms.maxGuests')} rules={[{ required: true, message: t('validation.required') }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
          <Col xs={24} md={6}>
            <Form.Item name="bedType" label={t('rooms.bedType')} rules={[{ required: true, message: t('validation.required') }]}>
              <Select>
                <Option value="single">Single</Option>
                <Option value="double">Double</Option>
                <Option value="queen">Queen</Option>
                <Option value="king">King</Option>
                <Option value="twin">Twin</Option>
              </Select>
            </Form.Item>
          </Col>
          <Col xs={24} md={6}>
            <Form.Item name="bedCount" label={t('rooms.bedCount')} rules={[{ required: true, message: t('validation.required') }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
          <Col xs={24} md={6}>
            <Form.Item name="totalRooms" label={t('rooms.totalRooms')} rules={[{ required: true, message: t('validation.required') }]}> 
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
        </Row>

        <Row gutter={16}>
          <Col xs={24} md={6}>
            <Form.Item name="basePrice" label={t('rooms.basePrice')} rules={[{ required: true, message: t('validation.required') }]}>
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
          <Col xs={24} md={6}>
            <Form.Item name="weekendPrice" label={t('rooms.weekendPrice')} rules={[{ required: true, message: t('validation.required') }]}>
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
          <Col xs={24} md={6}>
            <Form.Item name="currency" label={t('rooms.currency')}>
              <Select>
                <Option value="VND">VND</Option>
                <Option value="USD">USD</Option>
              </Select>
            </Form.Item>
          </Col>
          <Col xs={24} md={6}>
            <Form.Item name="isActive" label={t('rooms.activeStatus')} valuePropName="checked">
              <Switch />
            </Form.Item>
          </Col>
        </Row>

        <Row gutter={16}>
          <Col xs={24} md={6}>
            <Form.Item name="discountPercentage" label={t('rooms.discountPercent')}>
              <InputNumber min={0} max={100} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
          <Col xs={24} md={18}>
            <Form.Item name="specialOfferDescription" label={t('rooms.specialOfferDescription')}>
              <Input placeholder={t('common.description')} />
            </Form.Item>
          </Col>
        </Row>

        <Form.Item name="amenities" label={t('rooms.amenities')}>
          <Select mode="multiple" allowClear placeholder={t('rooms.amenities')}>
            {['wifi','air_conditioning','tv','minibar','safe','balcony','city_view','ocean_view','mountain_view','kitchenette','bathtub','shower','hairdryer','coffee_maker','telephone','desk','sofa'].map(a => (
              <Option key={a} value={a}>{a}</Option>
            ))}
          </Select>
        </Form.Item>

        <Row justify="end">
          <Space>
            <Button onClick={() => navigate(`/hotels/${hotelId}/rooms`)}>{t('common.cancel')}</Button>
            <Button type="primary" htmlType="submit" icon={<SaveOutlined />} loading={loading}>
              {isEdit ? t('common.update') : t('common.create')}
            </Button>
          </Space>
        </Row>
      </Form>
    </Card>
  );
};

export default RoomForm;
