import "../styles/SettingsPage.css";
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../contexts/AuthContext';
import 'bootstrap/dist/css/bootstrap.min.css';

export default function SettingsPage() {
  const navigate = useNavigate();
  const { user, updateUserProfile } = useAuth();
  const [loading, setLoading] = useState(false);
  
  // Estado local apenas para o Modo Noturno (exemplo visual)
  const [darkMode, setDarkMode] = useState(() => {
    return localStorage.getItem('darkMode') === 'true';
  });

  useEffect(() => {
    // Redireciona se não estiver logado
    if (!user) {
      navigate('/signIn');
    }
  }, [user, navigate]);

  // Função para alternar configurações que dependem do Servidor
  const handleServerToggle = async (field, currentValue) => {
    // Confirmação antes de mudar
    const label = field === 'is_delivery' ? 'Entregador' : 'Dono de Restaurante';
    const action = currentValue ? 'desativar' : 'ativar';
    
    const confirmed = window.confirm(`Tem certeza que deseja ${action} o modo ${label}?`);
    if (!confirmed) return;

    const token = localStorage.getItem('token');
    if (!token) return navigate('/signIn');

    try {
      setLoading(true);

      // Requisição ao Servidor (envia o valor inverso do atual)
      const newValue = !currentValue;
      
      const response = await axios.put('http://localhost:3001/api/auth/edit', 
        { [field]: newValue }, 
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      // Atualiza o Contexto e o LocalStorage (via AuthContext)
      // O backend retorna o objeto user completo atualizado
      const userAtualizado = response.data.user;
      updateUserProfile(userAtualizado);

    } catch (error) {
      console.error(error);
      alert(error.response?.data?.message || "Erro ao atualizar configuração.");
    } finally {
      setLoading(false);
    }
  };

  // Função para o Modo Noturno (Local apenas)
  const handleDarkModeToggle = () => {
    const newVal = !darkMode;
    setDarkMode(newVal);
    localStorage.setItem('darkMode', newVal);
    if(newVal) {
        document.body.classList.add('bg-dark', 'text-white');
    } else {
        document.body.classList.remove('bg-dark', 'text-white');
    }
  };

  if (!user) return null;

  return (
    <div className="container mt-5 d-flex justify-content-center">
      <div className={`card shadow p-4 ${darkMode ? 'bg-secondary text-white' : 'bg-white'}`} style={{ width: '100%', maxWidth: '500px' }}>
        
        <div className="d-flex align-items-center mb-4">
          <button className="btn btn-link text-decoration-none me-2 p-0" onClick={() => navigate(-1)}>
            <i className="fas fa-arrow-left fs-4"></i>
          </button>
          <h4 className="fw-bold mb-0">Configurações</h4>
        </div>

        <hr />

        <div className="card-body p-0">
          
          {/* Slider 2: Entregador (Server Side) */}
          <div className="d-flex justify-content-between align-items-center mb-4">
            <div>
              <h6 className="fw-bold mb-0"><i className="fas fa-motorcycle me-2"></i>Sou Entregador</h6>
              <small className={darkMode ? "text-light" : "text-muted"}>Habilita o painel de entregas</small>
            </div>
            <div className="form-check form-switch">
              <input 
                className="form-check-input" 
                type="checkbox" 
                style={{ transform: 'scale(1.3)' }}
                checked={user.is_delivery} // Valor vem do Contexto
                onChange={() => handleServerToggle('is_delivery', user.is_delivery)}
                disabled={loading}
              />
            </div>
          </div>

          <hr className="my-3 opacity-25"/>

          {/* Slider 3: Restaurante (Server Side) */}
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h6 className="fw-bold mb-0"><i className="fas fa-store me-2"></i>Tenho Restaurante</h6>
              <small className={darkMode ? "text-light" : "text-muted"}>Gerenciar meus restaurantes</small>
            </div>
            <div className="form-check form-switch">
              <input 
                className="form-check-input" 
                type="checkbox" 
                style={{ transform: 'scale(1.3)' }}
                checked={user.has_restaurant} // Valor vem do Contexto
                onChange={() => handleServerToggle('has_restaurant', user.has_restaurant)}
                disabled={loading}
              />
            </div>
          </div>

        </div>
        
        {loading && (
           <div className="text-center mt-3">
             <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
             <small>Salvando alterações...</small>
           </div>
        )}

      </div>
    </div>
  );
}