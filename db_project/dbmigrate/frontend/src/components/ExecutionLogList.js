import React from 'react';

function ExecutionLogList({ logs, onDelete }) {
  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  const getExitCodeClass = (exitCode) => {
    if (exitCode === null || exitCode === undefined) return '';
    return exitCode === 0 ? 'exit-success' : 'exit-error';
  };

  if (logs.length === 0) {
    return <div className="no-logs">No execution logs found</div>;
  }

  return (
    <div className="log-list">
      {logs.map((log) => (
        <div key={log.id} className="log-item execution-log-item">
          <div className="log-header">
            <div>
              <span className="log-timestamp">{formatTimestamp(log.executed_at)}</span>
              {log.log_id && (
                <span className="log-reference"> (Command ID: {log.log_id})</span>
              )}
            </div>
            <button
              onClick={() => onDelete(log.id)}
              className="btn-delete"
              title="Delete execution log"
            >
              ✕
            </button>
          </div>
          
          <div className="execution-command">
            <strong>Command:</strong> <code>{log.command}</code>
          </div>
          
          {log.output && (
            <div className="execution-output">
              <strong>Output:</strong>
              <pre>{log.output}</pre>
            </div>
          )}
          
          {log.exit_code !== null && log.exit_code !== undefined && (
            <div className={`execution-exit-code ${getExitCodeClass(log.exit_code)}`}>
              <strong>Exit Code:</strong> {log.exit_code}
              {log.exit_code === 0 ? ' ✓' : ' ✗'}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

export default ExecutionLogList;
