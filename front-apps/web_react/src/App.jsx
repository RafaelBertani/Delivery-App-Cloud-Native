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
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/settings" element={<SettingsPage />} />
            {/* <Route path="/home" element={<LockSelectPage />} />
            <Route path="/home/:cod" element={<HomePage />} />
            <Route path="/lock-control" element={<LockControlPage />} />
            <Route path="/register-lock" element={<RegisterLockPage />} />
            <Route path="/join-lock" element={<JoinLockPage />} />
            <Route path="/logs" element={<LogsPage />} />
            <Route path="/users" element={<UsersPage />} /> */}
          </Routes>
        </main>
        {/* <Footer className="mt-auto"/> */}
      </div>
    </AuthProvider>
  );
}

export default App;