import React from 'react';
import { Routes, Route } from 'react-router-dom';
import SelectHotel from './SelectHotel.js';
import RoomList from './RoomList.js';
import RoomForm from './RoomForm.js';

const Rooms = () => {
  return (
    <Routes>
      <Route path="/" element={<SelectHotel />} />
      <Route path=":id" element={<RoomList />} />
      <Route path=":id/new" element={<RoomForm />} />
      <Route path=":id/:roomId/edit" element={<RoomForm />} />
    </Routes>
  );
};

export default Rooms;
