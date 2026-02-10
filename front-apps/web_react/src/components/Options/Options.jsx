import React from "react";
import "./Options.css";

const Options = ( ) => {
  return (
     <div className="options d-flex bg-primary text-white p-2 justify-content-center align-items-center">
      <a href="#" className="btn btn-primary me-2">
        <i className="fas fa-search"></i> Pesquisar
      </a>
      <a href="#" className="btn btn-primary me-2">
        <i className="fas fa-lightbulb"></i> Sugeridos
      </a>
      <a href="#" className="btn btn-primary me-2">
        <i className="fas fa-box"></i> Pedidos
      </a>
      <a href="#" className="btn btn-primary me-2">
        <i className="fas fa-user"></i> Conta
      </a>
      <a href="#" className="btn btn-primary me-2">
        <i className="fas fa-cog"></i> Configurações
      </a>
    </div>
  );
};

export default Options;
