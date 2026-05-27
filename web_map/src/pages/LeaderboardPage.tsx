import { useEffect, useState } from 'react';

const BACKEND_URL = 'http://localhost:8000/api/v1';

type LeaderboardEntry = {
  rank: number;
  user_id: string;
  username: string;
  avatar_url: string | null;
  points: number;
  reports_count: number;
  verified_reports: number;
  votes_cast: number;
};

const RANK_STYLES: Record<number, { bg: string; color: string; icon: string }> = {
  1: { bg: 'linear-gradient(135deg,#f59e0b,#fbbf24)', color: '#78350f', icon: '🥇' },
  2: { bg: 'linear-gradient(135deg,#9ca3af,#d1d5db)', color: '#1f2937', icon: '🥈' },
  3: { bg: 'linear-gradient(135deg,#b45309,#d97706)', color: '#fff', icon: '🥉' },
};

export default function LeaderboardPage() {
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const res = await fetch(`${BACKEND_URL}/leaderboard?limit=50`);
        if (!res.ok) throw new Error(`Server error ${res.status}`);
        const data: LeaderboardEntry[] = await res.json();
        setEntries(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load leaderboard');
      } finally {
        setIsLoading(false);
      }
    };
    load();
  }, []);

  const topThree = entries.slice(0, 3);
  const rest = entries.slice(3);

  return (
    <div className="page-shell">
      {/* Header */}
      <div className="page-header">
        <div>
          <p className="section-label">Gamification</p>
          <h2>Community Leaderboard</h2>
          <p className="page-desc">
            Citizens earn XP by submitting reports, getting them verified, and voting
            on community issues. Top contributors shape a safer city.
          </p>
        </div>
      </div>

      {error && (
        <div className="empty-state" style={{ marginBottom: 24 }}>
          <strong>Could not load leaderboard</strong>
          <p>{error}</p>
        </div>
      )}

      {isLoading ? (
        <div className="empty-state"><strong>Loading leaderboard…</strong></div>
      ) : (
        <>
          {/* Podium — top 3 */}
          {topThree.length > 0 && (
            <div className="podium-grid">
              {/* Reorder: 2nd | 1st | 3rd */}
              {[topThree[1], topThree[0], topThree[2]].map((entry) => {
                if (!entry) return null;
                const rs = RANK_STYLES[entry.rank];
                const isFirst = entry.rank === 1;
                return (
                  <div
                    key={entry.user_id}
                    className={`podium-card${isFirst ? ' podium-first' : ''}`}
                    style={{ order: isFirst ? 0 : entry.rank }}
                  >
                    <div className="podium-rank-badge" style={{ background: rs.bg, color: rs.color }}>
                      {rs.icon}
                    </div>
                    <div className="podium-avatar">
                      {entry.avatar_url ? (
                        <img src={entry.avatar_url} alt={entry.username} />
                      ) : (
                        <span>{entry.username.charAt(0).toUpperCase()}</span>
                      )}
                    </div>
                    <strong className="podium-name">{entry.username}</strong>
                    <div className="podium-points">{entry.points.toLocaleString()} XP</div>
                    <div className="podium-stats">
                      <span>📋 {entry.reports_count} reports</span>
                      <span>✅ {entry.verified_reports} verified</span>
                      <span>🗳 {entry.votes_cast} votes</span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Rest of leaderboard — table */}
          {rest.length > 0 && (
            <div className="panel" style={{ marginTop: 28, padding: 0, overflow: 'hidden' }}>
              <table className="lb-table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Citizen</th>
                    <th>XP Points</th>
                    <th>Reports</th>
                    <th>Verified</th>
                    <th>Votes Cast</th>
                  </tr>
                </thead>
                <tbody>
                  {rest.map((entry) => (
                    <tr key={entry.user_id}>
                      <td className="lb-rank">{entry.rank}</td>
                      <td>
                        <div className="lb-user">
                          <div className="lb-avatar">
                            {entry.avatar_url ? (
                              <img src={entry.avatar_url} alt={entry.username} />
                            ) : (
                              <span>{entry.username.charAt(0).toUpperCase()}</span>
                            )}
                          </div>
                          <span className="lb-username">{entry.username}</span>
                        </div>
                      </td>
                      <td className="lb-points">
                        <span className="lb-points-badge">{entry.points.toLocaleString()} XP</span>
                      </td>
                      <td>{entry.reports_count}</td>
                      <td>{entry.verified_reports}</td>
                      <td>{entry.votes_cast}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}
