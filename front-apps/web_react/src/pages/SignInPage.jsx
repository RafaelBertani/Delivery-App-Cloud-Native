import "../styles/SignInPage.css";
import { useNavigate } from 'react-router-dom';

export default function SignInPage() {

  const navigate = useNavigate();
  
  function goToHome() {
    navigate('/');
  }

  function goToSignUp() {
    navigate('/signUp');
  }

  return (
    <div className="container">

      <form className="box">
        <h1>Login</h1>

        <input type="email" placeholder="Email" />
        <input type="password" placeholder="Senha" />

        <button type="submit">Entrar</button>

        <p>
          Não tem conta? <a onClick={goToSignUp}>Criar conta</a>
        </p>

      </form>
    </div>
  );
}
