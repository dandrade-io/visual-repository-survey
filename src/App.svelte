<script>
  import { onMount, tick } from 'svelte';
  import { IMAGES_PER_PARTICIPANT, ALLOWED_EMAIL_DOMAINS, MODELS, SEARCH_ENGINE_URL } from './config.js';
  import { loadState, saveState, clearState, sample, emptyAnswer, isModelAnswerComplete } from './lib/state.js';
  import { submitSurvey, supabaseConfigured } from './lib/supabase.js';
  import ModelQuestion from './lib/ModelQuestion.svelte';
  import SearchSteps from './lib/SearchSteps.svelte';
  import Contact from './lib/Contact.svelte';

  const BASE = import.meta.env.BASE_URL;
  const searchHost = SEARCH_ENGINE_URL.replace(/^https?:\/\//, '').replace(/\/$/, '');
  const pad = (n) => String(n).padStart(2, '0');

  // 'loading' | 'info' | 'survey' | 'submitting' | 'done' | 'error'
  let stage = $state('loading');
  let participant = $state({ id: '', name: '', email: '', career: '' });
  let answers = $state([]);
  let index = $state(0);
  let consent = $state(false);
  let manifest = [];
  let loadError = $state('');
  let submitError = $state('');
  let showErrors = $state(false);
  let imageLoaded = $state(false);

  onMount(async () => {
    try {
      const res = await fetch(`${BASE}images.json`);
      if (!res.ok) throw new Error(res.statusText);
      manifest = await res.json();
    } catch {
      loadError = 'No se pudo cargar la lista de imágenes. Recarga la página y, si el problema continúa, escríbeme.';
      stage = 'error';
      return;
    }
    const saved = loadState();
    if (saved && ['survey', 'submitting'].includes(saved.stage) && saved.answers?.length) {
      participant = saved.participant;
      // Progress saved before queries defaulted to 1 may still hold null.
      answers = saved.answers.map((a) => {
        for (const m of MODELS) if (!(a[m.key].queries >= 1)) a[m.key].queries = 1;
        return a;
      });
      index = Math.min(saved.index ?? 0, saved.answers.length - 1);
      stage = 'survey';
    } else if (saved?.stage === 'done') {
      participant = saved.participant ?? participant;
      stage = 'done';
    } else {
      if (saved?.participant) participant = saved.participant;
      stage = 'info';
    }
  });

  // Persist progress on every change.
  $effect(() => {
    if (stage === 'loading' || stage === 'error') return;
    saveState({ stage, participant: $state.snapshot(participant), answers: $state.snapshot(answers), index });
  });

  // ---------- Personal info ----------
  const emailDomainOk = (email) => {
    if (!ALLOWED_EMAIL_DOMAINS.length) return true;
    const domain = email.trim().toLowerCase().split('@')[1] ?? '';
    return ALLOWED_EMAIL_DOMAINS.some((d) => domain === d || domain.endsWith('.' + d));
  };
  const emailFormatOk = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());

  let infoErrors = $derived({
    name: participant.name.trim().length < 3 ? 'Escribe tu nombre completo.' : '',
    email: !emailFormatOk(participant.email)
      ? 'Escribe un correo válido.'
      : !emailDomainOk(participant.email)
        ? `Usa tu correo institucional (termina en ${ALLOWED_EMAIL_DOMAINS.join(' o ')}).`
        : '',
    career: participant.career.trim().length < 2 ? 'Escribe tu carrera.' : '',
    consent: consent ? '' : 'Necesitamos tu autorización para continuar.',
  });
  let infoValid = $derived(Object.values(infoErrors).every((e) => !e));

  async function focusFirstError() {
    await tick();
    const el = document.querySelector('[aria-invalid="true"], .invalid input, .invalid');
    el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    if (el instanceof HTMLInputElement) el.focus({ preventScroll: true });
  }

  function startSurvey(e) {
    e.preventDefault();
    showErrors = true;
    if (!infoValid) return focusFirstError();
    participant.id = crypto.randomUUID();
    participant.name = participant.name.trim().replace(/\s+/g, ' ');
    participant.email = participant.email.trim().toLowerCase();
    participant.career = participant.career.trim();
    answers = sample(manifest, IMAGES_PER_PARTICIPANT).map(emptyAnswer);
    index = 0;
    showErrors = false;
    stage = 'survey';
    scrollTop();
  }

  // ---------- Survey ----------
  let current = $derived(answers[index]);
  let currentValid = $derived(current ? MODELS.every((m) => isModelAnswerComplete(current[m.key])) : false);
  let missingModels = $derived(current ? MODELS.filter((m) => !isModelAnswerComplete(current[m.key])).map((m) => m.label) : []);
  let isLast = $derived(index === answers.length - 1);
  let progress = $derived(answers.length ? (index / answers.length) * 100 : 0);
  let firstName = $derived(participant.name.split(' ')[0] ?? '');

  // Reset the fade-in each time the image changes, and preload the next one.
  $effect(() => {
    void current?.image.id;
    imageLoaded = false;
    const next = answers[index + 1];
    if (next) new Image().src = `${BASE}images/${next.image.file}`;
  });

  function scrollTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function next() {
    showErrors = true;
    if (!currentValid) return focusFirstError();
    showErrors = false;
    if (isLast) {
      submit();
    } else {
      index += 1;
      scrollTop();
    }
  }

  function back() {
    if (index > 0) {
      index -= 1;
      showErrors = false;
      scrollTop();
    }
  }

  async function submit() {
    stage = 'submitting';
    submitError = '';
    try {
      await submitSurvey($state.snapshot(participant), $state.snapshot(answers));
      stage = 'done';
      scrollTop();
    } catch (err) {
      console.error(err);
      submitError = err?.message ?? String(err);
      stage = 'survey';
    }
  }

  function restart() {
    clearState();
    participant = { id: '', name: '', email: '', career: '' };
    answers = [];
    index = 0;
    consent = false;
    stage = 'info';
    scrollTop();
  }
</script>

<div class="shell">
  <header class="masthead">
    <div class="inner">
      <p class="brand">
        <span class="caps">Proyecto Integrador</span>
        <span class="sep" aria-hidden="true"></span>
        <span class="caps muted">USFQ</span>
      </p>
      <nav>
        {#if stage === 'survey' || stage === 'submitting'}
          <a class="caps navlink" href={SEARCH_ENGINE_URL} target="_blank" rel="noopener"><span class="wide-only">Abrir </span> buscador ↗</a>
        {/if}
        <a class="caps navlink wide-only" href="#ayuda">Ayuda</a>
      </nav>
    </div>
    {#if stage === 'survey' || stage === 'submitting'}
      <div class="progress" role="progressbar" aria-valuemin="0" aria-valuemax={answers.length} aria-valuenow={index} aria-label="Imágenes completadas">
        <div style="width: {progress}%"></div>
      </div>
    {/if}
  </header>

  {#if !supabaseConfigured}
    <p class="testmode">Modo de prueba: las respuestas no se guardarán.</p>
  {/if}

  <main>
    {#if stage === 'loading'}
      <p class="loading">Cargando…</p>
    {:else if stage === 'error'}
      <section class="narrow">
        <h1>Algo salió mal</h1>
        <p class="lede">{loadError}</p>
        <div class="contact-block"><Contact /></div>
      </section>
    {:else if stage === 'info'}
      <div class="welcome">
        <div class="intro">
          <p class="caps kicker">Encuesta · {IMAGES_PER_PARTICIPANT} imágenes · 15 a 20 minutos</p>
          <h1>Evaluación del<br /><em>buscador visual</em></h1>
          <p class="lede">
            Queremos saber qué tan fácil es encontrar una imagen describiéndola con palabras. Vas a comparar
            dos modelos de búsqueda, <strong>{MODELS[0].label}</strong> y <strong>{MODELS[1].label}</strong>,
            usando imágenes elegidas al azar.
          </p>

          <a class="site" href={SEARCH_ENGINE_URL} target="_blank" rel="noopener">
            <span class="caps">El buscador</span>
            <span class="url">{searchHost}</span>
            <span class="arrow" aria-hidden="true">↗</span>
          </a>

          <h2 class="section-title">Cómo buscar cada imagen</h2>
          <SearchSteps />
        </div>

        <aside class="side">
          <form class="panel" onsubmit={startSurvey} novalidate>
            <h2>Tus datos</h2>
            <p class="panel-note">Se usan solo para identificar tus respuestas.</p>

            <div class="field">
              <label for="name">Nombre completo</label>
              <input id="name" type="text" autocomplete="name" bind:value={participant.name} aria-invalid={showErrors && !!infoErrors.name} />
              {#if showErrors && infoErrors.name}<small class="err">{infoErrors.name}</small>{/if}
            </div>
            <div class="field">
              <label for="email">Correo institucional</label>
              <input id="email" type="email" autocomplete="email" placeholder="usuario@estud.usfq.edu.ec" bind:value={participant.email} aria-invalid={showErrors && !!infoErrors.email} />
              {#if showErrors && infoErrors.email}<small class="err">{infoErrors.email}</small>{/if}
            </div>
            <div class="field">
              <label for="career">Carrera</label>
              <input id="career" type="text" placeholder="Ej. Arquitectura" bind:value={participant.career} aria-invalid={showErrors && !!infoErrors.career} />
              {#if showErrors && infoErrors.career}<small class="err">{infoErrors.career}</small>{/if}
            </div>

            <label class="consent">
              <input type="checkbox" bind:checked={consent} aria-invalid={showErrors && !!infoErrors.consent} />
              <span>Autorizo el uso de mis respuestas con fines académicos para este proyecto.</span>
            </label>
            {#if showErrors && infoErrors.consent}<small class="err">{infoErrors.consent}</small>{/if}

            <button type="submit" class="btn primary wide">Comenzar encuesta</button>
          </form>

          <div class="contact-block"><Contact /></div>
        </aside>
      </div>
    {:else if (stage === 'survey' || stage === 'submitting') && current}
      <div class="survey">
        <div class="viewer">
          <div class="counter">
            <span class="num">{pad(index + 1)}</span>
            <span class="of">de {pad(answers.length)}</span>
          </div>

          <a class="frame" href="{BASE}images/{current.image.file}" target="_blank" rel="noopener" title="Ver en tamaño completo">
            {#key current.image.id}
              <img
                src="{BASE}images/{current.image.file}"
                alt="Imagen {index + 1} que debes encontrar"
                class:loaded={imageLoaded}
                onload={() => (imageLoaded = true)}
              />
            {/key}
          </a>
          <p class="hint">Toca la imagen para verla en tamaño completo.</p>

          <details class="howto">
            <summary>¿Cómo buscar?</summary>
            <ol>
              <li>
                Abre <a href={SEARCH_ENGINE_URL} target="_blank" rel="noopener">{searchHost}</a>.
              </li>
              <li>Escribe una descripción, elige <strong>{MODELS[0].label}</strong> y presiona Enter o <em>Buscar</em>.</li>
              <li>Reformula hasta encontrarla. Cada búsqueda es una consulta.</li>
              <li>Cambia el modelo a <strong>{MODELS[1].label}</strong> y repite.</li>
            </ol>
          </details>
        </div>

        <div class="questions">
          <p class="caps kicker">Imagen {index + 1} de {answers.length}</p>
          <h1 class="q-title">Busca esta imagen con ambos modelos</h1>
          <p class="q-lede">
            Cuenta cada vez que presionas Enter o <em>Buscar</em> como una consulta.
          </p>

          {#each MODELS as m, i (m.key)}
            <ModelQuestion label={m.label} name="{m.key}-{index}" order={i + 1} bind:value={answers[index][m.key]} />
          {/each}
          {#if submitError}
            <div class="alert" role="alert">
              <strong>No pudimos enviar tus respuestas.</strong>
              Siguen guardadas en este navegador; intenta de nuevo en un momento. Si el problema continúa, escríbeme.
              <small>Detalle: {submitError}</small>
            </div>
          {/if}

          <nav class="actions">
            <button type="button" class="btn" onclick={back} disabled={index === 0 || stage === 'submitting'}>Anterior</button>
            <button type="button" class="btn primary" onclick={next} disabled={!currentValid || stage === 'submitting'} aria-describedby="next-hint">
              {#if stage === 'submitting'}Enviando…{:else if isLast}Enviar respuestas{:else}Siguiente imagen{/if}
            </button>
          </nav>
          {#if !currentValid}
            <p class="next-hint" id="next-hint">
              Elige tu nivel de satisfacción con {missingModels.join(' y ')} para continuar.
            </p>
          {/if}
        </div>
      </div>
    {:else if stage === 'done'}
      <section class="narrow done">
        <span class="seal" aria-hidden="true">✓</span>
        <h1>Gracias{firstName ? `, ${firstName}` : ''}.</h1>
        <p class="lede">
          Tus respuestas se registraron correctamente. Tu participación ayuda a evaluar qué modelo entiende
          mejor las descripciones de las personas.
        </p>
        <button type="button" class="linkish" onclick={restart}>Responder como otra persona</button>
      </section>
    {/if}
  </main>

  <footer id="ayuda">
    <div class="inner">
      <Contact compact />
    </div>
  </footer>
</div>

<style>
  .shell {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    border-top: 4px solid var(--red);
  }
  .inner {
    max-width: 1120px;
    margin: 0 auto;
    padding: 0 24px;
  }

  /* Masthead */
  .masthead {
    position: sticky;
    top: 0;
    z-index: 10;
    background: rgba(255, 255, 255, 0.94);
    backdrop-filter: blur(8px);
    border-bottom: 1px solid var(--line);
  }
  .masthead .inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    height: 56px;
  }
  .brand {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    color: var(--ink);
  }
  .sep {
    width: 1px;
    height: 14px;
    background: var(--line);
  }
  .muted {
    color: var(--muted);
  }
  nav {
    display: flex;
    gap: 1.4rem;
  }
  .navlink {
    color: var(--ink);
    text-decoration: none;
    white-space: nowrap;
  }
  .brand .caps {
    white-space: nowrap;
  }
  .navlink:hover {
    color: var(--red-ink);
  }
  .progress {
    height: 2px;
    background: var(--mist);
  }
  .progress div {
    height: 100%;
    background: var(--red);
    transition: width 0.4s ease;
  }
  .testmode {
    text-align: center;
    font-size: 0.8rem;
    padding: 0.4rem;
    background: var(--mist);
    color: var(--muted);
  }

  main {
    flex: 1;
    width: 100%;
    max-width: 1120px;
    margin: 0 auto;
    padding: 3.5rem 24px 4rem;
  }
  .loading {
    color: var(--muted);
    text-align: center;
    padding: 4rem 0;
  }

  .kicker {
    color: var(--red-ink);
    margin-bottom: 1rem;
  }
  h1 {
    font-size: clamp(2.6rem, 6vw, 4rem);
  }
  h1 em {
    font-style: italic;
    font-weight: 500;
    color: var(--red-ink);
  }
  .lede {
    font-size: 1.08rem;
    color: var(--muted);
    margin-top: 1.25rem;
    max-width: 34rem;
  }
  .lede strong {
    color: var(--ink);
    font-weight: 500;
  }

  /* Welcome */
  .welcome {
    display: grid;
    grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr);
    gap: 5rem;
    align-items: start;
  }
  .site {
    display: grid;
    grid-template-columns: 1fr auto;
    align-items: end;
    gap: 0.2rem 1rem;
    margin: 2.25rem 0 3.5rem;
    padding: 1.1rem 0;
    border-top: 1px solid var(--ink);
    border-bottom: 1px solid var(--line);
    text-decoration: none;
    color: var(--ink);
    max-width: 34rem;
  }
  .site .caps {
    grid-column: 1 / -1;
    color: var(--muted);
  }
  .site .url {
    font-family: var(--serif);
    font-size: clamp(1.35rem, 3vw, 1.75rem);
    font-weight: 600;
    overflow-wrap: anywhere;
  }
  .site .arrow {
    font-size: 1.4rem;
    color: var(--red-ink);
    transition: transform 0.2s;
  }
  .site:hover {
    color: var(--ink);
  }
  .site:hover .url {
    color: var(--red-ink);
  }
  .site:hover .arrow {
    transform: translate(2px, -2px);
  }
  .section-title {
    font-size: 1.9rem;
    margin-bottom: 1.6rem;
  }

  .side {
    position: sticky;
    top: 88px;
  }
  .panel {
    border: 1px solid var(--line);
    border-radius: 10px;
    padding: 2rem;
    background: var(--paper);
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03), 0 12px 32px -18px rgba(0, 0, 0, 0.12);
    display: grid;
    gap: 1.15rem;
  }
  .panel h2 {
    font-size: 1.9rem;
  }
  .panel-note {
    font-size: 0.88rem;
    color: var(--muted);
    margin-top: -0.75rem;
  }
  .field {
    display: grid;
    gap: 0.4rem;
  }
  .field label {
    font-size: 0.88rem;
    font-weight: 500;
    color: var(--ink);
  }
  .field :global(input[aria-invalid='true']) {
    border-color: var(--red-ink);
  }
  .consent {
    display: flex;
    gap: 0.65rem;
    align-items: flex-start;
    font-size: 0.88rem;
    color: var(--muted);
    cursor: pointer;
  }
  .consent input {
    margin-top: 0.2rem;
  }
  .err {
    color: var(--red-ink);
    font-size: 0.82rem;
  }
  .wide {
    width: 100%;
    margin-top: 0.4rem;
    padding: 1rem;
  }
  .contact-block {
    margin-top: 2rem;
  }

  /* Survey */
  .survey {
    display: grid;
    grid-template-columns: minmax(0, 1.1fr) minmax(0, 0.9fr);
    gap: 4.5rem;
    align-items: start;
  }
  .viewer {
    position: sticky;
    top: 90px;
  }
  .counter {
    display: flex;
    align-items: baseline;
    gap: 0.6rem;
    margin-bottom: 1rem;
  }
  .counter .num {
    font-family: var(--serif);
    font-size: 3.2rem;
    font-weight: 500;
    line-height: 1;
    color: var(--ink);
  }
  .counter .of {
    font-family: var(--serif);
    font-size: 1.3rem;
    font-style: italic;
    color: var(--muted);
  }
  .frame {
    display: block;
    background: var(--mist);
    border-radius: var(--radius);
    overflow: hidden;
    cursor: zoom-in;
    aspect-ratio: 4 / 3;
  }
  .frame img {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: contain;
    opacity: 0;
    transition: opacity 0.35s ease;
  }
  .frame img.loaded {
    opacity: 1;
  }
  .hint {
    font-size: 0.8rem;
    color: var(--muted);
    margin-top: 0.6rem;
  }
  .howto {
    margin-top: 1.4rem;
    border-top: 1px solid var(--line);
    padding-top: 0.9rem;
    font-size: 0.9rem;
  }
  .howto summary {
    cursor: pointer;
    font-weight: 500;
    color: var(--ink);
    width: fit-content;
  }
  .howto ol {
    margin: 0.75rem 0 0;
    padding-left: 1.2rem;
    color: var(--muted);
    display: grid;
    gap: 0.3rem;
  }
  .howto strong {
    color: var(--ink);
    font-weight: 500;
  }

  .q-title {
    font-size: clamp(1.9rem, 3.4vw, 2.4rem);
  }
  .q-lede {
    color: var(--muted);
    margin: 0.6rem 0 1.8rem;
    font-size: 0.95rem;
  }
  .actions {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    margin-top: 2rem;
    padding-top: 1.5rem;
    border-top: 1px solid var(--line);
  }
  .next-hint {
    margin-top: 0.75rem;
    font-size: 0.85rem;
    color: var(--muted);
    text-align: right;
  }
  .alert {
    margin-top: 1.25rem;
    padding: 1rem 1.1rem;
    border-left: 3px solid var(--red-ink);
    background: var(--red-tint);
    font-size: 0.9rem;
    color: var(--ink);
  }
  .alert small {
    display: block;
    margin-top: 0.4rem;
    color: var(--muted);
  }

  /* Done / error */
  .narrow {
    max-width: 36rem;
    margin: 2rem auto 0;
  }
  .done {
    text-align: center;
  }
  .done .lede {
    margin-left: auto;
    margin-right: auto;
  }
  .seal {
    display: inline-grid;
    place-items: center;
    width: 3.5rem;
    height: 3.5rem;
    margin-bottom: 1.5rem;
    border: 1px solid var(--red);
    border-radius: 50%;
    color: var(--red-ink);
    font-size: 1.4rem;
  }
  .linkish {
    margin-top: 2rem;
    background: none;
    border: none;
    padding: 0;
    color: var(--muted);
    font-size: 0.88rem;
    text-decoration: underline;
    text-underline-offset: 3px;
  }
  .linkish:hover {
    color: var(--ink);
  }

  footer {
    border-top: 1px solid var(--line);
    padding: 1.25rem 0;
    background: var(--paper);
  }

  /* Responsive */
  @media (max-width: 960px) {
    .welcome,
    .survey {
      grid-template-columns: 1fr;
      gap: 3rem;
    }
    .side,
    .viewer {
      position: static;
    }
  }
  @media (max-width: 600px) {
    .inner,
    main {
      padding-left: 16px;
      padding-right: 16px;
    }
    main {
      padding-top: 2.25rem;
    }
    .brand .sep,
    .brand .muted,
    .wide-only {
      display: none;
    }
    .panel {
      padding: 1.4rem;
    }
    .survey {
      gap: 2rem;
    }
    .counter .num {
      font-size: 2.4rem;
    }
    .actions .btn {
      flex: 1;
    }
  }
</style>
