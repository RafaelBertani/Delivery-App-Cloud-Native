import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import 'bootstrap/dist/css/bootstrap.min.css';
import "../styles/DishesPage.css";

const DEFAULT_DISH_IMG = "https://cdn-icons-png.flaticon.com/512/3014/3014520.png";

export default function DishesPage() {
  const { id: restaurantId } = useParams();
  const navigate = useNavigate();
  const formRef = useRef(null);

  // --- ESTADOS ---
  const [dishes, setDishes] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Estado do Formulário
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [imagePreview, setImagePreview] = useState(null);

  const initialFormState = {
    name: '',
    description: '',
    price: '',
    image: '', // Base64
    is_available: true
  };
  const [formData, setFormData] = useState(initialFormState);

  useEffect(() => {
    let isMounted = true;
    fetchDishes();

    async function fetchDishes() {
      const token = localStorage.getItem('token');
      if (!token) { navigate('/signIn'); return; }

      try {
        const response = await axios.get(`http://localhost:3002/api/restaurants/${restaurantId}/list-dishes`);
        if (isMounted) {
          setDishes(response.data);
          setLoading(false);
        }
      } catch (error) {
        console.error("Erro ao buscar pratos:", error);
        if (isMounted) setLoading(false);
      }
    }
    return () => { isMounted = false; };
  }, [restaurantId, navigate]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        alert("Imagem muito grande! Máximo 2MB.");
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
        setFormData(prev => ({ ...prev, image: reader.result }));
      };
      reader.readAsDataURL(file);
    }
  };

  const resetForm = () => {
    setFormData(initialFormState);
    setImagePreview(null);
    setIsEditing(false);
    setEditingId(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const token = localStorage.getItem('token');
    setSubmitting(true);

    try {
      if (isEditing) {
        await axios.patch(`http://localhost:3002/api/restaurants/edit-dish/${editingId}`, formData, {
          headers: { Authorization: `Bearer ${token}` }
        });
        alert("Prato atualizado com sucesso!");
      } else {
        await axios.post(`http://localhost:3002/api/restaurants/${restaurantId}/create-dish`, formData, {
          headers: { Authorization: `Bearer ${token}` }
        });
        alert("Prato criado com sucesso!");
      }

      const res = await axios.get(`http://localhost:3002/api/restaurants/${restaurantId}/list-dishes`);
      setDishes(res.data);
      resetForm();

    } catch (error) {
      console.error(error);
      alert("Erro ao salvar prato.");
    } finally {
      setSubmitting(false);
    }
  };
  
  const handleEditClick = (dish) => {
    setIsEditing(true);
    setEditingId(dish.id);
    setFormData({
      name: dish.name,
      description: dish.description || '',
      price: dish.price,
      image: dish.image || '',
      is_available: dish.is_available
    });
    setImagePreview(dish.image || null);
    formRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  // Toggle de Disponibilidade (Usa a mesma rota de edit-dish)
  const handleToggleAvailability = async (dish) => {
    const token = localStorage.getItem('token');
    const newState = !dish.is_available;

    const updatedDishes = dishes.map(d => 
      d.id === dish.id ? { ...d, is_available: newState } : d
    );
    setDishes(updatedDishes);

    try {
      await axios.patch(`http://localhost:3002/api/restaurants/edit-dish/${dish.id}`, 
        { is_available: newState }, 
        { headers: { Authorization: `Bearer ${token}` } }
      );
    } catch (error) {
      console.error(error);
      alert("Erro ao mudar disponibilidade.");
      setDishes(dishes); 
    }
  };

  const handleDelete = async (id) => {
    if(!window.confirm("Tem certeza que deseja excluir este prato?")) return;
    const token = localStorage.getItem('token');
    try {
        await axios.delete(`http://localhost:3002/api/restaurants/delete-dish/${id}`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        setDishes(prev => prev.filter(d => d.id !== id));
    } catch (error) {
        alert("Erro ao deletar.");
    }
  }

  // --- RENDERIZAÇÃO ---
  return (
    <div className="container mt-4 mb-5">
      
      {/* Cabeçalho */}
      <div className="d-flex align-items-center mb-4">
        <button className="btn btn-outline-secondary me-3" onClick={() => navigate(`/my-restaurants/${restaurantId}/settings`)}>
          <i className="fas fa-arrow-left"></i> Voltar
        </button>
        <h3 className="fw-bold mb-0">Gerenciar Cardápio</h3>
      </div>

      {/* --- FORMULÁRIO (ADD/EDIT) --- */}
      <div className="card shadow-sm border-primary mb-5" ref={formRef}>
        <div className={`card-header text-white ${isEditing ? 'bg-warning' : 'bg-primary'}`}>
          <h5 className="mb-0">
            <i className={`fas ${isEditing ? 'fa-edit' : 'fa-plus-circle'} me-2`}></i>
            {isEditing ? 'Editar Prato' : 'Adicionar Novo Prato'}
          </h5>
        </div>
        <div className="card-body">
          <form onSubmit={handleSubmit}>
            <div className="row">
              
              {/* Upload de Imagem */}
              <div className="col-md-3 text-center mb-3">
                <div className="border rounded p-2 d-flex flex-column align-items-center bg-light">
                    <img 
                      src={imagePreview || DEFAULT_DISH_IMG} 
                      alt="Preview" 
                      className="img-fluid rounded mb-2"
                      style={{ maxHeight: '150px', objectFit: 'cover' }} 
                    />
                    <label className="btn btn-sm btn-outline-primary w-100">
                      Escolher Foto
                      <input type="file" hidden accept="image/*" onChange={handleImageChange} />
                    </label>
                </div>
              </div>

              {/* Campos */}
              <div className="col-md-9">
                <div className="row g-3">
                  <div className="col-md-8">
                    <label className="form-label fw-bold">Nome do Prato *</label>
                    <input type="text" className="form-control" name="name" value={formData.name} onChange={handleInputChange} required placeholder="Ex: X-Bacon Especial" />
                  </div>
                  <div className="col-md-4">
                    <label className="form-label fw-bold">Preço (R$) *</label>
                    <input type="number" step="0.01" className="form-control" name="price" value={formData.price} onChange={handleInputChange} required placeholder="0.00" />
                  </div>
                  <div className="col-12">
                    <label className="form-label">Descrição</label>
                    <textarea className="form-control" name="description" rows="2" value={formData.description} onChange={handleInputChange} placeholder="Ingredientes, tamanho, etc..." />
                  </div>
                </div>
                
                <div className="d-flex justify-content-end gap-2 mt-4">
                  {isEditing && (
                    <button type="button" className="btn btn-secondary" onClick={resetForm}>
                      Cancelar Edição
                    </button>
                  )}
                  <button type="submit" className={`btn ${isEditing ? 'btn-warning' : 'btn-success'} fw-bold px-4`} disabled={submitting}>
                    {submitting ? 'Salvando...' : (isEditing ? 'Atualizar Prato' : 'Cadastrar Prato')}
                  </button>
                </div>
              </div>

            </div>
          </form>
        </div>
      </div>

      {/* --- LISTA DE PRATOS --- */}
      <h4 className="fw-bold mb-3"><i className="fas fa-list me-2"></i>Pratos Cadastrados</h4>
      
      {loading ? (
        <div className="text-center py-5"><div className="spinner-border text-primary"></div></div>
      ) : (
        <div className="row g-4">
          {dishes.length === 0 && (
            <div className="col-12 text-center text-muted py-4">
              Nenhum prato cadastrado ainda. Use o formulário acima.
            </div>
          )}

          {dishes.map((dish) => (
            <div className="col-md-6 col-lg-4" key={dish.id}>
              <div className={`card h-100 shadow-sm dish-card ${!dish.is_available ? 'border-danger bg-light' : 'border-success'}`}>
                
                {/* Imagem do Card */}
                <div className="position-relative">
                    <img 
                    src={dish.image || DEFAULT_DISH_IMG} 
                    className="card-img-top" 
                    alt={dish.name}
                    style={{ height: '200px', objectFit: 'cover', opacity: dish.is_available ? 1 : 0.6 }} 
                    />
                    <span className="position-absolute bottom-0 end-0 bg-dark text-white px-3 py-1 m-2 rounded fw-bold">
                        R$ {parseFloat(dish.price).toFixed(2).replace('.', ',')}
                    </span>
                </div>

                <div className="card-body d-flex flex-column">
                  <div className="d-flex justify-content-between align-items-start mb-2">
                    <h5 className="card-title fw-bold mb-0 text-truncate">{dish.name}</h5>
                  </div>
                  
                  <p className="card-text text-muted small flex-grow-1">
                    {dish.description || "Sem descrição."}
                  </p>

                  <hr />

                  <div className="d-flex justify-content-between align-items-center">
                    {/* Switch de Disponibilidade */}
                    <div className="form-check form-switch">
                        <input 
                            className="form-check-input" 
                            type="checkbox" 
                            role="switch"
                            checked={dish.is_available}
                            onChange={() => handleToggleAvailability(dish)}
                            style={{ cursor: 'pointer' }}
                        />
                        <label className={`form-check-label fw-bold small ${dish.is_available ? 'text-success' : 'text-danger'}`}>
                            {dish.is_available ? 'DISPONÍVEL' : 'ESGOTADO'}
                        </label>
                    </div>

                    {/* Botões de Editar e de Excluir */}
                    <div>
                        <button className="btn btn-sm btn-outline-primary me-2" onClick={() => handleEditClick(dish)} title="Editar">
                            <i className="fas fa-pen"></i>
                        </button>
                        <button className="btn btn-sm btn-outline-danger" onClick={() => handleDelete(dish.id)} title="Excluir">
                            <i className="fas fa-trash"></i>
                        </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

    </div>
  );
}