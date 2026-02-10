import React from "react";
import "./Footer.css";

const Footer = () => {
  return (
    <footer className="bg-dark text-white py-3 mt-auto text-center">
      <p className="mb-0">&copy; 2026 MeuSite. Todos os direitos reservados.</p>
      <small>
        <a href="/terms" className="text-white text-decoration-underline">Termos</a> |{" "}
        <a href="/privacy" className="text-white text-decoration-underline">Privacidade</a>
      </small>
    </footer>
  );
};

export default Footer;
