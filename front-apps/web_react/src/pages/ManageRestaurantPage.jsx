import "../styles/ManageRestaurantPage.css";
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';

const DEFAULT_LOGO = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

export default function ManageRestaurantPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  
  // Estado para visualização da imagem antes de salvar
  const [logoPreview, setLogoPreview] = useState(DEFAULT_LOGO);

  // Objeto único com todos os campos editáveis
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    street: '',
    city: '',
    state: '',
    zip_code: '',
    country: 'Brasil',
    logo: '' // Base64
  });

  // 1. Carrega os dados atuais ao abrir a tela
  useEffect(() => {
    let isMounted = true;
    
    async function fetchData() {
      const token = localStorage.getItem('token');
      if (!token) { navigate(`/my-restaurants/${id}`); return; }

      try {
        const response = await axios.get(`http://localhost:3002/api/restaurants/${id}/settings`, {
          headers: { Authorization: `Bearer ${token}` }
        });

        if (isMounted) {
          const data = response.data;
          // Preenche o formulário com o que veio do banco
          setFormData({
            name: data.name || '',
            description: data.description || '',
            street: data.street || '',
            city: data.city || '',
            state: data.state || '',
            zip_code: data.zip_code || '',
            country: data.country || 'Brasil',
            logo: data.logo || '' // Mantém a logo atual no state (para reenvio se necessário) ou manipula logica
          });
          
          if (data.logo) {
            setLogoPreview(data.logo);
          }
          setLoading(false);
        }
      } catch (err) {
        if (isMounted) {
          console.error(err);
          setError("Erro ao carregar dados do restaurante.");
          setLoading(false);
        }
      }
    }

    fetchData();

    return () => { isMounted = false; };
  }, [id, navigate]);

  // 2. Manipula mudança nos inputs de texto
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  // 3. Manipula troca de imagem (Logo)
  const handleLogoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        alert("A imagem é muito grande! Escolha uma menor que 2MB.");
        return;
      }

      const reader = new FileReader();
      reader.onloadend = () => {
        // Atualiza o preview e o form data com o novo base64
        setLogoPreview(reader.result);
        setFormData(prev => ({ ...prev, logo: reader.result }));
      };
      reader.readAsDataURL(file);
    }
  };

  // 4. Salvar Alterações
  const handleSubmit = async (e) => {
    e.preventDefault();
    const token = localStorage.getItem('token');
    
    // Validação básica
    if (!formData.name || !formData.street || !formData.city) {
        alert("Nome, Rua e Cidade são obrigatórios.");
        return;
    }

    try {
      setSaving(true);
      
      await axios.patch(`http://localhost:3002/api/restaurants/${id}/settings`, 
        formData, 
        { headers: { Authorization: `Bearer ${token}` } }
      );

      alert("Dados atualizados com sucesso!");
      navigate(`/my-restaurants`);

    } catch (err) {
      console.error(err);
      alert(err.response?.data?.message || "Erro ao atualizar restaurante.");
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div className="text-center mt-5"><div className="spinner-border text-primary"></div></div>;

  return (
    <div className="container mt-4 mb-5" style={{ maxWidth: '800px' }}>
      
      {/* --- CABEÇALHO ALTERADO --- */}
      <div className="d-flex align-items-center justify-content-between mb-4">
        
        {/* Lado Esquerdo: Voltar + Título */}
        <div className="d-flex align-items-center">
          <button className="btn btn-outline-secondary me-3" onClick={() => navigate(`/my-restaurants`)}>
            <i className="fas fa-arrow-left"></i> Voltar
          </button>
          <h3 className="fw-bold mb-0">Editar Dados</h3>
        </div>

        {/* Lado Direito: BOTÃO NOVO (Gerenciar Pratos) */}
        <button 
          className="btn btn-primary shadow-sm" 
          onClick={() => navigate(`/my-restaurants/${id}/edit-menu`)}
        >
          <i className="fas fa-utensils me-2"></i> Pratos
        </button>

      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <form onSubmit={handleSubmit}>
        
        {/* CARD 1: Identidade Visual e Básicos */}
        <div className="card shadow-sm mb-4">
          <div className="card-header bg-white py-3">
            <h5 className="mb-0 fw-bold text-primary"><i className="fas fa-id-card me-2"></i>Informações Básicas</h5>
          </div>
          <div className="card-body">
            
            <div className="row">
              {/* Área da Logo */}
              <div className="col-md-4 text-center mb-4 mb-md-0 border-end">
                <label className="form-label fw-bold d-block">Logotipo</label>
                <div className="position-relative d-inline-block">
                    <img 
                    src={logoPreview} 
                    alt="Logo Preview" 
                    className="rounded-circle border border-3 border-light shadow-sm mb-3"
                    style={{ width: '150px', height: '150px', objectFit: 'cover' }}
                    />
                    <label 
                        className="btn btn-sm btn-primary position-absolute bottom-0 end-0 rounded-circle shadow"
                        style={{ width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', transform: 'translate(-10px, -10px)' }}
                        title="Alterar imagem"
                    >
                        <i className="fas fa-camera"></i>
                        <input type="file" hidden accept="image/*" onChange={handleLogoChange} />
                    </label>
                </div>
                <div className="text-muted small mt-2">Clique na câmera para alterar.<br/>Max: 2MB</div>
              </div>

              {/* Campos de Texto */}
              <div className="col-md-8 ps-md-4">
                <div className="mb-3">
                  <label className="form-label fw-bold">Nome do Restaurante *</label>
                  <input 
                    type="text" 
                    className="form-control" 
                    name="name" 
                    value={formData.name} 
                    onChange={handleInputChange} 
                    required 
                  />
                </div>
                <div className="mb-3">
                  <label className="form-label fw-bold">Descrição</label>
                  <textarea 
                    className="form-control" 
                    name="description" 
                    rows="4" 
                    value={formData.description} 
                    onChange={handleInputChange}
                    placeholder="Conte um pouco sobre seu restaurante..."
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* CARD 2: Endereço */}
        <div className="card shadow-sm mb-4">
          <div className="card-header bg-white py-3">
            <h5 className="mb-0 fw-bold text-primary"><i className="fas fa-map-marked-alt me-2"></i>Endereço e Localização</h5>
          </div>
          <div className="card-body">
            <div className="row g-3">
              <div className="col-md-8">
                <label className="form-label fw-bold">Rua / Avenida / Número *</label>
                <input type="text" className="form-control" name="street" value={formData.street} onChange={handleInputChange} required />
              </div>
              <div className="col-md-4">
                <label className="form-label fw-bold">CEP</label>
                <input type="text" className="form-control" name="zip_code" value={formData.zip_code} onChange={handleInputChange} />
              </div>
              <div className="col-md-5">
                <label className="form-label fw-bold">Cidade *</label>
                <input type="text" className="form-control" name="city" value={formData.city} onChange={handleInputChange} required />
              </div>
              <div className="col-md-3">
                <label className="form-label fw-bold">Estado</label>
                <input type="text" className="form-control" name="state" value={formData.state} onChange={handleInputChange} />
              </div>
              <div className="col-md-4">
                <label className="form-label fw-bold">País</label>
                <input type="text" className="form-control" name="country" value={formData.country} onChange={handleInputChange} />
              </div>
            </div>
          </div>
        </div>

        {/* Botões de Ação */}
        <div className="d-flex justify-content-end gap-3 mb-5">
          <button type="button" className="btn btn-secondary px-4" onClick={() => navigate(`/my-restaurants/`)}>
            Cancelar
          </button>
          <button type="submit" className="btn btn-success px-5 fw-bold" disabled={saving}>
            {saving ? (
                <>
                    <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                    Salvando...
                </>
            ) : (
                <>
                    <i className="fas fa-save me-2"></i> Salvar Alterações
                </>
            )}
          </button>
        </div>

      </form>
    </div>
  );
}