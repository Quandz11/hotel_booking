import React, { useEffect, useState } from 'react';
import { Routes, Route } from 'react-router-dom';
import HotelList from './HotelList';
import HotelDetail from './HotelDetail';
import HotelForm from './HotelForm';
import RoomList from '../rooms/RoomList';
import RoomForm from '../rooms/RoomForm';

const Hotels = () => {
  return (
    <Routes>
      <Route path="/" element={<HotelList />} />
      <Route path="/new" element={<HotelForm />} />
      <Route path="/:id" element={<HotelDetail />} />
      <Route path="/:id/edit" element={<HotelForm />} />
      <Route path= "/:id/rooms" element={<RoomList />} />
      <Route path= "/:id/rooms/new" element={<RoomForm />} />
      <Route path= "/:id/rooms/:roomId/edit" element={<RoomForm />} />
    </Routes>
  );
};

export default Hotels;
