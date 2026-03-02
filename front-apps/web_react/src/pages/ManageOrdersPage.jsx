import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';

export default function ManageOrdersPage() {
  const { id } = useParams(); // ID do restaurante
  const navigate = useNavigate();
  
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [processingId, setProcessingId] = useState(null);

  useEffect(() => {
    fetchOrders();
  }, [id]);

  const fetchOrders = async () => {
    const token = localStorage.getItem('token');
    if (!token) { navigate('/signIn'); return; }

    try {
      setLoading(true);
      const response = await axios.get(`http://localhost:3003/api/orders/restaurant/${id}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setOrders(response.data);
      setError('');
    } catch (err) {
      console.error("Erro ao buscar pedidos:", err);
      setError('Não foi possível carregar a lista de pedidos.');
    } finally {
      setLoading(false);
    }
  };

  // Função genérica para avançar o status do pedido
  const handleUpdateStatus = async (orderId, newStatus) => {
    const token = localStorage.getItem('token');
    
    // --- NOVO: Adiciona confirmação se o novo status for DELIVERING ---
    if (newStatus === 'DELIVERING') {
      const isConfirmed = window.confirm("O entregador informou o código correto e retirou o pedido?");
      if (!isConfirmed) return; // Se ele cancelar, não faz nada.
    }

    try {
      setProcessingId(orderId);
      
      await axios.patch(`http://localhost:3003/api/orders/${orderId}/status`, 
        { status: newStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      setOrders(prevOrders => 
        prevOrders.map(order => 
          order.id === orderId ? { ...order, status: newStatus } : order
        )
      );

    } catch (err) {
      console.error(`Erro ao atualizar pedido para ${newStatus}:`, err);
      alert(err.response?.data?.message || "Erro ao atualizar status do pedido.");
    } finally {
      setProcessingId(null);
    }
  };

  const formatTime = (dateString) => {
    return new Date(dateString).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  };

  // Separação dos pedidos em 3 grupos
  const pendingOrders = orders.filter(o => o.status === 'PENDING');
  const preparingOrders = orders.filter(o => o.status === 'PREPARING');
  const preparedOrders = orders.filter(o => o.status === 'PREPARED');

  // Componente interno para o Card do Pedido
  const OrderCard = ({ order }) => {
    // Define as cores e textos baseado no status atual
    let cardStyle = "";
    let headerStyle = "";
    
    if (order.status === 'PENDING') {
      cardStyle = "border-warning";
      headerStyle = "bg-warning text-dark";
    } else if (order.status === 'PREPARING') {
      cardStyle = "border-info";
      headerStyle = "bg-info text-white";
    } else if (order.status === 'PREPARED') {
      cardStyle = "border-success";
      headerStyle = "bg-success text-white";
    }

    return (
      <div className={`card shadow-sm mb-4 ${cardStyle}`}>
        <div className={`card-header d-flex justify-content-between align-items-center ${headerStyle}`}>
          <h5 className="mb-0 fw-bold">Pedido #{order.id}</h5>
          <span className="small fw-bold"><i className="fas fa-clock me-1"></i> {formatTime(order.created_at)}</span>
        </div>
        
        <div className="card-body p-0">
          <div className="p-3 bg-light border-bottom" style={{ maxHeight: '180px', overflowY: 'auto' }}>
            <ul className="list-unstyled mb-0">
              {order.items?.map((item, index) => (
                <li key={index} className="d-flex justify-content-between mb-2 pb-2 border-bottom border-secondary-subtle">
                  <div>
                    <span className="fw-bold me-2">{item.quantity}x</span>
                    <span>{item.dish_name || `Prato #${item.dish_id}`}</span>
                  </div>
                  <div className="text-muted">
                    R$ {(parseFloat(item.unit_price) * item.quantity).toFixed(2).replace('.', ',')}
                  </div>
                </li>
              ))}
            </ul>
          </div>

          <div className="p-3 d-flex justify-content-between align-items-center bg-white">
            <div>
              <span className="text-muted small d-block">Total do Pedido</span>
              <h5 className="fw-bold text-success mb-0">
                R$ {parseFloat(order.total_amount).toFixed(2).replace('.', ',')}
              </h5>
            </div>
            
            {/* Renderização condicional dos botões de ação */}
            <div>
              {order.status === 'PENDING' && (
                <button 
                  className="btn btn-warning fw-bold px-3" 
                  onClick={() => handleUpdateStatus(order.id, 'PREPARING')}
                  disabled={processingId === order.id}
                >
                  {processingId === order.id ? (
                    <span className="spinner-border spinner-border-sm" role="status"></span>
                  ) : (
                    <><i className="fas fa-check me-2"></i> Aceitar</>
                  )}
                </button>
              )}

              {order.status === 'PREPARING' && (
                <button 
                  className="btn btn-info text-white fw-bold px-3" 
                  onClick={() => handleUpdateStatus(order.id, 'PREPARED')}
                  disabled={processingId === order.id}
                >
                  {processingId === order.id ? (
                    <span className="spinner-border spinner-border-sm" role="status"></span>
                  ) : (
                    <><i className="fas fa-box me-2"></i> Pronto p/ Retirada</>
                  )}
                </button>
              )}

              {/* --- NOVO: Botão para confirmar a retirada do pedido --- */}
              {order.status === 'PREPARED' && (
                <button 
                  className="btn btn-outline-success fw-bold px-3" 
                  onClick={() => handleUpdateStatus(order.id, 'DELIVERING')}
                  disabled={processingId === order.id}
                >
                  {processingId === order.id ? (
                    <span className="spinner-border spinner-border-sm" role="status"></span>
                  ) : (
                    <><i className="fas fa-motorcycle me-2"></i> Confirmar Retirada</>
                  )}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  };

  if (loading) return <div className="text-center mt-5"><div className="spinner-border text-primary"></div></div>;

  return (
    <div className="container mt-4 mb-5" style={{ maxWidth: '900px' }}>
      
      <div className="d-flex align-items-center mb-4">
        <button className="btn btn-outline-secondary me-3" onClick={() => navigate(`/my-restaurants`)}>
          <i className="fas fa-arrow-left"></i> Voltar
        </button>
        <h2 className="fw-bold mb-0">Gerenciar Pedidos</h2>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <div className="row">
        {/* SESSÃO 1: PENDENTES */}
        <div className="col-12 mb-4">
          <h4 className="fw-bold text-warning mb-3">
            <i className="fas fa-bell me-2"></i> Novos Pedidos ({pendingOrders.length})
          </h4>
          {pendingOrders.length === 0 ? (
            <div className="p-3 text-center bg-light rounded text-muted mb-4">Nenhum pedido pendente.</div>
          ) : (
            <div className="row">
              {pendingOrders.map(order => (
                <div className="col-md-6" key={order.id}><OrderCard order={order} /></div>
              ))}
            </div>
          )}
        </div>

        <hr className="text-muted" />

        {/* SESSÃO 2: EM PREPARO */}
        <div className="col-12 mb-4 mt-3">
          <h4 className="fw-bold text-info mb-3">
            <i className="fas fa-fire me-2"></i> Em Preparo ({preparingOrders.length})
          </h4>
          {preparingOrders.length === 0 ? (
            <div className="p-3 text-center bg-light rounded text-muted mb-4">Nenhum pedido em preparo.</div>
          ) : (
            <div className="row">
              {preparingOrders.map(order => (
                <div className="col-md-6" key={order.id}><OrderCard order={order} /></div>
              ))}
            </div>
          )}
        </div>

        <hr className="text-muted" />

        {/* SESSÃO 3: PRONTOS / AGUARDANDO RETIRADA */}
        <div className="col-12 mt-3">
          <h4 className="fw-bold text-success mb-3">
            <i className="fas fa-box-open me-2"></i> Aguardando Retirada ({preparedOrders.length})
          </h4>
          {preparedOrders.length === 0 ? (
            <div className="p-3 text-center bg-light rounded text-muted">Nenhum pedido aguardando entregador.</div>
          ) : (
            <div className="row">
              {preparedOrders.map(order => (
                <div className="col-md-6 mb-4" key={order.id}>
                  
                  <div className="d-flex justify-content-between align-items-end mb-2 px-1">
                    <span className="text-success small fw-bold">
                      <i className="fas fa-motorcycle me-1"></i> Aguardando motoboy
                    </span>
                    <span className="badge bg-dark text-warning fs-5 border border-warning shadow-sm">
                      CÓDIGO: {order.pickup_code || '---'}
                    </span>
                  </div>
                  
                  <OrderCard order={order} />
                </div>
              ))}
            </div>
          )}
        </div>

      </div>
    </div>
  );
}