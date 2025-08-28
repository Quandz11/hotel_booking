import React from 'react';
import { Select, Space } from 'antd';
import { GlobalOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

const { Option } = Select;

const LanguageSwitcher = () => {
  const { i18n } = useTranslation();

  const handleLanguageChange = (value) => {
    i18n.changeLanguage(value);
    localStorage.setItem('language', value);
  };

  return (
    <Space>
      <GlobalOutlined />
      <Select
        value={i18n.language}
        onChange={handleLanguageChange}
        size="small"
        style={{ width: 80 }}
        bordered={false}
      >
        <Option value="vi">VI</Option>
        <Option value="en">EN</Option>
      </Select>
    </Space>
  );
};

export default LanguageSwitcher;
