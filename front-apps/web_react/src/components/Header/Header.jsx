import React from "react";
import { useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import "./Header.css";
import logo from "../../assets/logo.png";
import { useAuth } from "../../contexts/AuthContext";

const Header = ( ) => {
  
  const navigate = useNavigate();

  const { user, signOut } = useAuth();

  function goToSignUp() {
    navigate('/signUp');
  }

  function goToSignIn() {
    navigate('/signIn');
  }

  function handleLogout() {
    signOut();
    navigate('/');
  }

  return (
    <header className="header">
      <img className="logo" src={logo} alt="Logo"/> {/* seria bom uma .svg */}
      <div className="header-buttons">
        {user ? (
          <div className="d-flex align-items-center">
            <span className="me-3 fw-bold text-dark">
              Olá, {user.name}
            </span>
            
            <button 
              className="btn btn-outline-danger btn-sm" 
              onClick={handleLogout}
              title="Sair da conta"
            >
              <i className="fas fa-sign-out-alt"></i> Sair
            </button>
          </div>
        ) : (
          <>
            <button className="btn signin" onClick={goToSignIn}>Login</button>
            <button className="btn signup" onClick={goToSignUp}>Cadastro</button>
          </>
        )}
      </div>
    </header>
  );
};

export default Header;
