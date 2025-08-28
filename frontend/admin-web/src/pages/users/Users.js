import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { Outlet } from 'react-router-dom';
import UserList from './UserList';
import UserDetail from './UserDetail';
import UserForm from './UserForm';

const Users = () => {
  return (
    <Routes>
      <Route index element={<UserList />} />
      <Route path="new" element={<UserForm />} />
      <Route path=":id" element={<UserDetail />} />
      <Route path=":id/edit" element={<UserForm />} />
    </Routes>
  );
};

export default Users;
