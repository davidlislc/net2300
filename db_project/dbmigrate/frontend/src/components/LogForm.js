import React, { useState } from 'react';

function LogForm({ onSubmit }) {
  const [formData, setFormData] = useState({
    message: '',
    status: 'pending'
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
    if (!formData.message.trim()) {
      setError('Message is required');
      setLoading(false);
      return;
    }

    const logData = {
      message: formData.message,
      status: formData.status
    };

    const result = await onSubmit(logData);
    setLoading(false);

    if (result.success) {
      setSuccess('Command entry created successfully!');
      // Reset form
      setFormData({
        message: '',
        status: 'pending'
      });
      setTimeout(() => setSuccess(''), 3000);
    } else {
      setError(result.error || 'Failed to create log entry');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="log-form">
      {error && <div className="error-message">{error}</div>}
      {success && <div className="success-message">{success}</div>}

      <div className="form-group">
        <label htmlFor="message">Command *</label>
        <textarea
          id="message"
          name="message"
          value={formData.message}
          onChange={handleChange}
          className="form-control"
          rows="3"
          placeholder="Enter command..."
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="status">Status *</label>
        <select
          id="status"
          name="status"
          value={formData.status}
          onChange={handleChange}
          className="form-control"
          required
        >
          <option value="pending">Pending</option>
          <option value="processing">Processing</option>
          <option value="done">Done</option>
          <option value="error">Error</option>
        </select>
      </div>

      <button type="submit" className="btn btn-primary" disabled={loading}>
        {loading ? 'Creating...' : '✓ Create command Entry'}
      </button>
    </form>
  );
}

export default LogForm;
