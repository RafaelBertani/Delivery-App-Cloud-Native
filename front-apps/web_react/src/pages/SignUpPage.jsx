import "../styles/SignUpPage.css";
import { useNavigate } from 'react-router-dom';
import {useState} from 'react';
import Joi from 'joi';
import axios from 'axios';

export default function SignUpPage() {

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');

  const navigate = useNavigate();
  
  function goToHome() {
    navigate('/');
  }

  function goToSignIn() {
    navigate('/signIn');
  }

  const registerSchema = Joi.object({
    name: Joi.string().min(3).required().messages({
      'string.empty': 'Nome é obrigatório.',
      'string.min': 'Nome deve ter no mínimo 3 caracteres.'
    }),

    email: Joi.string().email({ tlds: false }).required().messages({
      'string.email': 'Email inválido.',
      'string.empty': 'Email é obrigatório.'
    }),

    password: Joi.string().min(6).required().messages({
      'string.min': 'A senha deve ter pelo menos 6 caracteres.',
      'string.empty': 'Senha é obrigatória.'
    }),

    confirmPassword: Joi.string()
      .valid(Joi.ref('password'))
      .required()
      .messages({
        'any.only': 'As senhas não conferem.',
        'string.empty': 'Confirmação de senha é obrigatória.'
      })
  });

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');

    const formData = {
      name,
      email,
      password,
      confirmPassword
    };

    const { error } = registerSchema.validate(formData, {
      abortEarly: true
    });

    if (error) {
      setError(error.details[0].message);
      return;
    }

    //console.log('Dados válidos:', formData);

    try {
      await axios.post('http://localhost:3001/api/auth/signup', formData );
      alert('Cadastro realizado com sucesso!');
      goToSignIn(); //navigate('/signin');
    } catch (error) {
      if (error.response?.data?.error) {
        setError(error.response.data.error);
      } else {
        setError('Erro no cadastro. Tente novamente.');
      }
    }
  }

  return (
    <div className="container">
      
      <form className="box" onSubmit={handleSubmit}>
        <h1>Criar conta</h1>

        <input
          type="text"
          placeholder="Nome"
          className="input-field"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
        />
        <input
          type="email"
          placeholder="Email"
          className="input-field"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Senha"
          className="input-field"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          minLength={6}
        />
        <input
          type="password"
          placeholder="Confirmar Senha"
          className="input-field"
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          required
          minLength={6}
        />
        <button type="submit">Registrar</button>

        {error && <div style={{ color: "red", marginTop: 8 }}>{error}</div>}

        <p>
          Já tem conta? <a onClick={goToSignIn}>Entrar</a>
        </p>
        
      </form>
    </div>
  );
}
