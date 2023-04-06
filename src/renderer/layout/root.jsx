import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  HashRouter as Router,
  Routes,
  Route,
} from 'react-router-dom';
import styles from './root.module.css';
import { API } from 'api';

export function Root() {
  return (
    <Router>
      <Routes>
        <Route index element={<Page />} />
      </Routes>
    </Router>
  );
}

function Page() {
  const { t } = useTranslation();

  const [param, setParam] = useState('');

  const [log, setLog] = useState('');

  async function foo(param) {
    const api = new API();

    const result = await api.foo(param);

    setLog(result)
  }

  return (
    <>
      <main className={styles.main}>
        <p>running in {__BUILD_MODE__ === 'electron' ? "electron" : "browser"}</p>

        <div>
          <input
            type="text"
            value={param}
            onChange={(e) => setParam(e.target.value)}
          />

          <button
            type="button"
            title={t('page.button.foo', { param })}
            onClick={() => foo(param)}
          >
            foo
          </button>
        </div>

        <p>{log}</p>
      </main>
    </>
  );
}
