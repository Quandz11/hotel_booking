import React from 'react';
import { Routes, Route } from 'react-router-dom';
import BookingList from './BookingList';
import BookingDetail from './BookingDetail';

const Bookings = () => {
  return (
    <Routes>
      <Route index element={<BookingList />} />
      <Route path=":id" element={<BookingDetail />} />
    </Routes>
  );
};

export default Bookings;
