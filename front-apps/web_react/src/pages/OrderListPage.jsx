import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import { useAuth } from '../contexts/AuthContext';

const DEFAULT_LOGO = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

export default function OrderListPage() {
  const navigate = useNavigate();

  const { user, updateUserProfile } = useAuth();

  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    // Redireciona se não estiver logado
    if (!user) {
      navigate('/signIn');
    }
  }, [user, navigate]);

  useEffect(() => {
    let isMounted = true;

    async function fetchOrders() {
      const token = localStorage.getItem('token');
      if (!token) {
        navigate('/signIn');
        return;
      }

      try {
        setLoading(true);
        // Porta 3003 conforme solicitado
        const response = await axios.get('http://localhost:3003/api/orders/my-orders', {
          headers: { Authorization: `Bearer ${token}` }
        });
        
        if (isMounted) {
          setOrders(response.data);
          setError('');
        }
      } catch (err) {
        console.error("Erro ao buscar pedidos:", err);
        if (isMounted) setError('Não foi possível carregar seu histórico de pedidos.');
      } finally {
        if (isMounted) setLoading(false);
      }
    }

    fetchOrders();

    return () => { isMounted = false; };
  }, [navigate]);

  // Função para traduzir e colorir o status do pedido
  const getStatusBadge = (status) => {
    switch (status) {
      case 'PENDING':
        return <span className="badge bg-warning text-dark"><i className="fas fa-clock me-1"></i> Aguardando Confirmação</span>;
      case 'PREPARING':
        return <span className="badge bg-info text-dark"><i className="fas fa-fire me-1"></i> Preparando</span>;
      case 'PREPARED':
        return <span className="badge bg-secondary"><i className="fas fa-box me-1"></i> Pedido Pronto</span>;
      case 'DELIVERING':
        return <span className="badge bg-primary"><i className="fas fa-motorcycle me-1"></i> Saiu para Entrega</span>;
      case 'ARRIVED':
        return <span className="badge bg-dark"><i className="fas fa-map-marker-alt me-1"></i> Chegou ao Destino</span>;
      case 'DELIVERED':
        return <span className="badge bg-success"><i className="fas fa-check-circle me-1"></i> Entregue</span>;
      case 'CANCELLED':
        return <span className="badge bg-danger"><i className="fas fa-times-circle me-1"></i> Cancelado</span>;
      default:
        return <span className="badge bg-secondary">Desconhecido</span>;
    }
  };

  // Formata a data para padrão brasileiro (ex: 25/10/2023 14:30)
  const formatDate = (dateString) => {
    const options = { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' };
    return new Date(dateString).toLocaleDateString('pt-BR', options);
  };

  return (
    <div className="container mt-4 mb-5" style={{ maxWidth: '800px' }}>
      
      <div className="d-flex align-items-center mb-4 border-bottom pb-3">
        <button className="btn btn-outline-secondary me-3" onClick={() => navigate('/')}>
          <i className="fas fa-arrow-left"></i>
        </button>
        <h2 className="fw-bold mb-0">Meus Pedidos</h2>
      </div>

      {loading ? (
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status"></div>
          <p className="mt-2 text-muted">Buscando seus pedidos...</p>
        </div>
      ) : error ? (
        <div className="alert alert-danger shadow-sm text-center">
          <i className="fas fa-exclamation-triangle me-2"></i>{error}
        </div>
      ) : orders.length === 0 ? (
        <div className="text-center py-5">
          <i className="fas fa-receipt fa-4x text-light mb-3"></i>
          <h4 className="fw-bold text-muted">Nenhum pedido encontrado</h4>
          <p className="text-secondary">Você ainda não fez nenhum pedido. Que tal explorar alguns restaurantes?</p>
          <button className="btn btn-primary mt-2 px-4" onClick={() => navigate('/')}>
            Ver Restaurantes
          </button>
        </div>
      ) : (
        <div className="d-flex flex-column gap-3">
          {orders.map(order => (
            <div key={order.id} className="card shadow-sm border-0 mb-2">
              <div className="card-body">
                <div className="d-flex justify-content-between align-items-start mb-3">
                  
                  {/* Info do Restaurante e Data */}
                  <div className="d-flex align-items-center">
                    <img 
                      src={order.restaurant_logo || DEFAULT_LOGO} 
                      alt="Logo Restaurante" 
                      className="rounded-circle border me-3"
                      style={{ width: '50px', height: '50px', objectFit: 'cover' }}
                    />
                    <div>
                      <h5 className="fw-bold mb-0">{order.restaurant_name}</h5>
                      <small className="text-muted">Pedido #{order.id} • {formatDate(order.created_at)}</small>
                    </div>
                  </div>

                  {/* Preço */}
                  <div className="text-end">
                    <h5 className="fw-bold text-success mb-0">
                      R$ {parseFloat(order.total_amount).toFixed(2).replace('.', ',')}
                    </h5>
                  </div>

                  {/* Código de entrega */}
                  <div className="text-end">
                    <h5 className="fw-bold text-success mb-0">
                        Código de entrega: {order.delivery_code}
                    </h5>
                  </div>

                </div>

                <hr className="text-muted opacity-25 my-2" />

                <div className="d-flex justify-content-between align-items-center pt-2">
                  {getStatusBadge(order.status)}
                  
                  <button 
                    className="btn btn-sm btn-outline-primary fw-bold px-3 rounded-pill"
                    onClick={() => alert('Função de ver detalhes ou repetir pedido pode ir aqui!')}
                  >
                    Detalhes
                  </button>
                </div>

              </div>
            </div>
          ))}
        </div>
      )}

    </div>
  );
}