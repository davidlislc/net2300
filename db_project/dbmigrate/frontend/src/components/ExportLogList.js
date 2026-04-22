import React from 'react';

function ExportLogList({ logs, onDelete }) {
  if (!logs || logs.length === 0) {
    return <div className="no-logs">No export logs found</div>;
  }

  const formatFileSize = (bytes) => {
    if (!bytes || bytes === 'NULL') return 'N/A';
    const kb = bytes / 1024;
    const mb = kb / 1024;
    if (mb >= 1) {
      return `${mb.toFixed(2)} MB`;
    }
    return `${kb.toFixed(2)} KB`;
  };

  const getStatusClass = (status) => {
    switch (status) {
      case 'pending':
        return 'status-pending';
      case 'success':
        return 'status-done';
      case 'error':
        return 'status-error';
      default:
        return '';
    }
  };

  return (
    <div className="log-list">
      {logs.map((log) => (
        <div key={log.id} className={`log-item ${getStatusClass(log.status)}`}>
          <div className="log-header">
            <span className="log-id">ID: {log.id}</span>
            <span className={`status-badge ${getStatusClass(log.status)}`}>
              {log.status}
            </span>
            <button
              onClick={() => onDelete(log.id)}
              className="btn btn-delete"
              title="Delete"
            >
              🗑️
            </button>
          </div>
          
          <div className="log-content">
            <div className="log-field">
              <strong>Database:</strong> {log.database_name}
            </div>
            <div className="log-field">
              <strong>Filename:</strong> {log.filename}
            </div>
            <div className="log-field">
              <strong>File Size:</strong> {formatFileSize(log.file_size)}
            </div>
            {log.output && (
              <div className="log-field">
                <strong>Output:</strong>
                <pre className="log-output">{log.output}</pre>
              </div>
            )}
            <div className="log-field">
              <strong>Exported At:</strong> {new Date(log.exported_at).toLocaleString()}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

export default ExportLogList;
