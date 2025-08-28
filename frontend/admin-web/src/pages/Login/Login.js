import React, { useState } from 'react';
import { Form, Input, Button, Card, Alert, Checkbox, Select } from 'antd';
import { UserOutlined, LockOutlined, GlobalOutlined } from '@ant-design/icons';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { login, clearError } from '../../store/slices/authSlice';
import './Login.css';

const { Option } = Select;

const Login = () => {
  const [form] = Form.useForm();
  const dispatch = useDispatch();
  const { loading, error } = useSelector((state) => state.auth);
  const { t, i18n } = useTranslation();

  const onFinish = (values) => {
    dispatch(clearError());
    dispatch(login(values));
  };

  const changeLanguage = (lang) => {
    i18n.changeLanguage(lang);
    localStorage.setItem('language', lang);
  };

  return (
    <div className="login-container">
      <div className="login-header">
        <div className="language-selector">
          <Select
            value={i18n.language}
            onChange={changeLanguage}
            suffixIcon={<GlobalOutlined />}
            bordered={false}
          >
            <Option value="vi">Tiếng Việt</Option>
            <Option value="en">English</Option>
          </Select>
        </div>
      </div>
      
      <div className="login-content">
        <Card className="login-card">
          <div className="login-logo">
            <h1>Hotel Admin</h1>
            <p>{t('auth.adminPanel')}</p>
          </div>

          {error && (
            <Alert
              message={error}
              type="error"
              showIcon
              closable
              onClose={() => dispatch(clearError())}
              style={{ marginBottom: 24 }}
            />
          )}

          <Form
            form={form}
            name="login"
            onFinish={onFinish}
            autoComplete="off"
            size="large"
          >
            <Form.Item
              name="email"
              rules={[
                {
                  required: true,
                  message: t('auth.emailRequired'),
                },
                {
                  type: 'email',
                  message: t('auth.emailInvalid'),
                },
              ]}
            >
              <Input
                prefix={<UserOutlined />}
                placeholder={t('auth.email')}
              />
            </Form.Item>

            <Form.Item
              name="password"
              rules={[
                {
                  required: true,
                  message: t('auth.passwordRequired'),
                },
              ]}
            >
              <Input.Password
                prefix={<LockOutlined />}
                placeholder={t('auth.password')}
              />
            </Form.Item>

            <Form.Item>
              <Form.Item name="remember" valuePropName="checked" noStyle>
                <Checkbox>{t('auth.rememberMe')}</Checkbox>
              </Form.Item>
            </Form.Item>

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                loading={loading}
                block
              >
                {t('auth.login')}
              </Button>
            </Form.Item>
          </Form>

          <div className="login-footer">
            <p>{t('auth.adminOnly')}</p>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Login;
