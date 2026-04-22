import React from 'react';

function LogList({ logs, onDelete, onStatusChange }) {
  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  const getStatusClass = (status) => {
    const statusClasses = {
      'pending': 'status-pending',
      'processing': 'status-processing',
      'done': 'status-done',
      'error': 'status-error'
    };
    return statusClasses[status] || 'status-pending';
  };

  const handleStatusChange = async (logId, newStatus) => {
    if (onStatusChange) {
      await onStatusChange(logId, newStatus);
    }
  };

  if (logs.length === 0) {
    return <div className="no-logs">No command entries found</div>;
  }

  return (
    <div className="log-list">
      {logs.map((log) => (
        <div key={log.id} className={`log-item ${getStatusClass(log.status)}`}>
          <div className="log-header">
            <span className="log-timestamp">{formatTimestamp(log.timestamp)}</span>
            <div className="log-header-actions">
              <select
                value={log.status || 'pending'}
                onChange={(e) => handleStatusChange(log.id, e.target.value)}
                className={`status-select ${getStatusClass(log.status)}`}
                title="Change status"
              >
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="done">Done</option>
                <option value="error">Error</option>
              </select>
              <button
                onClick={() => onDelete(log.id)}
                className="btn-delete"
                title="Delete log"
              >
                ✕
              </button>
            </div>
          </div>
          <div className="log-message">{log.message}</div>
          <div className="log-status-badge">
            <span className={`badge ${getStatusClass(log.status)}`}>
              {log.status || 'pending'}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}

export default LogList;
