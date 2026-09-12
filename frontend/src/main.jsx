import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';

async function api(path, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  try {
    const response = await fetch(`/api${path}`, {
      ...options,
      headers: { 'Content-Type': 'application/json', ...options.headers },
      cache: 'no-store',
      signal: controller.signal,
    });
    const body = await response.json().catch(() => null);
    if (!response.ok) {
      throw new Error(typeof body?.detail === 'string'
        ? body.detail : `Request failed (${response.status}). Please try again.`);
    }
    return body;
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new Error('The request timed out. Retrieve records before retrying an insert; it may already have saved.');
    }
    if (error instanceof TypeError) throw new Error('Cannot reach the server. Check your connection and try again.');
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

function App() {
  const [text, setText] = useState('');
  const [records, setRecords] = useState([]);
  const [retrieved, setRetrieved] = useState(false);
  const [busy, setBusy] = useState('');
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const formatDate = value => new Date(value).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'medium' });

  async function insert(event) {
    event.preventDefault();
    if (!text.trim() || busy) return;
    setBusy('insert'); setError(''); setNotice('');
    try {
      const saved = await api('/entries', { method: 'POST', body: JSON.stringify({ text: text.trim() }) });
      setText('');
      setNotice(`Record #${saved.id} saved at ${formatDate(saved.created_at)}. Select Retrieve to read it from the database.`);
    } catch (error) { setError(error.message); }
    finally { setBusy(''); }
  }

  async function retrieve() {
    setBusy('retrieve'); setError(''); setNotice('');
    try {
      const result = await api('/entries');
      setRecords(result); setRetrieved(true);
      setNotice(result.length ? `${result.length} record${result.length === 1 ? '' : 's'} retrieved.` : 'No records yet. Insert your first note.');
    } catch (error) { setError(error.message); }
    finally { setBusy(''); }
  }

  const output = records.map(record => `#${record.id} · ${formatDate(record.created_at)}\n${record.text}`).join('\n\n────────────────────────\n\n');
  return (
    <main className="notebook">
      <header className="masthead">
        <span className="mark" aria-hidden="true">N<span>·</span></span>
        <span className="edition">DEVOPS LAB / 01</span>
      </header>
      <section className="intro">
        <p className="eyebrow">A NOTE, WITH A MOMENT ATTACHED</p>
        <h1>Timestamp Notebook<span>.</span></h1>
        <p>Write something. Save it with the server’s date and time. Come back and read it.</p>
      </section>
      <div className="workspace">
        <form className="panel" onSubmit={insert}>
          <div className="panel-heading"><span className="step">01</span><h2>Write a note</h2></div>
          <label htmlFor="note">Your text</label>
          <textarea id="note" value={text} onChange={event => setText(event.target.value)} maxLength={2000}
            placeholder="Something worth remembering…" disabled={Boolean(busy)} required aria-describedby="input-help" />
          <p className="field-help" id="input-help"><span>Date and time are added when you save.</span><span>{text.length}/2000</span></p>
          <button className="primary" type="submit" disabled={Boolean(busy) || !text.trim()}>{busy === 'insert' ? 'Saving…' : 'Insert'}</button>
        </form>
        <section className="panel output-panel" aria-labelledby="records-title">
          <div className="panel-heading"><span className="step">02</span><h2 id="records-title">Read your records</h2></div>
          <label htmlFor="records">Saved text and timestamps</label>
          <textarea id="records" readOnly value={output} aria-describedby="output-help"
            placeholder={retrieved ? 'No saved records yet.' : 'Select Retrieve to load your saved records.'} />
          <p className="field-help" id="output-help"><span>Newest first · up to 100 records</span><span>{retrieved ? `${records.length} loaded` : 'Ready to retrieve'}</span></p>
          <button className="secondary" type="button" onClick={retrieve} disabled={Boolean(busy)}>{busy === 'retrieve' ? 'Retrieving…' : 'Retrieve'}</button>
        </section>
      </div>
      <div className="feedback" aria-live="polite" aria-atomic="true">
        {error ? <p className="error" role="alert">{error}</p> : <p>{notice || 'Your notes stay saved when you refresh this page.'}</p>}
      </div>
      <footer><span>Timestamp Notebook</span><span>Times displayed in {timezone}. Stored in UTC.</span></footer>
    </main>
  );
}

createRoot(document.getElementById('root')).render(<React.StrictMode><App /></React.StrictMode>);
