// awen-shell.js — the shared machinery for awen app entry pages: loader overlay
// wiring, wasm prefetch with real download progress, and keyboard-focus routing
// into Qt's shadow DOM. The page supplies #loader/#status/#progress/#screen,
// includes this script at the end of body BEFORE the app's <target>.js and
// qtloader.js (so the elements exist and the error hooks cover those scripts),
// and calls awenShell.init({ name, entry, wasm }) from body onload.
window.awenShell = (() => {
  let appName = 'app';
  const loaderElement = document.getElementById('loader');
  const statusElement = document.getElementById('status');
  const progressElement = document.getElementById('progress');
  const screenElement = document.getElementById('screen');

  // Once the app is up, page-level errors must not swap it out for the loader.
  let appLoaded = false;

  function setStatus(text) {
    statusElement.innerHTML = text;
  }

  function showApp() {
    appLoaded = true;
    loaderElement.style.display = 'none';
    screenElement.style.display = 'block';
    focusAppWhenReady();
  }

  // Route the keyboard to the app: Qt wasm only delivers key events while its
  // invisible focus helper (inside the shadow DOM, an internal detail of Qt 6)
  // holds DOM focus, so push focus there whenever it drifts to the page. Guards
  // mirror Qt's own focus(): leave focus already inside Qt's DOM alone, and skip
  // an aria-hidden helper (accessibility active — Qt owns focus routing then).
  // Returns whether the app holds focus afterwards, checked via focus() rather
  // than element presence (focusing under a display:none ancestor is a no-op).
  function focusApp() {
    const shadowRoot = screenElement.querySelector('#qt-shadow-container')?.shadowRoot;
    if (!shadowRoot)
      return false;
    if (shadowRoot.activeElement)
      return true; // the app already holds focus internally
    // Prefer the active window's helper; with one window both selectors agree.
    const helper = shadowRoot.querySelector('.qt-decorated-window:not(.inactive) .qt-window-focus-helper')
      ?? shadowRoot.querySelector('.qt-window-focus-helper');
    if (!helper || helper.getAttribute('aria-hidden') === 'true')
      return false;
    helper.focus({ preventScroll: true });
    return shadowRoot.activeElement === helper;
  }

  // The window DOM (and its focus helper) only exists after main() runs, so
  // retry across frames until focus lands, bounded so a failed load or a Qt
  // upgrade renaming the internals does not poll forever.
  function focusAppWhenReady(deadline = performance.now() + 15000) {
    if (focusApp())
      return;
    if (performance.now() < deadline)
      requestAnimationFrame(() => focusAppWhenReady(deadline));
    else
      console.warn(`${appName}: could not hand keyboard focus to the app; click its view to focus it`);
  }

  // Fullscreen transitions move focus around; keep the keyboard on the app.
  document.addEventListener('fullscreenchange', () => focusApp());

  // Nothing on the page needs the keyboard except the app, so refocus it
  // after any click — including clicks on the app itself, which Qt 6.11 does
  // not refocus. Capture phase is required (Qt stops pointer-event propagation)
  // and the deferral runs after Qt's own focus routing.
  document.addEventListener('pointerup', () => setTimeout(() => focusApp(), 0), true);

  function showLoader(status) {
    screenElement.style.display = 'none';
    loaderElement.style.display = 'flex';
    progressElement.hidden = true;
    setStatus(status);
  }

  // Fetch the wasm ourselves so the progress bar shows the real download; the
  // compiled module goes to qtLoad via qt.module, so emscripten does not
  // re-download it. Indeterminate when Content-Length is absent.
  async function fetchWasmWithProgress(url) {
    const response = await fetch(url);
    if (!response.ok || !response.body) {
      throw new Error(`Failed to fetch ${url}: ${response.status}`);
    }

    const total = Number(response.headers.get('Content-Length')) || 0;
    if (total === 0) {
      progressElement.removeAttribute('value'); // indeterminate
    }

    const reader = response.body.getReader();
    const chunks = [];
    let received = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }
      chunks.push(value);
      received += value.length;
      if (total > 0) {
        const percent = Math.min(100, Math.round((received / total) * 100));
        progressElement.value = percent;
        setStatus(`Downloading&hellip; ${percent}%`);
      }
    }

    const bytes = new Uint8Array(received);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.length;
    }
    return WebAssembly.compile(bytes.buffer);
  }

  window.onerror = window.onunhandledrejection = () => {
    // Before the app is up a page error means the load failed; after, the app
    // keeps running and the error stays in the console.
    if (!appLoaded) {
      showLoader('Exception thrown, see JavaScript console');
    }
  };

  async function init({ name, entry, wasm }) {
    appName = name;

    // Entry function, the container div Qt renders into, and the overlay hooks.
    const qt = {
      onLoaded: () => showApp(),
      onExit: (exitData) => {
        let status = 'Application exit';
        status += exitData.code !== undefined ? ` with code ${exitData.code}` : '';
        status += exitData.text !== undefined ? ` (${exitData.text})` : '';
        showLoader(status);
      },
      entryFunction: entry,
      containerElements: [screenElement],
    };

    try {
      try {
        qt.module = await fetchWasmWithProgress(wasm);
        progressElement.hidden = true;
        setStatus('Starting&hellip;');
      } catch (fetchError) {
        // Progress is cosmetic: let emscripten fetch the wasm itself instead.
        console.warn('wasm prefetch failed, falling back to plain load:', fetchError);
        delete qt.module;
        progressElement.hidden = true;
        setStatus('Loading&hellip;');
      }

      await qtLoad({ qt });
    } catch (e) {
      console.error(e);
      console.error(e.stack);
      showLoader('Failed to start, see JavaScript console');
    }
  }

  return { init, focusApp };
})();
