import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { fetchLogs } from '../../services/api';
import './AuditLogs.css';

const AuditLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    const loadLogs = async () => {
      try {
        const data = await fetchLogs();
        setLogs(data);
      } catch (error) {
        console.error('Failed to fetch audit logs:', error);
      } finally {
        setLoading(false);
      }
    };

    if (user?.role === 'admin' || user?.isAdmin) {
      loadLogs();
    }
  }, [user]);

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString();
  };

  if (!user?.role === 'admin' && !user?.isAdmin) {
    return <div>Unauthorized</div>;
  }

  return (
    <div className="audit-logs-container">
      <h2>Audit Logs</h2>
      <div className="audit-logs-list">
        {logs.length === 0 ? (
          <p>Audit Logs coming soon.</p>
        ) : (
          logs.map((log) => (
            <div key={log.id} className="audit-log-item">
              <div className="audit-log-header">
                <span className="action">{log.action}</span>
                <span className="timestamp">{formatDate(log.created_at)}</span>
              </div>
              <div className="audit-log-details">
                <p>Record: {log.record_type} #{log.record_id}</p>
                <p>User: {log.user?.username || 'System'}</p>
                {log.changes && (
                  <pre className="changes">
                    {JSON.stringify(log.changes, null, 2)}
                  </pre>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default AuditLogs;
