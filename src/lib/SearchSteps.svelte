<script>
  import { MODELS, SEARCH_ENGINE_URL } from '../config.js';

  const host = SEARCH_ENGINE_URL.replace(/^https?:\/\//, '').replace(/\/$/, '');
</script>

<ol class="steps">
  <li>
    <h3>Observa la imagen</h3>
    <p>Cada página de la encuesta te muestra una imagen. Mírala con atención: luego la vas a buscar a partir de lo que recuerdes.</p>
  </li>
  <li>
    <h3>Abre el buscador</h3>
    <p>
      Entra a <a href={SEARCH_ENGINE_URL} target="_blank" rel="noopener">{host}</a> en otra pestaña y
      mantén esta encuesta abierta.
    </p>
  </li>
  <li>
    <h3>Escribe, elige el modelo y busca</h3>
    <p>
      Describe con tus palabras lo que recuerdas de la imagen, selecciona <strong>{MODELS[0].label}</strong> en la barra y
      presiona <kbd>Enter</kbd> o el botón <em>Buscar</em>. Cada búsqueda cuenta como una consulta.
    </p>

    <figure class="demo" aria-hidden="true">
      <div class="bar">
        <span class="query">una calle empedrada con casas coloniales<span class="caret"></span></span>
        <span class="select">{MODELS[0].label} <svg viewBox="0 0 10 6"><path d="M1 1l4 4 4-4" /></svg></span>
        <span class="go">Buscar</span>
      </div>
      <div class="marks">
        <span><b>a</b> Escribe tu consulta</span>
        <span><b>b</b> Elige el modelo</span>
        <span><b>c</b> Enter o Buscar</span>
      </div>
    </figure>
  </li>
  <li>
    <h3>Repite con el otro modelo</h3>
    <p>
      Cuando la encuentres (o decidas que no aparece), cambia el modelo a
      <strong>{MODELS[1].label}</strong> en la misma barra y vuelve a buscar.
    </p>
  </li>
  <li>
    <h3>Registra tu experiencia</h3>
    <p>Anota cuántas consultas necesitaste con cada modelo y qué tan satisfecho/a quedaste.</p>
  </li>
</ol>

<style>
  .steps {
    list-style: none;
    margin: 0;
    padding: 0;
    counter-reset: step;
  }
  li {
    counter-increment: step;
    position: relative;
    padding: 0 0 1.6rem 3.1rem;
  }
  li::before {
    content: counter(step);
    position: absolute;
    left: 0;
    top: -0.3rem;
    font-family: var(--serif);
    font-size: 2rem;
    font-weight: 500;
    line-height: 1;
    color: var(--red);
    width: 2rem;
    text-align: center;
  }
  li:not(:last-child)::after {
    content: '';
    position: absolute;
    left: 1rem;
    top: 2.2rem;
    bottom: 0.4rem;
    border-left: 1px solid var(--line);
  }
  h3 {
    font-family: var(--sans);
    font-size: 1rem;
    font-weight: 500;
    letter-spacing: 0;
    margin-bottom: 0.25rem;
  }
  p {
    color: var(--muted);
    font-size: 0.95rem;
  }
  p strong {
    color: var(--ink);
    font-weight: 500;
  }
  kbd {
    font-family: var(--sans);
    font-size: 0.8rem;
    padding: 0.05rem 0.4rem;
    border: 1px solid var(--line);
    border-bottom-width: 2px;
    border-radius: 4px;
    color: var(--ink);
    background: var(--paper);
  }

  /* Illustrated search bar */
  .demo {
    margin: 1rem 0 0;
    padding: 1.1rem;
    background: var(--mist);
    border-radius: var(--radius);
  }
  .bar {
    display: flex;
    align-items: stretch;
    background: var(--paper);
    border: 1px solid #d6d6d3;
    border-radius: var(--radius);
    font-size: 0.85rem;
    overflow: hidden;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
  }
  .query {
    flex: 1;
    min-width: 0;
    padding: 0.65rem 0.8rem;
    color: var(--ink);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .caret {
    display: inline-block;
    width: 1px;
    height: 1em;
    margin-left: 1px;
    vertical-align: -2px;
    background: var(--ink);
    animation: blink 1.1s steps(1) infinite;
  }
  @keyframes blink {
    50% {
      opacity: 0;
    }
  }
  .select {
    display: flex;
    align-items: center;
    gap: 0.45rem;
    padding: 0 0.8rem;
    border-left: 1px solid var(--line);
    color: var(--ink);
    white-space: nowrap;
    font-weight: 500;
  }
  .select svg {
    width: 9px;
    height: 6px;
    fill: none;
    stroke: var(--muted);
    stroke-width: 1.5;
  }
  .go {
    display: flex;
    align-items: center;
    padding: 0 1rem;
    background: var(--ink);
    color: #fff;
    font-weight: 500;
  }
  .marks {
    display: flex;
    flex-wrap: wrap;
    gap: 0.35rem 1.1rem;
    margin-top: 0.75rem;
    font-size: 0.78rem;
    color: var(--muted);
  }
  .marks b {
    display: inline-grid;
    place-items: center;
    width: 1.15rem;
    height: 1.15rem;
    margin-right: 0.3rem;
    border-radius: 50%;
    background: var(--red-ink);
    color: #fff;
    font-size: 0.68rem;
    font-weight: 500;
  }
  @media (max-width: 520px) {
    .bar {
      flex-wrap: wrap;
    }
    .query {
      flex-basis: 100%;
      border-bottom: 1px solid var(--line);
    }
    .select {
      flex: 1;
      border-left: none;
      padding: 0.6rem 0.8rem;
    }
  }
</style>
