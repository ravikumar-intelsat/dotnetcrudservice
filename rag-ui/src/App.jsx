import React from 'react';
import './App.css';
import RAGInterface from './components/RAGInterface';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>🤖 Resume RAG Chat Interface</h1>
        <p>Ask questions about the candidate's resume</p>
      </header>
      <main className="App-main">
        <RAGInterface />
      </main>
    </div>
  );
}

export default App;
