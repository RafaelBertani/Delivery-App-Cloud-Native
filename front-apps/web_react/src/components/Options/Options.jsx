import React from "react";
import "./Options.css";
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const Options = () => {
  // Use o user do Contexto, e não do localStorage direto
  const { user } = useAuth(); 
  const navigate = useNavigate();

  function goToProfile() {
    navigate('/profile');
  }

  function goToSettings() {
    navigate('/settings');
  }

  function goToRestaurants(){
    navigate('/my-restaurants');
  }

  function goToSuggested(){
    navigate('/suggested');
  }
  
  // Se o contexto ainda estiver carregando, pode retornar null ou carregar normal
  // if (!user) return null; 

  return (
     <div className="options d-flex bg-primary text-white p-2 justify-content-center align-items-center">
      <a className="btn btn-primary me-2">
        <i className="fas fa-search"></i> Pesquisar
      </a>
      <a className="btn btn-primary me-2" onClick={goToSuggested}>
        <i className="fas fa-lightbulb"></i> Sugeridos
      </a>
      <a className="btn btn-primary me-2">
        <i className="fas fa-box"></i> Pedidos
      </a>
      
      {user?.is_delivery && (
        <a className="btn btn-primary me-2">
          <i className="fas fa-motorcycle"></i> Painel Entregas
        </a>
      )}
      
      {user?.has_restaurant && (
        <a className="btn btn-primary me-2" onClick={goToRestaurants}>
          <i className="fas fa-store"></i> Meus Restaurantes
        </a>
      )}
      
      <a className="btn btn-primary me-2" onClick={goToProfile}>
        <i className="fas fa-user"></i> Conta
      </a>
      
      <a className="btn btn-primary me-2" onClick={goToSettings}>
        <i className="fas fa-cog"></i> Configurações
      </a>
    </div>
  );
};

export default Options;