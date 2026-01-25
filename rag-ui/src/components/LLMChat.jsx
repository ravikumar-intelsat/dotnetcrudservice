import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import '../styles/RAGInterface.css';

const LLMChat = () => {
  const [message, setMessage] = useState('');
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

  const handleSubmit = async (e) => {
    e.preventDefault();

    const queryText = message.trim();
    if (!queryText) return;

    setError(null);
    setLoading(true);

    setMessages(prev => [...prev, {
      type: 'user',
      content: queryText
    }]);

    try {
      const apiBaseUrl = import.meta.env.VITE_API_URL || 'https://didactic-barnacle-q77wvgqprjx5hxx56-5001.app.github.dev';
      const response = await axios.post(`${apiBaseUrl}/api/chat`, {
        message: queryText
      }, {
        timeout: 300000
      });

      setMessages(prev => [...prev, {
        type: 'assistant',
        content: response.data.response,
        generationTime: response.data.generationTime
      }]);
    } catch (err) {
      console.error('Error:', err);
      setError(err.response?.data?.error || err.message || 'Failed to get response. Make sure the backend is running.');
      setMessages(prev => [...prev, {
        type: 'error',
        content: 'Sorry, I encountered an error processing your message. Please try again.'
      }]);
    } finally {
      setLoading(false);
      setMessage('');
    }
  };

  return (
    <div className="rag-container">
      <div className="rag-chat">
        <div className="messages-container">
          {messages.length === 0 ? (
            <div className="welcome-section">
              <h2>Welcome! 👋</h2>
              <p>Chat directly with the LLM. This mode does not use retrieval.</p>
            </div>
          ) : (
            messages.map((msg, idx) => (
              <div key={idx} className={`message message-${msg.type}`}>
                <div className="message-avatar">
                  {msg.type === 'user' ? '👤' : msg.type === 'error' ? '❌' : '🤖'}
                </div>
                <div className="message-content">
                  <p className="message-text">{msg.content}</p>
                  {msg.generationTime && (
                    <small className="response-time">⏱️ Response time: {msg.generationTime.toFixed(2)}s</small>
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

        <form className="input-form" onSubmit={handleSubmit}>
          <div className="input-wrapper">
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Type a message..."
              disabled={loading}
              className="query-input"
            />
            <button
              type="submit"
              disabled={loading || !message.trim()}
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

export default LLMChat;
