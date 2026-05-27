import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ErrorBoundary } from './components/ErrorBoundary';
import Navbar from './components/Navbar';
import LoginPage from './pages/LoginPage';
import MapPage from './pages/MapPage';
import ReportsPage from './pages/ReportsPage';
import LeaderboardPage from './pages/LeaderboardPage';

function AppShell() {
  const { session, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="splash-loader">
        <div className="splash-spinner" />
        <p>Loading StreetWatch…</p>
      </div>
    );
  }

  if (!session) {
    return <LoginPage />;
  }

  return (
    <>
      <Navbar />
      <div className="page-content">
        <Routes>
          <Route path="/" element={<MapPage />} />
          <Route path="/reports" element={<ReportsPage />} />
          <Route path="/leaderboard" element={<LeaderboardPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>
    </>
  );
}

export default function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <BrowserRouter>
          <AppShell />
        </BrowserRouter>
      </AuthProvider>
    </ErrorBoundary>
  );
}
