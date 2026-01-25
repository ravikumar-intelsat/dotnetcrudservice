import React, { useState } from 'react';
import './App.css';
import RAGInterface from './components/RAGInterface';
import LLMChat from './components/LLMChat';

function App() {
  const [activeTab, setActiveTab] = useState('rag');

  return (
    <div className="App">
      <header className="App-header">
        <h1>🤖 Resume RAG Chat Interface</h1>
        <p>Ask questions about the candidate's resume or chat directly with the LLM</p>
      </header>
      <main className="App-main">
        <div className="tab-bar">
          <button
            className={`tab-button ${activeTab === 'rag' ? 'active' : ''}`}
            onClick={() => setActiveTab('rag')}
            type="button"
          >
            RAG
          </button>
          <button
            className={`tab-button ${activeTab === 'chat' ? 'active' : ''}`}
            onClick={() => setActiveTab('chat')}
            type="button"
          >
            LLM Chat
          </button>
        </div>
        {activeTab === 'rag' ? <RAGInterface /> : <LLMChat />}
      </main>
    </div>
  );
}

export default App;
