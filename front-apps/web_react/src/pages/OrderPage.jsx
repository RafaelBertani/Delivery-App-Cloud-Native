import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import '../styles/OrderPage.css';

const DEFAULT_LOGO = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";
const DEFAULT_DISH = "https://cdn-icons-png.flaticon.com/512/3014/3014520.png";

export default function OrderPage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [restaurant, setRestaurant] = useState(null);
  const [dishes, setDishes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [isCheckingOut, setIsCheckingOut] = useState(false);

  // O carrinho será um objeto onde a chave é o ID do prato e o valor é a quantidade
  // Exemplo: { 1: 2, 5: 1 } -> 2x prato id 1, 1x prato id 5
  const [cart, setCart] = useState({});

  // 1. Busca os Dados (Restaurante + Pratos)
  useEffect(() => {
    let isMounted = true;

    async function fetchMenuData() {
      try {
        setLoading(true);
        
        // Dispara as duas requisições ao mesmo tempo para ser mais rápido
        const [restRes, dishesRes] = await Promise.all([
          axios.get(`http://localhost:3002/api/restaurants/${id}`),
          axios.get(`http://localhost:3002/api/restaurants/${id}/list-dishes`)
        ]);

        if (isMounted) {
          setRestaurant(restRes.data);
          // Filtramos para mostrar apenas os pratos disponíveis ao cliente
          setDishes(dishesRes.data.filter(dish => dish.is_available));
        }
      } catch (err) {
        console.error("Erro ao carregar cardápio:", err);
        if (isMounted) setError("Não foi possível carregar o cardápio deste restaurante.");
      } finally {
        if (isMounted) setLoading(false);
      }
    }

    fetchMenuData();

    return () => { isMounted = false; };
  }, [id]);

  // 2. Funções do Carrinho
  const handleAdd = (dishId) => {
    setCart(prev => ({
      ...prev,
      [dishId]: (prev[dishId] || 0) + 1
    }));
  };

  const handleRemove = (dishId) => {
    setCart(prev => {
      const newCart = { ...prev };
      if (newCart[dishId] > 1) {
        newCart[dishId] -= 1;
      } else {
        delete newCart[dishId]; // Remove do objeto se chegar a zero
      }
      return newCart;
    });
  };

  // 3. Cálculos do Carrinho
  // Soma o (preço do prato * quantidade no carrinho)
  const cartTotal = dishes.reduce((total, dish) => {
    const quantity = cart[dish.id] || 0;
    return total + (parseFloat(dish.price) * quantity);
  }, 0);

  // Conta quantos itens totais existem no carrinho
  const totalItems = Object.values(cart).reduce((sum, qtd) => sum + qtd, 0);

  // 4. Finalizar Pedido
  const handleCheckout = async () => {
    // 1. Verifica se o usuário está logado
    const token = localStorage.getItem('token');
    if (!token) {
      alert("Você precisa estar logado para finalizar o pedido!");
      navigate('/signIn'); // redireciona para o login
      return;
    }

    // 2. Transforma o carrinho (Objeto) no formato esperado pelo Backend (Array)
    // Ex: { '1': 2, '5': 1 }  --->  [{ dish_id: 1, quantity: 2 }, { dish_id: 5, quantity: 1 }]
    const items = Object.entries(cart).map(([dishId, quantity]) => ({
      dish_id: parseInt(dishId),
      quantity: quantity
    }));

    // Garante que não vai enviar um pedido vazio pro backend
    if (items.length === 0) {
      alert("Seu carrinho está vazio!");
      return;
    }

    // 3. Monta o Payload (pacote de dados)
    const payload = {
      restaurant_id: parseInt(id),
      items: items
    };

    try {
      // INÍCIO DO LOADING: Bloqueia o botão
      setIsCheckingOut(true);
      
      // 4. Dispara a requisição para criar o pedido
      const response = await axios.post('http://localhost:3002/api/orders/create', payload, {
        headers: { Authorization: `Bearer ${token}` }
      });

      // Sucesso!
      alert("Pedido realizado com sucesso!");
      
      // Limpa o carrinho para não ficar lixo na tela
      setCart({});
      
      // Redireciona o usuário para a Home (ou para a tela de rastreio, se tiver)
      navigate('/');

    } catch (error) {
      console.error("Erro ao finalizar pedido:", error);
      alert(error.response?.data?.message || "Ocorreu um erro ao processar seu pedido. Tente novamente.");
      
    } finally {
      // FIM DO LOADING: Libera o botão de novo
      // O bloco finally executa SEMPRE, dando erro ou dando sucesso.
      setIsCheckingOut(false);
    }
  };

  // --- RENDERIZAÇÃO ---
  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center vh-100">
        <div className="spinner-border text-primary" style={{ width: '3rem', height: '3rem' }}></div>
      </div>
    );
  }

  if (error || !restaurant) {
    return (
      <div className="container mt-5 text-center">
        <div className="alert alert-danger">{error || "Restaurante não encontrado."}</div>
        <button className="btn btn-outline-primary" onClick={() => navigate('/')}>Voltar ao Início</button>
      </div>
    );
  }

  return (
    // Adicionamos um padding-bottom grande para a barra fixa não cobrir o último prato
    <div className="container mt-4 pb-cart"> 
      
      {/* --- CABEÇALHO DO RESTAURANTE --- */}
      <div className="d-flex align-items-center mb-4 pb-3 border-bottom">
        <img 
          src={restaurant.logo || DEFAULT_LOGO} 
          alt={restaurant.name} 
          className="rounded-circle shadow-sm me-3 border"
          style={{ width: '80px', height: '80px', objectFit: 'cover' }}
        />
        <div>
          <h2 className="fw-bold mb-1">{restaurant.name}</h2>
          <p className="text-muted mb-1 small">{restaurant.description}</p>
          <div className="text-secondary small">
            <i className="fas fa-map-marker-alt text-danger me-1"></i>
            {restaurant.street}, {restaurant.city}
          </div>
        </div>
      </div>

      {/* --- LISTA DE PRATOS --- */}
      <h5 className="fw-bold mb-4">Cardápio</h5>

      {dishes.length === 0 ? (
        <div className="text-center text-muted py-5">
          <i className="fas fa-utensils fa-3x mb-3 text-light"></i>
          <p>Nenhum prato disponível no momento.</p>
        </div>
      ) : (
        <div className="row g-3">
          {dishes.map(dish => {
            const quantity = cart[dish.id] || 0;

            return (
              <div className="col-12 col-md-6" key={dish.id}>
                <div className="card shadow-sm border-0 h-100 dish-item-card">
                  <div className="card-body d-flex p-3">
                    
                    {/* Info do Prato */}
                    <div className="flex-grow-1 pe-3 d-flex flex-column justify-content-between">
                      <div>
                        <h6 className="fw-bold mb-1">{dish.name}</h6>
                        <p className="text-muted small mb-2 dish-description">
                          {dish.description}
                        </p>
                      </div>
                      <div className="fw-bold text-success">
                        R$ {parseFloat(dish.price).toFixed(2).replace('.', ',')}
                      </div>
                    </div>

                    {/* Imagem e Controles */}
                    <div className="d-flex flex-column align-items-center justify-content-between" style={{ width: '100px' }}>
                      <img 
                        src={dish.image || DEFAULT_DISH} 
                        alt={dish.name} 
                        className="rounded mb-2"
                        style={{ width: '90px', height: '90px', objectFit: 'cover' }}
                      />
                      
                      {/* Controles de Quantidade */}
                      <div className="d-flex align-items-center bg-light rounded-pill px-2 py-1 border">
                        <button 
                          className="btn btn-sm btn-link text-danger text-decoration-none p-0 px-1"
                          onClick={() => handleRemove(dish.id)}
                          disabled={quantity === 0}
                        >
                          <i className="fas fa-minus"></i>
                        </button>
                        
                        <span className="fw-bold mx-2" style={{ minWidth: '15px', textAlign: 'center' }}>
                          {quantity}
                        </span>
                        
                        <button 
                          className="btn btn-sm btn-link text-success text-decoration-none p-0 px-1"
                          onClick={() => handleAdd(dish.id)}
                        >
                          <i className="fas fa-plus"></i>
                        </button>
                      </div>
                    </div>

                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* --- BARRA FIXA DO CARRINHO (Aparece só se tiver itens) --- */}
      {totalItems > 0 && (

          <div className="container d-flex justify-content-between align-items-center" style={{ maxWidth: '800px' }}>
            
            {/* Resumo */}
            <div>
              <div className="text-muted small">Total com {totalItems} item(ns)</div>
              <h4 className="fw-bold text-success mb-0">
                R$ {cartTotal.toFixed(2).replace('.', ',')}
              </h4>
            </div>

            {/* Botão de Avançar */}
            <button 
                className="btn btn-primary btn-lg fw-bold px-4 rounded-pill shadow-sm" 
                onClick={handleCheckout}
                disabled={isCheckingOut} // <--- Desabilita o botão
                >
                {isCheckingOut ? (
                    <>Processando <span className="spinner-border spinner-border-sm ms-2"></span></>
                ) : (
                    <>Fazer Pedido <i className="fas fa-chevron-right ms-2"></i></>
                )}
            </button>
            
            
          </div>

      )}

    </div>
  );
}