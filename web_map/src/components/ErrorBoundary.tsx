import { Component, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('🔴 ErrorBoundary caught:', error, info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: 'Manrope, sans-serif',
          background: '#eff4ff',
          padding: '2rem',
          textAlign: 'center',
        }}>
          <h2 style={{ color: '#d94040', marginBottom: '1rem' }}>⚠️ App crashed</h2>
          <pre style={{
            background: '#fff',
            border: '1px solid #e5e7eb',
            borderRadius: '12px',
            padding: '1rem 1.5rem',
            maxWidth: '700px',
            overflowX: 'auto',
            fontSize: '0.85rem',
            color: '#374151',
            textAlign: 'left',
          }}>
            {this.state.error?.message}
            {'\n\n'}
            {this.state.error?.stack}
          </pre>
          <button
            onClick={() => this.setState({ hasError: false, error: null })}
            style={{
              marginTop: '1.5rem',
              padding: '10px 24px',
              borderRadius: '999px',
              border: 0,
              background: 'linear-gradient(135deg, #2d46ba, #5a7cff)',
              color: '#fff',
              fontWeight: 700,
              cursor: 'pointer',
            }}
          >
            Try Again
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
