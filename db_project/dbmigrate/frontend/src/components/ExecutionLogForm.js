import React, { useState } from 'react';

function ExecutionLogForm({ onSubmit }) {
  const [formData, setFormData] = useState({
    log_id: '',
    command: '',
    output: '',
    exit_code: ''
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    // Validate
    if (!formData.command.trim()) {
      setError('Command is required');
      setLoading(false);
      return;
    }

    const logData = {
      log_id: formData.log_id ? parseInt(formData.log_id) : undefined,
      command: formData.command,
      output: formData.output || undefined,
      exit_code: formData.exit_code !== '' ? parseInt(formData.exit_code) : undefined
    };

    const result = await onSubmit(logData);
    setLoading(false);

    if (result.success) {
      setSuccess('Execution log created successfully!');
      // Reset form
      setFormData({
        log_id: '',
        command: '',
        output: '',
        exit_code: ''
      });
      setTimeout(() => setSuccess(''), 3000);
    } else {
      setError(result.error || 'Failed to create execution log');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="log-form">
      {error && <div className="error-message">{error}</div>}
      {success && <div className="success-message">{success}</div>}

      <div className="form-group">
        <label htmlFor="log_id">Command ID (optional)</label>
        <input
          type="number"
          id="log_id"
          name="log_id"
          value={formData.log_id}
          onChange={handleChange}
          className="form-control"
          placeholder="Reference to command log ID"
        />
      </div>

      <div className="form-group">
        <label htmlFor="command">Command *</label>
        <textarea
          id="command"
          name="command"
          value={formData.command}
          onChange={handleChange}
          className="form-control"
          rows="2"
          placeholder="Enter command that was executed..."
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="output">Output</label>
        <textarea
          id="output"
          name="output"
          value={formData.output}
          onChange={handleChange}
          className="form-control"
          rows="4"
          placeholder="Command output..."
        />
      </div>

      <div className="form-group">
        <label htmlFor="exit_code">Exit Code</label>
        <input
          type="number"
          id="exit_code"
          name="exit_code"
          value={formData.exit_code}
          onChange={handleChange}
          className="form-control"
          placeholder="e.g., 0 for success, 1 for error"
        />
      </div>

      <button type="submit" className="btn btn-primary" disabled={loading}>
        {loading ? 'Creating...' : '✓ Create Execution Log'}
      </button>
    </form>
  );
}

export default ExecutionLogForm;
