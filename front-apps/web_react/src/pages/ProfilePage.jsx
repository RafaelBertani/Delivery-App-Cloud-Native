import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import { useAuth } from '../contexts/AuthContext';

const DEFAULT_AVATAR = "https://cdn-icons-png.flaticon.com/512/149/149071.png";

export default function ProfilePage() {
  const navigate = useNavigate();
  
  const { user, updateUserProfile } = useAuth(); 
  
  const [editingField, setEditingField] = useState(null);
  const [tempValue, setTempValue] = useState("");
  const [loading, setLoading] = useState(false); 

  // O useEffect que lia o localStorage foi removido, pois o AuthProvider deve gerenciar isso.

  async function saveToBackend(field, value) {
    const token = localStorage.getItem('token');

    if (!token) {
      navigate('/signIn');
      return false;
    }

    try {
      setLoading(true);
      
      const response = await axios.put('http://localhost:3001/api/auth/edit', 
        { [field]: value }, 
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      // O backend retorna o user atualizado
      const userAtualizado = response.data.user;

      // Atualiza o Contexto Global (que atualiza a tela automaticamente)
      updateUserProfile(userAtualizado);

      setLoading(false);
      return true; // Sucesso

    } catch (error) {
      setLoading(false);
      console.error(error);
      
      if (error.response?.status === 401) {
        alert("Sessão expirada. Faça login novamente.");
        localStorage.removeItem('token');
        localStorage.removeItem('user'); // Opcional, o contexto deve lidar com logout
        navigate('/signIn');
      } else {
        alert(error.response?.data?.message || "Erro ao atualizar perfil.");
      }
      return false; // Falha
    }
  }

  const handleImageChange = (e) => {
    const file = e.target.files[0];

    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        alert("A imagem é muito grande! Escolha uma menor que 2MB.");
        return;
      }

      const reader = new FileReader();
      
      reader.onloadend = async () => {
        const base64String = reader.result;
        
        // Apenas chamamos o backend. A atualização da tela acontece via updateUserProfile dentro dessa função.
        const success = await saveToBackend('profile_pic', base64String); 

        if (success) {
          alert("Foto atualizada com sucesso!");
        }
      };

      reader.readAsDataURL(file);
    }
  };

  function startEditing(field, currentValue) {
    setEditingField(field);
    setTempValue(currentValue);
  }

  function cancelEditing() {
    setEditingField(null);
    setTempValue("");
  }

  async function handleSave() {
    if (editingField === 'password' && tempValue.length < 6) {
      alert("A senha deve ter no mínimo 6 caracteres.");
      return;
    }
    if (!tempValue.trim() && editingField !== 'password') return;

    const success = await saveToBackend(editingField, tempValue);

    if (success) {
        setEditingField(null); 
    }
  }

  // Se o contexto ainda não carregou o user (loading inicial do app), não exibe nada ou um spinner
  if (!user) return null; 

  return (
    <div className="container mt-5 d-flex justify-content-center">
      <div className="card shadow p-4" style={{ width: '100%', maxWidth: '500px' }}>
        
        {loading && (
          <div className="position-absolute top-0 start-0 w-100 h-100 bg-white opacity-75 d-flex justify-content-center align-items-center" style={{ zIndex: 10 }}>
            <div className="spinner-border text-primary" role="status"></div>
          </div>
        )}

        <div className="text-center mb-4">
          
          <div className="position-relative d-inline-block">
            <img 
              src={user.pic || DEFAULT_AVATAR} 
              alt="Profile" 
              className="rounded-circle mb-2 border border-3 border-secondary"
              style={{ width: '120px', height: '120px', objectFit: 'cover' }}
            />
            
            <input 
              type="file" 
              id="avatarInput" 
              accept="image/*" 
              style={{ display: 'none' }} 
              onChange={handleImageChange}
              disabled={loading} 
            />

            <label 
              htmlFor="avatarInput" 
              className="position-absolute bottom-0 end-0 bg-primary text-white rounded-circle p-2 shadow-sm"
              style={{ cursor: loading ? 'wait' : 'pointer', transform: 'translate(10%, -20%)' }}
              title="Trocar foto"
            >
              <i className="fas fa-camera"></i>
            </label>
          </div>

          <h4 className="fw-bold mt-2">Meu Perfil</h4>
          <span className="badge bg-secondary">{user.role}</span>
        </div>

        <hr />

        <div className="card-body">
          
          <div className="mb-4">
            <label className="form-label text-muted small fw-bold">NOME COMPLETO</label>
            <div className="d-flex justify-content-between align-items-center">
              <span className="fs-5">{user.name}</span>
              {editingField !== 'name' && (
                <button className="btn btn-link text-decoration-none p-0" onClick={() => startEditing('name', user.name)} disabled={loading}>
                  <i className="fas fa-pencil-alt"></i> Editar
                </button>
              )}
            </div>
            {editingField === 'name' && (
              <div className="mt-2 p-3 bg-light rounded border">
                <input type="text" className="form-control mb-2" value={tempValue} onChange={(e) => setTempValue(e.target.value)} autoFocus disabled={loading} />
                <div className="d-flex gap-2">
                  <button className="btn btn-success btn-sm" onClick={handleSave} disabled={loading}><i className="fas fa-check"></i> Salvar</button>
                  <button className="btn btn-secondary btn-sm" onClick={cancelEditing} disabled={loading}>Cancelar</button>
                </div>
              </div>
            )}
          </div>

          <div className="mb-4">
            <label className="form-label text-muted small fw-bold">E-MAIL</label>
            <div className="d-flex justify-content-between align-items-center">
              <span className="fs-5">{user.email}</span>
              {editingField !== 'email' && (
                <button className="btn btn-link text-decoration-none p-0" onClick={() => startEditing('email', user.email)} disabled={loading}>
                  <i className="fas fa-pencil-alt"></i> Editar
                </button>
              )}
            </div>
            {editingField === 'email' && (
              <div className="mt-2 p-3 bg-light rounded border">
                <input type="email" className="form-control mb-2" value={tempValue} onChange={(e) => setTempValue(e.target.value)} autoFocus disabled={loading}/>
                <div className="d-flex gap-2">
                  <button className="btn btn-success btn-sm" onClick={handleSave} disabled={loading}><i className="fas fa-check"></i> Salvar</button>
                  <button className="btn btn-secondary btn-sm" onClick={cancelEditing} disabled={loading}>Cancelar</button>
                </div>
              </div>
            )}
          </div>

          <div className="mb-4">
            <label className="form-label text-muted small fw-bold">SENHA</label>
            <div className="d-flex justify-content-between align-items-center">
              <span className="fs-5 text-muted">••••••••</span> 
              {editingField !== 'password' && (
                <button className="btn btn-link text-decoration-none p-0" onClick={() => startEditing('password', '')} disabled={loading}>
                  <i className="fas fa-pencil-alt"></i> Alterar
                </button>
              )}
            </div>
            {editingField === 'password' && (
              <div className="mt-2 p-3 bg-light rounded border">
                <input type="password" className="form-control mb-2" placeholder="Digite a nova senha" value={tempValue} onChange={(e) => setTempValue(e.target.value)} autoFocus disabled={loading}/>
                <div className="d-flex gap-2">
                  <button className="btn btn-success btn-sm" onClick={handleSave} disabled={loading}><i className="fas fa-check"></i> Salvar</button>
                  <button className="btn btn-secondary btn-sm" onClick={cancelEditing} disabled={loading}>Cancelar</button>
                </div>
              </div>
            )}
          </div>

          <div className="alert alert-info mt-4">
            <small><i className="fas fa-info-circle me-1"></i> ID: <strong>{user.id}</strong></small><br/>
            <small><i className="fas fa-utensils me-1"></i> Restaurante: <strong>{user.has_restaurant ? 'Sim' : 'Não'}</strong></small><br/>
            <small><i className="fas fa-bicycle me-1"></i> Entregador: <strong>{user.is_delivery ? 'Sim' : 'Não'}</strong></small>
          </div>

        </div>
      </div>
    </div>
  );
}