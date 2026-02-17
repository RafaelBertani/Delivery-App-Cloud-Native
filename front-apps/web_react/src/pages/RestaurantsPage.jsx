import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../contexts/AuthContext';
import 'bootstrap/dist/css/bootstrap.min.css';
import "../styles/RestaurantsPage.css";

const DEFAULT_LOGO = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

export default function RestaurantsPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  // Estados da Lista
  const [restaurants, setRestaurants] = useState([]);
  const [loadingList, setLoadingList] = useState(true);
  const [error, setError] = useState('');

  // Estados do Formulário
  const [creating, setCreating] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    street: '',
    city: '',
    state: '',
    zip_code: '',
    country: 'Brasil', // Valor padrão
    logo: '' // Será base64
  });

  // 1. Carregar restaurantes ao abrir a página
  useEffect(() => {
    fetchRestaurants();
  }, []);

  async function fetchRestaurants() {
    const token = localStorage.getItem('token');

    if (!user || !token) return;

    try {
      setLoadingList(true);
      const response = await axios.get('http://localhost:3001/api/restaurants/list', {
        params: { id: user.id },
        headers: { Authorization: `Bearer ${token}` }
      });
      setRestaurants(response.data);
      setError('');
    } catch (err) {
      console.error(err);
      setError('Erro ao carregar restaurantes. Tente novamente.');
    } finally {
      setLoadingList(false);
    }
  }

  // 2. Manipulação do Formulário
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleLogoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) { // 2MB limit
        alert("Imagem muito grande! Máximo 2MB.");
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        setFormData(prev => ({ ...prev, logo: reader.result }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const token = localStorage.getItem('token');
    
    if (!formData.name || !formData.street || !formData.city) {
      alert("Preencha os campos obrigatórios (Nome, Rua, Cidade).");
      return;
    }

    try {
      setCreating(true);
      await axios.post('http://localhost:3001/api/restaurants/new', {id: user.id, ...formData}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      alert("Restaurante criado com sucesso!");
      
      // Limpa formulário
      setFormData({
        name: '', description: '', street: '', city: '', state: '', zip_code: '', country: 'Brasil', logo: ''
      });

      // Recarrega a lista
      fetchRestaurants();

    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Erro ao criar restaurante.");
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="container mt-4 mb-5">
      
      {/* --- ÁREA 1: CADASTRAR NOVO RESTAURANTE --- */}
      <div className="card shadow-sm mb-5">
        <div className="card-header bg-primary text-white">
          <h5 className="mb-0"><i className="fas fa-plus-circle me-2"></i>Novo Restaurante</h5>
        </div>
        <div className="card-body">
          <form onSubmit={handleSubmit}>
            <div className="row">
              {/* Logo Preview */}
              <div className="col-md-2 text-center mb-3">
                <img 
                  src={formData.logo || DEFAULT_LOGO} 
                  alt="Logo Preview" 
                  className="img-thumbnail rounded-circle"
                  style={{ width: '100px', height: '100px', objectFit: 'cover' }}
                />
                <div className="mt-2">
                  <label className="btn btn-sm btn-outline-secondary" style={{ cursor: 'pointer' }}>
                    Carregar Logo
                    <input type="file" hidden accept="image/*" onChange={handleLogoChange} />
                  </label>
                </div>
              </div>

              {/* Campos Principais */}
              <div className="col-md-10">
                <div className="mb-3">
                  <label className="form-label fw-bold">Nome do Restaurante *</label>
                  <input type="text" className="form-control" name="name" value={formData.name} onChange={handleInputChange} required placeholder="Ex: Pizzaria do João" />
                </div>
                <div className="mb-3">
                  <label className="form-label">Descrição</label>
                  <textarea className="form-control" name="description" rows="2" value={formData.description} onChange={handleInputChange} placeholder="Ex: A melhor pizza da região..." />
                </div>
              </div>
            </div>

            <h6 className="mt-3 text-muted border-bottom pb-2">Endereço</h6>
            <div className="row g-3">
              <div className="col-md-6">
                <input type="text" className="form-control" name="street" value={formData.street} onChange={handleInputChange} placeholder="Rua / Avenida *" required />
              </div>
              <div className="col-md-3">
                <input type="text" className="form-control" name="city" value={formData.city} onChange={handleInputChange} placeholder="Cidade *" required />
              </div>
              <div className="col-md-3">
                <input type="text" className="form-control" name="state" value={formData.state} onChange={handleInputChange} placeholder="Estado" />
              </div>
              <div className="col-md-4">
                <input type="text" className="form-control" name="zip_code" value={formData.zip_code} onChange={handleInputChange} placeholder="CEP" />
              </div>
              <div className="col-md-4">
                <input type="text" className="form-control" name="country" value={formData.country} onChange={handleInputChange} placeholder="País" />
              </div>
              <div className="col-md-4 d-flex align-items-end">
                <button type="submit" className="btn btn-success w-100" disabled={creating}>
                  {creating ? 'Salvando...' : 'Cadastrar Restaurante'}
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>

      {/* --- ÁREA 2: LISTA DE RESTAURANTES --- */}
      <h4 className="fw-bold mb-3"><i className="fas fa-store me-2"></i>Meus Restaurantes</h4>
      
      {loadingList && (
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status"></div>
          <p className="mt-2 text-muted">Carregando seus restaurantes...</p>
        </div>
      )}

      {!loadingList && error && (
        <div className="alert alert-danger" role="alert">
          {error}
        </div>
      )}

      {!loadingList && !error && restaurants.length === 0 && (
        <div className="alert alert-info text-center p-5">
          <i className="fas fa-utensils fa-3x mb-3 text-secondary"></i>
          <h5>Nenhum restaurante encontrado.</h5>
          <p>Cadastre seu primeiro restaurante acima para começar!</p>
        </div>
      )}

      <div className="d-flex flex-column gap-3">
        {!loadingList && restaurants.map((rest) => (
          <div key={rest.id} className="card shadow-sm border-start border-4 border-primary">
            <div className="card-body d-flex align-items-center flex-wrap">
              
              {/* Imagem */}
              <div className="me-4">
                <img 
                  src={rest.logo || DEFAULT_LOGO} 
                  alt={rest.name} 
                  className="rounded"
                  style={{ width: '80px', height: '80px', objectFit: 'cover' }}
                />
              </div>

              {/* Informações */}
              <div className="flex-grow-1">
                <h5 className="fw-bold mb-1">{rest.name}</h5>
                <p className="text-muted small mb-1">
                  {rest.description ? rest.description.substring(0, 60) + '...' : 'Sem descrição'}
                </p>
                <small className="text-secondary">
                  <i className="fas fa-map-marker-alt me-1"></i>
                  {rest.city} - {rest.state}
                </small>
              </div>

              {/* Botão de Ação */}
              <div className="mt-3 mt-md-0">
                <button className="btn btn-outline-primary" onClick={() => alert(`Gerenciar ID: ${rest.id}`)}>
                  <i className="fas fa-cog me-1"></i> GERENCIAR
                </button>
              </div>
              
            </div>
          </div>
        ))}
      </div>

    </div>
  );
}