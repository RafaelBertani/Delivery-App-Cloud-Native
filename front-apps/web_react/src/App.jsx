import { Routes, Route } from 'react-router-dom'; //npm install react-router-dom
import 'bootstrap/dist/css/bootstrap.min.css' // npm install bootstrap
import '@fortawesome/fontawesome-free/css/all.css' // npm install --save @fortawesome/fontawesome-free
import Header from "./components/Header/Header";
import Footer from "./components/Footer/Footer";
import Options from "./components/Options/Options";
import HomePage from "./pages/HomePage";
import SignInPage from "./pages/SignInPage";
import SignUpPage from "./pages/SignUpPage";

function App() {
  return (
    <div className="container-fluid p-0 d-flex flex-column min-vh-100">
      <Header />
      <Options />
      <main className="main flex-grow-1">
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/signIn" element={<SignInPage />} />
          <Route path="/signUp" element={<SignUpPage />} />
          {/* <Route path="/home" element={<LockSelectPage />} />
          <Route path="/home/:cod" element={<HomePage />} />
          <Route path="/lock-control" element={<LockControlPage />} />
          <Route path="/register-lock" element={<RegisterLockPage />} />
          <Route path="/join-lock" element={<JoinLockPage />} />
          <Route path="/logs" element={<LogsPage />} />
          <Route path="/users" element={<UsersPage />} /> */}
        </Routes>
      </main>
      {/* <Footer className="mt-auto"/> */}
    </div>
  );
}

export default App;