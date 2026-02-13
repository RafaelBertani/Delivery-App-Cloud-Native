import "../styles/SignInPage.css";
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import Joi from 'joi';
import axios from 'axios';

export default function SignInPage() {

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const navigate = useNavigate();
  
  function goToHome() {
    navigate('/');
  }

  function goToSignUp() {
    navigate('/signUp');
  }

  const registerSchema = Joi.object({
    email: Joi.string().email({ tlds: false }).required().messages({
      'string.email': 'Email inválido.',
      'string.empty': 'Email é obrigatório.'
    }),

    password: Joi.string().min(6).required().messages({
      'string.min': 'A senha deve ter pelo menos 6 caracteres.',
      'string.empty': 'Senha é obrigatória.'
    })
  });

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');

    const formData = {
      email,
      password
    };

    const { error } = registerSchema.validate(formData, {
      abortEarly: true
    });

    if (error) {
      setError(error.details[0].message);
      return;
    }

    console.log('Dados válidos:', formData);

    try {
      const response = await axios.post(
        'http://localhost:3001/api/auth/signin',
        formData
      );

      const { token, user } = response.data;

      // 🔐 salva token
      localStorage.setItem('token', token);

      // (opcional) salva usuário
      localStorage.setItem('user', JSON.stringify(user));

      alert('Login realizado com sucesso!');
      goToHome();

    } catch (error) {
      if (error.response?.data?.message) {
        setError(error.response.data.message);
      } else {
        setError('Erro no Login. Tente novamente.');
      }
    }
    
  }

  return (
    <div className="container">

      <form className="box" onSubmit={handleSubmit}>
        <h1>Login</h1>

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

        <button type="submit">Entrar</button>

        {error && <div style={{ color: "red", marginTop: 8 }}>{error}</div>}

        <p>
          Não tem conta? <a onClick={goToSignUp}>Criar conta</a>
        </p>

      </form>
    </div>
  );
}
