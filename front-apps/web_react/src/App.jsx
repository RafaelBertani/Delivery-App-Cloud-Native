import { Routes, Route } from 'react-router-dom'; //npm install react-router-dom
import { useState, useEffect } from 'react';
import 'bootstrap/dist/css/bootstrap.min.css' // npm install bootstrap
import '@fortawesome/fontawesome-free/css/all.css' // npm install --save @fortawesome/fontawesome-free
import axios from 'axios';
import { AuthProvider } from './contexts/AuthContext';

import Header from "./components/Header/Header";
import Footer from "./components/Footer/Footer";
import Options from "./components/Options/Options";
import HomePage from "./pages/HomePage";
import SignInPage from "./pages/SignInPage";
import SignUpPage from "./pages/SignUpPage";
import ProfilePage from "./pages/ProfilePage";
import SettingsPage from "./pages/SettingsPage";
import RestaurantsPage from "./pages/RestaurantsPage";
import ManageRestaurantPage from "./pages/ManageRestaurantPage";
import DishesPage from './pages/DishesPage';
import SuggestedPage from './pages/SuggestedPage';
import OrderPage from './pages/OrderPage';
import OrderListPage from './pages/OrderListPage';
import ManageOrdersPage from './pages/ManageOrdersPage';

function App() {

  const [user, setUser] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('token');

    if (!token) return;

    axios.get('http://localhost:3001/api/auth/me', {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })
    .then(res => {
      setUser(res.data.user);
    })
    .catch(() => {
      localStorage.removeItem('token');
      setUser(null);
    });
  }, []);

  return (
    <AuthProvider>
      <div className="container-fluid p-0 d-flex flex-column min-vh-100">
        <Header />
        <Options />
        <main className="main flex-grow-1">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/signIn" element={<SignInPage />} />
            <Route path="/signUp" element={<SignUpPage />} />

            <Route path="/suggested" element={<SuggestedPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/settings" element={<SettingsPage />} />
            <Route path="/my-restaurants" element={<RestaurantsPage />} />
            <Route path="/restaurant/:id" element={<OrderPage />} />
            {/* <Route path="/orders" element={<ViewOrdersPage />} /> */}
            <Route path="/orders-list" element={<OrderListPage />} />
            <Route path="/my-restaurants/:id/settings" element={<ManageRestaurantPage />} />
            <Route path="/my-restaurants/:id/edit-menu" element={<DishesPage />} />
            <Route path="/my-restaurants/:id/manage-orders" element={<ManageOrdersPage />} />
          </Routes>
        </main>
        {/* <Footer className="mt-auto"/> */}
      </div>
    </AuthProvider>
  );
}

export default App;