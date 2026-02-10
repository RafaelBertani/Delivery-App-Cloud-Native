import React from "react";
import { useNavigate } from 'react-router-dom';
import "./Header.css";
import logo from "../../assets/logo.png";

const Header = ( ) => {

  const navigate = useNavigate();

  function goToSignUp() {
    navigate('/signUp');
  }

  function goToSignIn() {
    navigate('/signIn');
  }

  return (
    <header className="header">
      <img className="logo" src={logo} alt="Logo"/> {/* seria bom uma .svg */}
      <div className="header-buttons">
        <button className="btn signin" onClick={goToSignIn}>Login</button>
        <button className="btn signup" onClick={goToSignUp}>Cadastro</button>
      </div>
    </header>
  );
};

export default Header;
