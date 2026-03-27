import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import "../styles/SearchPage.css";
import { useAuth } from '../contexts/AuthContext';

const DEFAULT_LOGO = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

export default function SearchPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [searchTerm, setSearchTerm] = useState('');
  const [restaurants, setRestaurants] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [hasSearched, setHasSearched] = useState(false);

  useEffect(() => {
    let isMounted = true;
    async function fetchInitial() {
      try {
        setLoading(true);
        // Traz sugestões iniciais enquanto o usuário não pesquisa nada
        const response = await axios.get('http://localhost:3002/api/restaurants/suggested');
        if (isMounted) {
          setRestaurants(response.data);
        }
      } catch (err) {
        console.error("Erro ao buscar iniciais:", err);
      } finally {
        if (isMounted) setLoading(false);
      }
    }
    fetchInitial();
    return () => { isMounted = false; };
  }, []);

  // Função disparada ao clicar em Buscar ou apertar Enter
  const handleSearch = async (e) => {
    e.preventDefault();
    
    if (!searchTerm.trim()) {
      return; // Não faz nada se a barra estiver vazia
    }

    try {
      setLoading(true);
      setError('');
      setHasSearched(true);
      
      // Chama a rota de busca no backend passando o que o usuário digitou
      const response = await axios.get(`http://localhost:3002/api/restaurants/search?q=${searchTerm}`);
      
      setRestaurants(response.data);
      
    } catch (err) {
      console.error("Erro ao buscar restaurantes:", err);
      setError('Ocorreu um erro ao realizar a busca. Tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  function browseRestaurant(id){
    if (!user) {
      navigate('/signIn');
    } else {
      navigate(`/restaurant/${id}`);
    }
  }

  return (
    <div className="container">
      
      {/* Cabeçalho e Barra de Pesquisa */}
      <div className="row justify-content-center mb-5">
        <div className="col-12 col-md-8 text-center">
          <h2 className="fw-bold text-primary display-5 mb-3">
            <i className="fas fa-search me-3"></i>Encontre seu Restaurante
          </h2>
          <p className="text-muted fs-5 mb-4">
            Busque pelo nome do restaurante e descubra o que pedir hoje.
          </p>

          {/* Formulário de Busca */}
          <form onSubmit={handleSearch}>
            <div className="input-group input-group-lg shadow-sm rounded-pill overflow-hidden border">
              <span className="input-group-text bg-white border-0 text-primary ps-4">
                <i className="fas fa-search"></i>
              </span>
              <input 
                type="text" 
                className="form-control border-0 px-3 shadow-none" 
                placeholder="Ex: Pizzaria, Burguer, Sushi..." 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              <button 
                className="btn btn-primary px-4 fw-bold" 
                type="submit"
                disabled={loading}
              >
                Buscar
              </button>
            </div>
          </form>
        </div>
      </div>

      {/* Título de Resultados (só aparece após pesquisar) */}
      {hasSearched && !loading && !error && (
        <h5 className="text-muted mb-4 border-bottom pb-2">
          Resultados para "{searchTerm}" ({restaurants.length} encontrados)
        </h5>
      )}

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
            <div className="col-12 text-center text-muted mt-5">
              <i className="fas fa-store-slash fa-3x mb-3 text-light"></i>
              <h4>Nenhum restaurante encontrado</h4>
              <p>Tente buscar por outro nome ou termo.</p>
            </div>
          ) : (
            restaurants.map((rest) => (
              <div className="col-12 col-md-6 col-lg-4 d-flex align-items-stretch" key={rest.id}>
                
                {/* Card Clicável */}
                <div 
                  className="card suggested-card shadow-sm border-0 w-100" 
                  onClick={() => {browseRestaurant(rest.id)} }
                  style={{ cursor: 'pointer', transition: 'transform 0.2s' }}
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

      <br/>
      <br/>
      <br/>
    </div>
  );
}