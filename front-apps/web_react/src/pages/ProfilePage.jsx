import "../styles/ProfilePage.css";
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import { useAuth } from '../contexts/AuthContext';

const DEFAULT_AVATAR = "https://cdn-icons-png.flaticon.com/512/149/149071.png";

export default function ProfilePage() {
  const navigate = useNavigate();
  const { user, updateUserProfile } = useAuth();
  
  // Estados do Perfil Original
  const [editingField, setEditingField] = useState(null);
  const [tempValue, setTempValue] = useState("");
  const [loading, setLoading] = useState(false); 

  // Novos Estados para Endereços
  const [addresses, setAddresses] = useState([]);
  const [loadingAddresses, setLoadingAddresses] = useState(true);
  const [showAddressForm, setShowAddressForm] = useState(false);
  const [newAddress, setNewAddress] = useState({
    name: '', street: '', city: '', state: '', zip_code: ''
  });

  useEffect(() => {
    if (!user) {
      navigate('/signIn');
    } else {
      fetchAddresses();
    }
  }, [user, navigate]);

  // ==========================================
  // FUNÇÕES DE PERFIL (Mantidas intactas)
  // ==========================================
  async function saveToBackend(field, value) {
    const token = localStorage.getItem('token');
    if (!token) { navigate('/signIn'); return false; }

    try {
      setLoading(true);
      const response = await axios.put('http://localhost:3001/api/auth/edit', 
        { [field]: value }, 
        { headers: { Authorization: `Bearer ${token}` } }
      );
      updateUserProfile(response.data.user);
      setLoading(false);
      return true; 
    } catch (error) {
      setLoading(false);
      console.error(error);
      if (error.response?.status === 401) {
        alert("Sessão expirada. Faça login novamente.");
        localStorage.removeItem('token');
        navigate('/signIn');
      } else {
        alert(error.response?.data?.message || "Erro ao atualizar perfil.");
      }
      return false; 
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
        const success = await saveToBackend('profile_pic', reader.result); 
        if (success) alert("Foto atualizada com sucesso!");
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
    if (success) setEditingField(null); 
  }


  // ==========================================
  // NOVAS FUNÇÕES DE ENDEREÇO
  // ==========================================
  
  // 1. Buscar endereços
  async function fetchAddresses() {
    const token = localStorage.getItem('token');
    try {
      setLoadingAddresses(true);
      const res = await axios.get('http://localhost:3001/api/auth/addresses', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setAddresses(res.data);
    } catch (err) {
      console.error("Erro ao buscar endereços:", err);
    } finally {
      setLoadingAddresses(false);
    }
  }

  // 2. Salvar novo endereço
  async function handleSaveAddress(e) {
    e.preventDefault();
    const token = localStorage.getItem('token');
    try {
      setLoading(true);
      await axios.post('http://localhost:3001/api/auth/addresses', newAddress, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setShowAddressForm(false);
      setNewAddress({ name: '', street: '', city: '', state: '', zip_code: '' });
      fetchAddresses(); // Recarrega a lista
    } catch (err) {
      console.error("Erro ao salvar endereço:", err);
      alert("Erro ao adicionar endereço.");
    } finally {
      setLoading(false);
    }
  }

  // 3. Ativar um endereço (o backend deve desativar os outros)
  async function handleToggleActive(addressId) {
    const token = localStorage.getItem('token');
    
    // Atualização Otimista: Atualiza a tela antes mesmo de o backend responder para parecer instantâneo
    setAddresses(prev => prev.map(addr => ({
      ...addr,
      is_active: addr.id === addressId
    })));

    try {
      await axios.put(`http://localhost:3001/api/auth/addresses/${addressId}/active`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
    } catch (err) {
      console.error("Erro ao ativar endereço:", err);
      fetchAddresses(); // Se der erro, desfaz a atualização otimista buscando do banco de novo
    }
  }

  if (!user) return null; 

  return (
    <div className="container mt-5 mb-5 d-flex justify-content-center">
      <div className="card shadow p-4" style={{ width: '100%', maxWidth: '600px' }}>
        
        {loading && (
          <div className="position-absolute top-0 start-0 w-100 h-100 bg-white opacity-75 d-flex justify-content-center align-items-center" style={{ zIndex: 10 }}>
            <div className="spinner-border text-primary" role="status"></div>
          </div>
        )}

        {/* CABEÇALHO DO PERFIL */}
        <div className="text-center mb-4">
          <div className="position-relative d-inline-block">
            <img 
              src={user.pic || DEFAULT_AVATAR} 
              alt="Profile" 
              className="rounded-circle mb-2 border border-3 border-secondary"
              style={{ width: '120px', height: '120px', objectFit: 'cover' }}
            />
            <input type="file" id="avatarInput" accept="image/*" style={{ display: 'none' }} onChange={handleImageChange} disabled={loading} />
            <label htmlFor="avatarInput" className="position-absolute bottom-0 end-0 bg-primary text-white rounded-circle p-2 shadow-sm" style={{ cursor: loading ? 'wait' : 'pointer', transform: 'translate(10%, -20%)' }} title="Trocar foto">
              <i className="fas fa-camera"></i>
            </label>
          </div>
          <h4 className="fw-bold mt-2">{user.name}</h4>
          <span className="badge bg-secondary">{user.role}</span>
        </div>

        {/* DADOS CADASTRAIS */}
        <div className="card-body p-0">
          <div className="mb-3">
            <label className="form-label text-muted small fw-bold">E-MAIL</label>
            <div className="d-flex justify-content-between align-items-center">
              <span className="fs-6">{user.email}</span>
            </div>
          </div>

          <div className="mb-4">
            <label className="form-label text-muted small fw-bold">SENHA</label>
            <div className="d-flex justify-content-between align-items-center">
              <span className="fs-6 text-muted">••••••••</span> 
              {editingField !== 'password' && (
                <button className="btn btn-link btn-sm text-decoration-none p-0" onClick={() => startEditing('password', '')} disabled={loading}>
                  <i className="fas fa-pencil-alt"></i> Alterar
                </button>
              )}
            </div>
            {editingField === 'password' && (
              <div className="mt-2 p-3 bg-light rounded border">
                <input type="password" className="form-control form-control-sm mb-2" placeholder="Nova senha" value={tempValue} onChange={(e) => setTempValue(e.target.value)} autoFocus disabled={loading}/>
                <div className="d-flex gap-2">
                  <button className="btn btn-success btn-sm" onClick={handleSave} disabled={loading}><i className="fas fa-check"></i> Salvar</button>
                  <button className="btn btn-secondary btn-sm" onClick={cancelEditing} disabled={loading}>Cancelar</button>
                </div>
              </div>
            )}
          </div>
        </div>

        <hr className="my-4" />

        {/* SESSÃO DE ENDEREÇOS */}
        <div className="addresses-section">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h5 className="fw-bold mb-0 text-primary">
              <i className="fas fa-map-marker-alt me-2"></i>Meus Endereços
            </h5>
            <button 
              className="btn btn-outline-primary btn-sm fw-bold" 
              onClick={() => setShowAddressForm(!showAddressForm)}
            >
              {showAddressForm ? 'Cancelar' : '+ Novo'}
            </button>
          </div>

          {/* Formulário de Novo Endereço */}
          {showAddressForm && (
            <form onSubmit={handleSaveAddress} className="bg-light p-3 rounded border mb-3 shadow-sm">
              <div className="row g-2">
                <div className="col-12">
                  <input type="text" className="form-control form-control-sm" placeholder="Nome (Ex: Casa, Trabalho)*" required 
                    value={newAddress.name} onChange={e => setNewAddress({...newAddress, name: e.target.value})} />
                </div>
                <div className="col-8">
                  <input type="text" className="form-control form-control-sm" placeholder="Rua e Número*" required 
                    value={newAddress.street} onChange={e => setNewAddress({...newAddress, street: e.target.value})} />
                </div>
                <div className="col-4">
                  <input type="text" className="form-control form-control-sm" placeholder="CEP*" required 
                    value={newAddress.zip_code} onChange={e => setNewAddress({...newAddress, zip_code: e.target.value})} />
                </div>
                <div className="col-8">
                  <input type="text" className="form-control form-control-sm" placeholder="Cidade*" required 
                    value={newAddress.city} onChange={e => setNewAddress({...newAddress, city: e.target.value})} />
                </div>
                <div className="col-4">
                  <input type="text" className="form-control form-control-sm" placeholder="Estado*" required 
                    value={newAddress.state} onChange={e => setNewAddress({...newAddress, state: e.target.value})} />
                </div>
                <div className="col-12 text-end mt-2">
                  <button type="submit" className="btn btn-success btn-sm px-4 fw-bold">Salvar Endereço</button>
                </div>
              </div>
            </form>
          )}

          {/* Lista de Endereços com Scroll */}
          <div className="address-list pe-2" style={{ maxHeight: '250px', overflowY: 'auto' }}>
            {loadingAddresses ? (
              <div className="text-center py-3 text-muted"><div className="spinner-border spinner-border-sm"></div> Carregando...</div>
            ) : addresses.length === 0 ? (
              <div className="text-center py-4 bg-light rounded text-muted small">
                Você ainda não tem endereços cadastrados.
              </div>
            ) : (
              addresses.map(addr => (
                <div key={addr.id} className={`card mb-2 border ${addr.is_active ? 'border-primary bg-primary bg-opacity-10' : 'border-secondary-subtle'}`}>
                  <div className="card-body p-3 d-flex justify-content-between align-items-center">
                    <div>
                      <h6 className="fw-bold mb-1 text-dark">
                        {addr.name} 
                        {addr.is_active && <span className="badge bg-primary ms-2" style={{fontSize: '0.65em'}}>ATUAL</span>}
                      </h6>
                      <p className="mb-0 small text-muted lh-sm">
                        {addr.street}<br/>
                        {addr.city} - {addr.state}, {addr.zip_code}
                      </p>
                    </div>
                    
                    {/* Toggle Switch */}
                    <div className="form-check form-switch ms-3">
                      <input 
                        className="form-check-input" 
                        type="checkbox" 
                        role="switch" 
                        style={{ cursor: 'pointer', transform: 'scale(1.2)' }}
                        checked={addr.is_active}
                        onChange={() => handleToggleActive(addr.id)}
                      />
                    </div>

                  </div>
                </div>
              ))
            )}
          </div>
        </div>

      </div>
    </div>
  );
}