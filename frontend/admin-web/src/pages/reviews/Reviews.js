import React from 'react';
import { Routes, Route } from 'react-router-dom';
import ReviewList from './ReviewList';
import ReviewDetail from './ReviewDetail';

const Reviews = () => {
  return (
    <Routes>
      <Route index element={<ReviewList />} />
      <Route path=":id" element={<ReviewDetail />} />
    </Routes>
  );
};

export default Reviews;
