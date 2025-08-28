import React, { useEffect, useState } from 'react';
import { Routes, Route } from 'react-router-dom';
import HotelList from './HotelList';
import HotelDetail from './HotelDetail';
import HotelForm from './HotelForm';

const Hotels = () => {
  return (
    <Routes>
      <Route path="/" element={<HotelList />} />
      <Route path="/new" element={<HotelForm />} />
      <Route path="/:id" element={<HotelDetail />} />
      <Route path="/:id/edit" element={<HotelForm />} />
    </Routes>
  );
};

export default Hotels;
