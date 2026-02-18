import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import "../styles/SuggestedPage.css";

const DEFAULT_LOGO = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

export default function SuggestedPage() {
  const navigate = useNavigate();
  const [restaurants, setRestaurants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let isMounted = true;

    async function fetchSuggestedRestaurants() {
      try {
        setLoading(true);
        const response = await axios.get('http://localhost:3002/api/restaurants/suggested');
        
        if (isMounted) {
          setRestaurants(response.data);
          setError('');
        }
      } catch (err) {
        console.error("Erro ao buscar sugestões:", err);
        if (isMounted) {
          setError('Não foi possível carregar as sugestões no momento.');
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    }

    fetchSuggestedRestaurants();

    return () => { isMounted = false; };
  }, []);

  return (
    <div className="container mt-5 mb-5">
      
      {/* Cabeçalho da Página */}
      <div className="text-center mb-5">
        <h2 className="fw-bold text-primary display-5">
          <i className="fas fa-compass me-3"></i>Descubra Novos Sabores
        </h2>
        <p className="text-muted fs-5">Sugestões incríveis escolhidas aleatoriamente para você hoje.</p>
      </div>

      {/* Loading */}
      {loading && (
        <div className="d-flex justify-content-center py-5">
          <div className="spinner-border text-primary" style={{ width: '3rem', height: '3rem' }}></div>
        </div>
      )}

      {/* Erro */}
      {!loading && error && (
        <div className="alert alert-danger text-center shadow-sm">
          <i className="fas fa-exclamation-triangle me-2"></i> {error}
        </div>
      )}

      {/* Grid de Restaurantes */}
      {!loading && !error && (
        <div className="row g-4">
          {restaurants.length === 0 ? (
            <div className="col-12 text-center text-muted mt-4">
              <p>Nenhum restaurante disponível no momento.</p>
            </div>
          ) : (
            restaurants.map((rest) => (
              <div className="col-12 col-md-6 col-lg-4 d-flex align-items-stretch" key={rest.id}>
                
                {/* Card Clicável */}
                <div 
                  className="card suggested-card shadow-sm border-0 w-100" 
                  onClick={() => navigate(`/restaurant/${rest.id}`)}
                >
                  <div className="card-body text-center p-4 d-flex flex-column">
                    
                    {/* Imagem do Restaurante */}
                    <div className="mb-3">
                      <img 
                        src={rest.logo || DEFAULT_LOGO} 
                        alt={rest.name} 
                        className={`rounded-circle shadow-sm border border-2 ${rest.is_open ? 'border-success' : 'border-secondary'}`}
                        style={{ width: '120px', height: '120px', objectFit: 'cover' }}
                      />
                    </div>
                    
                    {/* Informações */}
                    <h4 className="fw-bold mb-1 text-truncate">{rest.name}</h4>
                    
                    {/* Badge de Funcionamento */}
                    <div className="mb-3">
                      {rest.is_open ? (
                        <span className="badge bg-success bg-opacity-10 text-success rounded-pill px-3">Aberto Agora</span>
                      ) : (
                        <span className="badge bg-secondary bg-opacity-10 text-secondary rounded-pill px-3">Fechado</span>
                      )}
                    </div>

                    <p className="text-muted small flex-grow-1 text-truncate-2-lines">
                      {rest.description || "O melhor da gastronomia na sua região."}
                    </p>

                    <hr className="w-100 text-muted" />

                    {/* Localização */}
                    <div className="text-secondary small fw-bold">
                      <i className="fas fa-map-marker-alt me-1 text-danger"></i> 
                      {rest.city} {rest.state && `- ${rest.state}`}
                    </div>

                  </div>
                </div>

              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}