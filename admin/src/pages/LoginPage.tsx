import React, { useState } from 'react';
import { Sparkles, Lock, Mail, ArrowRight } from 'lucide-react';

interface LoginPageProps {
  onLoginSuccess: (token: string) => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [tokenInput, setTokenInput] = useState('');
  const [useTokenMode, setUseTokenMode] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (useTokenMode) {
        if (!tokenInput.trim()) throw new Error('Please enter a Firebase ID token');
        localStorage.setItem('saathira_admin_token', tokenInput.trim());
        onLoginSuccess(tokenInput.trim());
        return;
      }

      // In dev simulation mode, use the admin auth bearer key
      if (email === 'admin@saathira.com' || email.includes('admin')) {
        const dummyToken = `admin_dev_token_${Date.now()}`;
        localStorage.setItem('saathira_admin_token', dummyToken);
        onLoginSuccess(dummyToken);
      } else {
        throw new Error('Invalid admin credentials. Please use admin@saathira.com or paste Firebase Admin Token.');
      }
    } catch (err: any) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-brand-dark flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-brand-card rounded-3xl border border-brand-border p-8 space-y-6 shadow-2xl relative overflow-hidden">
        {/* Ambient background glow */}
        <div className="absolute -top-24 -right-24 w-48 h-48 bg-brand-primary/20 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-24 -left-24 w-48 h-48 bg-brand-accent/20 rounded-full blur-3xl pointer-events-none" />

        {/* Brand Header */}
        <div className="text-center space-y-2">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-brand-primary to-brand-accent flex items-center justify-center mx-auto shadow-lg shadow-purple-500/30">
            <Sparkles className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-extrabold text-white tracking-tight">Saathira Admin</h2>
          <p className="text-xs text-slate-400">
            Authorized administrator console for platform oversight & safety.
          </p>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {!useTokenMode ? (
            <>
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-slate-300">Admin Email</label>
                <div className="relative">
                  <Mail className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@saathira.com"
                    className="w-full bg-brand-dark rounded-xl border border-brand-border pl-10 pr-4 py-2.5 text-xs text-white placeholder:text-slate-600 focus:outline-none focus:border-brand-primary"
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-slate-300">Password</label>
                <div className="relative">
                  <Lock className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full bg-brand-dark rounded-xl border border-brand-border pl-10 pr-4 py-2.5 text-xs text-white placeholder:text-slate-600 focus:outline-none focus:border-brand-primary"
                  />
                </div>
              </div>
            </>
          ) : (
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-300">Firebase ID Token</label>
              <textarea
                value={tokenInput}
                onChange={(e) => setTokenInput(e.target.value)}
                placeholder="Paste Firebase Auth Bearer token..."
                rows={3}
                className="w-full bg-brand-dark rounded-xl border border-brand-border p-3 text-xs text-white placeholder:text-slate-600 focus:outline-none focus:border-brand-primary font-mono"
              />
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-brand-primary hover:bg-brand-primaryHover text-white font-bold text-xs shadow-lg shadow-purple-600/30 transition-all disabled:opacity-50"
          >
            <span>Sign In to Console</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        <div className="text-center">
          <button
            type="button"
            onClick={() => setUseTokenMode(!useTokenMode)}
            className="text-[11px] text-slate-500 hover:text-slate-300 underline"
          >
            {useTokenMode ? '← Back to Email login' : 'Or sign in with Firebase ID Token →'}
          </button>
        </div>
      </div>
    </div>
  );
};
