import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import '../styles/RAGInterface.css';

const RAGInterface = () => {
  const [question, setQuestion] = useState('');
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const suggestedQuestions = [
    'What is the candidate\'s total years of experience?',
    'What are the main technical skills and technologies?',
    'What projects has the candidate worked on?',
    'What is the candidate\'s current role and company?',
    'What certifications does the candidate have?',
    'Tell me about their education'
  ];

  const handleQuerySubmit = async (e, selectedQuestion = null) => {
    e.preventDefault();
    
    const queryText = selectedQuestion || question;
    if (!queryText.trim()) return;

    setError(null);
    setLoading(true);

    // Add user message
    setMessages(prev => [...prev, { 
      type: 'user', 
      content: queryText 
    }]);

    try {
      // Call the Python backend API
      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001';
      const response = await axios.post(`${apiBaseUrl}/api/query`, {
        question: queryText
      }, {
        timeout: 300000 // 5 minute timeout
      });

      // Add assistant response
      setMessages(prev => [...prev, {
        type: 'assistant',
        content: response.data.response,
        chunks: response.data.chunks,
        retrievalTime: response.data.retrievalTime
      }]);

    } catch (err) {
      console.error('Error:', err);
      setError(err.response?.data?.error || err.message || 'Failed to get response. Make sure the backend is running.');
      setMessages(prev => [...prev, {
        type: 'error',
        content: 'Sorry, I encountered an error processing your question. Please try again.'
      }]);
    } finally {
      setLoading(false);
      setQuestion('');
    }
  };

  return (
    <div className="rag-container">
      <div className="rag-chat">
        <div className="messages-container">
          {messages.length === 0 ? (
            <div className="welcome-section">
              <h2>Welcome! 👋</h2>
              <p>Ask me anything about the resume using the suggestions below or type your own question.</p>
              <div className="suggested-questions">
                <h3>Suggested Questions:</h3>
                <div className="questions-grid">
                  {suggestedQuestions.map((q, idx) => (
                    <button
                      key={idx}
                      className="suggestion-btn"
                      onClick={(e) => handleQuerySubmit(e, q)}
                    >
                      {q}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            messages.map((msg, idx) => (
              <div key={idx} className={`message message-${msg.type}`}>
                <div className="message-avatar">
                  {msg.type === 'user' ? '👤' : msg.type === 'error' ? '❌' : '🤖'}
                </div>
                <div className="message-content">
                  <p className="message-text">{msg.content}</p>
                  {msg.chunks && msg.chunks.length > 0 && (
                    <details className="retrieved-chunks">
                      <summary>📄 Retrieved {msg.chunks.length} relevant chunks</summary>
                      <div className="chunks-list">
                        {msg.chunks.map((chunk, i) => (
                          <div key={i} className="chunk">
                            <small className="chunk-score">Relevance: {(chunk.score * 100).toFixed(1)}%</small>
                            <p>{chunk.text}</p>
                          </div>
                        ))}
                      </div>
                    </details>
                  )}
                  {msg.retrievalTime && (
                    <small className="response-time">⏱️ Response time: {msg.retrievalTime.toFixed(2)}s</small>
                  )}
                </div>
              </div>
            ))
          )}
          {loading && (
            <div className="message message-loading">
              <div className="message-avatar">🤖</div>
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </div>
            </div>
          )}
          {error && (
            <div className="error-banner">
              ⚠️ {error}
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <form className="input-form" onSubmit={handleQuerySubmit}>
          <div className="input-wrapper">
            <input
              type="text"
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder="Ask a question about the resume..."
              disabled={loading}
              className="query-input"
            />
            <button 
              type="submit" 
              disabled={loading || !question.trim()}
              className="send-btn"
            >
              {loading ? '⏳' : '📤'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default RAGInterface;
