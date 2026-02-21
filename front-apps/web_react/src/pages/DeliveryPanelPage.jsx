import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import { useAuth } from '../contexts/AuthContext';

export default function DeliveryPanelPage() {
  const navigate = useNavigate();
  const { user } = useAuth();

  // Estados para as Entregas Atuais (Minhas Entregas)
  const [myDeliveries, setMyDeliveries] = useState([]);
  const [loadingMy, setLoadingMy] = useState(true);
  const [deliveryCodes, setDeliveryCodes] = useState({}); // Guarda os códigos digitados para cada pedido
  const [processingId, setProcessingId] = useState(null);

  // Estados para a Busca de Novas Entregas
  const [searchCity, setSearchCity] = useState('');
  const [availableDeliveries, setAvailableDeliveries] = useState([]);
  const [loadingSearch, setLoadingSearch] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);

  useEffect(() => {
    if (!user || !user.is_delivery) {
      alert("Acesso negado. Apenas entregadores podem ver esta página.");
      navigate('/');
      return;
    }
    fetchMyDeliveries();
  }, [user, navigate]);

  // 1. Busca as entregas que o motoboy já aceitou e estão em andamento
  const fetchMyDeliveries = async () => {
    const token = localStorage.getItem('token');
    try {
      setLoadingMy(true);
      // Rota imaginária no Serviço 3003 para buscar as entregas DESTE entregador
      const response = await axios.get(`http://localhost:3003/api/orders/my-active`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setMyDeliveries(response.data);
    } catch (err) {
      console.error("Erro ao buscar minhas entregas:", err);
    } finally {
      setLoadingMy(false);
    }
  };

  // 2. Busca entregas disponíveis por cidade (Status: PREPARED / WAITING_PICKUP)
  const handleSearchAvailable = async (e) => {
    e.preventDefault();
    if (!searchCity.trim()) return;

    const token = localStorage.getItem('token');
    try {
      setLoadingSearch(true);
      setHasSearched(true);
      const response = await axios.get(`http://localhost:3003/api/orders/available?city=${searchCity}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setAvailableDeliveries(response.data);
    } catch (err) {
      console.error("Erro ao buscar entregas disponíveis:", err);
      alert("Erro ao buscar novas entregas.");
    } finally {
      setLoadingSearch(false);
    }
  };

  // 3. Aceitar uma nova corrida
  const handleAcceptDelivery = async (orderId) => {
    const token = localStorage.getItem('token');
    try {
      setProcessingId(orderId);
      await axios.post(`http://localhost:3003/api/orders/${orderId}/accept`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      // Atualiza as telas
      setAvailableDeliveries(prev => prev.filter(d => d.id !== orderId));
      fetchMyDeliveries(); // Recarrega as minhas entregas para mostrar a nova
      alert("Corrida aceita com sucesso! Vá até o restaurante retirar o pedido.");
    } catch (err) {
      console.error("Erro ao aceitar corrida:", err);
      alert(err.response?.data?.message || "Erro ao aceitar a corrida.");
    } finally {
      setProcessingId(null);
    }
  };

  // 4. Avisar que Chegou no Cliente (Muda de DELIVERING para ARRIVED)
  const handleMarkAsArrived = async (orderId) => {
    const token = localStorage.getItem('token');
    try {
      setProcessingId(orderId);
      await axios.patch(`http://localhost:3003/api/orders/${orderId}/status`, 
        { status: 'ARRIVED' }, 
        { headers: { Authorization: `Bearer ${token}` } }
      );
      
      setMyDeliveries(prev => prev.map(d => d.id === orderId ? { ...d, status: 'ARRIVED' } : d));
    } catch (err) {
      console.error("Erro ao avisar chegada:", err);
      alert("Erro ao atualizar status.");
    } finally {
      setProcessingId(null);
    }
  };

  // 5. Validar o código e concluir a entrega (Muda para DELIVERED)
  const handleCompleteDelivery = async (orderId) => {
    const code = deliveryCodes[orderId];
    if (!code || code.length !== 3) {
      alert("Digite o código de 3 dígitos fornecido pelo cliente.");
      return;
    }

    const token = localStorage.getItem('token');
    try {
      setProcessingId(orderId);
      // Rota que vai verificar se o código bate com o "delivery_code" no banco
      await axios.post(`http://localhost:3003/api/orders/${orderId}/complete`, 
        { code: code },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      
      alert("Entrega concluída com sucesso! Bom trabalho!");
      setMyDeliveries(prev => prev.filter(d => d.id !== orderId)); // Remove da tela
    } catch (err) {
      console.error("Erro ao concluir entrega:", err);
      alert(err.response?.data?.message || "Código inválido ou erro ao concluir.");
    } finally {
      setProcessingId(null);
    }
  };

  // Lida com o input do código de forma independente para cada card
  const handleCodeChange = (orderId, value) => {
    setDeliveryCodes(prev => ({ ...prev, [orderId]: value }));
  };

  return (
    <div className="container mt-4 mb-5" style={{ maxWidth: '800px' }}>
      <h2 className="fw-bold mb-4 text-primary">
        <i className="fas fa-motorcycle me-3"></i>Painel do Entregador
      </h2>

      {/* ========================================== */}
      {/* SESSÃO 1: MINHAS ENTREGAS EM ANDAMENTO       */}
      {/* ========================================== */}
      <div className="card shadow-sm mb-5 border-0">
        <div className="card-header bg-dark text-white py-3">
          <h5 className="mb-0 fw-bold"><i className="fas fa-route me-2"></i> Minhas Entregas Atuais</h5>
        </div>
        <div className="card-body bg-light p-3" style={{ maxHeight: '450px', overflowY: 'auto' }}>
          
          {loadingMy ? (
            <div className="text-center py-4"><div className="spinner-border text-primary"></div></div>
          ) : myDeliveries.length === 0 ? (
            <div className="text-center text-muted py-4">
              <i className="fas fa-box-open fa-3x mb-3 text-secondary opacity-50"></i>
              <p>Você não tem entregas em andamento.</p>
            </div>
          ) : (
            myDeliveries.map(order => (
              <div key={order.id} className={`card mb-3 shadow-sm ${order.status === 'ARRIVED' ? 'border-warning' : 'border-info'}`}>
                <div className="card-body">
                  <div className="d-flex justify-content-between align-items-start mb-3">
                    <h5 className="fw-bold mb-0">Pedido #{order.id}</h5>
                    {order.status === 'DELIVERING' && <span className="badge bg-info text-dark">Em Rota</span>}
                    {order.status === 'ARRIVED' && <span className="badge bg-warning text-dark animated pulse infinite">Aguardando Cliente</span>}
                  </div>

                  {/* Endereços */}
                  <div className="mb-3 small">
                    <div className="d-flex mb-2">
                      <i className="fas fa-store text-secondary mt-1 me-2"></i>
                      <div>
                        <strong>Coleta (Restaurante):</strong><br/>
                        <span className="text-muted">{order.restaurant_address || 'Endereço do Restaurante'}</span>
                      </div>
                    </div>
                    <div className="d-flex">
                      <i className="fas fa-map-marker-alt text-danger mt-1 me-2"></i>
                      <div>
                        <strong>Entrega (Cliente):</strong><br/>
                        <span className="text-muted">{order.delivery_street}, {order.delivery_city}</span>
                      </div>
                    </div>
                  </div>

                  <hr />

                  {/* Botões de Ação Dinâmicos */}
                  {order.status === 'DELIVERING' ? (
                    <button 
                      className="btn btn-primary w-100 fw-bold py-2"
                      onClick={() => handleMarkAsArrived(order.id)}
                      disabled={processingId === order.id}
                    >
                      {processingId === order.id ? 'Atualizando...' : <><i className="fas fa-bullhorn me-2"></i>Avisar que Cheguei</>}
                    </button>
                  ) : (
                    <div className="bg-warning bg-opacity-10 p-3 rounded border border-warning">
                      <label className="fw-bold text-dark mb-2 d-block text-center">
                        O cliente deve fornecer um código de 3 dígitos:
                      </label>
                      <div className="input-group input-group-lg mb-2">
                        <input 
                          type="text" 
                          className="form-control text-center fw-bold fs-3 text-tracking-widest" 
                          placeholder="000" 
                          maxLength="3"
                          value={deliveryCodes[order.id] || ''}
                          onChange={(e) => handleCodeChange(order.id, e.target.value.replace(/\D/g, ''))} // Apenas números
                        />
                        <button 
                          className="btn btn-success fw-bold px-4"
                          onClick={() => handleCompleteDelivery(order.id)}
                          disabled={processingId === order.id || (deliveryCodes[order.id]?.length !== 3)}
                        >
                          {processingId === order.id ? 'Validando...' : 'Concluir'}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* ========================================== */}
      {/* SESSÃO 2: BUSCAR NOVAS ENTREGAS              */}
      {/* ========================================== */}
      <h4 className="fw-bold mb-3 text-success">
        <i className="fas fa-search-location me-2"></i>Buscar Novas Corridas
      </h4>
      
      <form onSubmit={handleSearchAvailable} className="mb-4">
        <div className="input-group input-group-lg shadow-sm">
          <span className="input-group-text bg-white text-success border-end-0"><i className="fas fa-city"></i></span>
          <input 
            type="text" 
            className="form-control border-start-0 ps-0" 
            placeholder="Digite a cidade (Ex: São Paulo)" 
            value={searchCity}
            onChange={(e) => setSearchCity(e.target.value)}
            required
          />
          <button className="btn btn-success fw-bold px-4" type="submit" disabled={loadingSearch}>
            {loadingSearch ? 'Buscando...' : 'Buscar'}
          </button>
        </div>
      </form>

      {/* Lista de Resultados */}
      {hasSearched && !loadingSearch && (
        <div className="row g-3">
          {availableDeliveries.length === 0 ? (
            <div className="col-12 text-center text-muted p-4 bg-light rounded border border-dashed">
              Nenhuma entrega disponível aguardando motoboy nesta cidade.
            </div>
          ) : (
            availableDeliveries.map(order => {
              // Calcula 4% do valor do pedido
              const earnings = (parseFloat(order.total_amount) * 0.04).toFixed(2).replace('.', ',');

              return (
                <div key={order.id} className="col-12 col-md-6">
                  <div className="card h-100 shadow-sm border-success border-opacity-50 hover-lift">
                    <div className="card-body">
                      
                      <div className="d-flex justify-content-between align-items-start mb-3">
                        <span className="badge bg-success bg-opacity-10 text-success border border-success">
                          Pronto para Retirada
                        </span>
                        <h4 className="fw-bold text-success mb-0">R$ {earnings}</h4>
                      </div>

                      <div className="mb-3 small">
                        <div className="mb-2">
                          <i className="fas fa-store text-secondary me-2"></i>
                          <span className="fw-bold">Restaurante:</span> {order.restaurant_address || 'Endereço Indisponível'}
                        </div>
                        <div>
                          <i className="fas fa-map-marker-alt text-danger me-2"></i>
                          <span className="fw-bold">Cliente:</span> {order.delivery_street}, {order.delivery_city}
                        </div>
                      </div>

                      <button 
                        className="btn btn-outline-success w-100 fw-bold"
                        onClick={() => handleAcceptDelivery(order.id)}
                        disabled={processingId === order.id}
                      >
                        {processingId === order.id ? 'Aceitando...' : 'Aceitar Corrida'}
                      </button>

                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}

    </div>
  );
}
