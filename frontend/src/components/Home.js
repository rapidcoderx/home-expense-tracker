import React, { useState } from 'react';
import axios from 'axios';

function Home() {
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const checkBackendStatus = async () => {
    try {
      setError('');
      const response = await axios.get('http://localhost:4001/api/health');
      setMessage(response.data.message);
    } catch (err) {
      setError('Error connecting to backend: ' + (err.message || 'Unknown error'));
      setMessage('');
    }
  };

  const styles = {
    container: {
      padding: '20px',
      textAlign: 'center'
    },
    button: {
      padding: '10px 15px',
      backgroundColor: '#4CAF50',
      color: 'white',
      border: 'none',
      borderRadius: '4px',
      cursor: 'pointer',
      fontSize: '16px',
      margin: '20px 0'
    },
    message: {
      margin: '20px 0',
      padding: '15px',
      backgroundColor: '#f1f8e9',
      borderRadius: '4px',
      display: message ? 'block' : 'none'
    },
    error: {
      margin: '20px 0',
      padding: '15px',
      backgroundColor: '#ffebee',
      color: '#c62828',
      borderRadius: '4px',
      display: error ? 'block' : 'none'
    }
  };

  return (
    <div style={styles.container}>
      <h1>Home Expense Tracker</h1>
      <p>Welcome to the Home Expense Tracker application</p>
      
      <button 
        style={styles.button}
        onClick={checkBackendStatus}
      >
        Check Backend Status
      </button>
      
      {message && <div style={styles.message}>{message}</div>}
      {error && <div style={styles.error}>{error}</div>}
    </div>
  );
}

export default Home; 