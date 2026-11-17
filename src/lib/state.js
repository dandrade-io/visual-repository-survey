// Keeps the participant's progress in this browser so a page refresh
// doesn't lose their answers. Everything is wrapped in try/catch because
// storage can be unavailable (private mode, blocked cookies...).

const KEY = 'search-survey-state-v1';

export function loadState() {
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function saveState(state) {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch {
    /* ignore */
  }
}

export function clearState() {
  try {
    localStorage.removeItem(KEY);
  } catch {
    /* ignore */
  }
}

/** Picks n distinct random items (Fisher–Yates on a copy). */
export function sample(list, n) {
  const a = [...list];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a.slice(0, Math.min(n, a.length));
}

export function emptyAnswer(image) {
  return {
    image,
    jina: { queries: null, found: true, satisfaction: null },
    siglip: { queries: null, found: true, satisfaction: null },
  };
}

export function isModelAnswerComplete(m) {
  return Number.isInteger(m.queries) && m.queries >= 1 && m.queries <= 100 && m.satisfaction >= 1 && m.satisfaction <= 5;
}
