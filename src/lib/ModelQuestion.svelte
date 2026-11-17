<script>
  import { SATISFACTION_LABELS } from '../config.js';

  /** @type {{ label: string, name: string, order: number, value: { queries: number, found: boolean, satisfaction: number|null } }} */
  let { label, name, order, value = $bindable() } = $props();

  // At least one search is always made, so the count starts at 1 and never goes lower.
  const MIN = 1;
  const MAX = 100;

  let complete = $derived(!!value.satisfaction);

  const clamp = (n) => Math.max(MIN, Math.min(MAX, n));

  function setQueries(e) {
    const digits = e.currentTarget.value.replace(/\D/g, '').slice(0, 3);
    e.currentTarget.value = digits;
    const n = parseInt(digits, 10);
    // While the field is empty (mid-edit) the stored value stays valid; blur restores the text.
    value.queries = Number.isNaN(n) ? MIN : clamp(n);
  }

  function syncField(e) {
    e.currentTarget.value = String(value.queries);
  }

  function step(delta) {
    value.queries = clamp((value.queries ?? MIN) + delta);
  }
</script>

<section class="model" class:complete aria-labelledby="{name}-title">
  <header>
    <span class="caps order">Modelo {order}</span>
    <h3 id="{name}-title">{label}</h3>
    <span class="status" aria-hidden="true">{complete ? 'Completo' : ''}</span>
  </header>

  <div class="q">
    <label for="{name}-queries">
      {#if value.found}
        ¿Cuántas consultas (búsquedas) hiciste hasta encontrar el resultado deseado?
      {:else}
        ¿Cuántas consultas (búsquedas) alcanzaste a hacer antes de rendirte?
      {/if}
    </label>
    <div class="stepper">
      <button type="button" onclick={() => step(-1)} disabled={value.queries <= MIN} aria-label="Restar una consulta">−</button>
      <input
        id="{name}-queries"
        type="text"
        inputmode="numeric"
        autocomplete="off"
        value={value.queries}
        oninput={setQueries}
        onblur={syncField}
        onfocus={(e) => e.currentTarget.select()}
      />
      <button type="button" onclick={() => step(1)} disabled={value.queries >= MAX} aria-label="Sumar una consulta">+</button>
    </div>

    <label class="notfound">
      <input type="checkbox" checked={!value.found} onchange={(e) => (value.found = !e.currentTarget.checked)} />
      <span>No logré encontrar la imagen con este modelo</span>
    </label>
  </div>

  <div class="q">
    <span class="qlabel" id="{name}-sat">¿Qué tan satisfecho/a quedaste con los resultados?</span>
    <div class="scale" role="radiogroup" aria-labelledby="{name}-sat">
      {#each [1, 2, 3, 4, 5] as n}
        <label class="opt" class:selected={value.satisfaction === n}>
          <input
            type="radio"
            name="{name}-satisfaction"
            value={n}
            checked={value.satisfaction === n}
            onchange={() => (value.satisfaction = n)}
            aria-label="{n}: {SATISFACTION_LABELS[n]}"
          />
          <span>{n}</span>
        </label>
      {/each}
    </div>
    <div class="ends" aria-hidden="true">
      <span>{SATISFACTION_LABELS[1]}</span>
      <span class="chosen">{value.satisfaction ? SATISFACTION_LABELS[value.satisfaction] : ''}</span>
      <span>{SATISFACTION_LABELS[5]}</span>
    </div>
  </div>
</section>

<style>
  .model {
    padding: 1.5rem 0;
    border-top: 1px solid var(--line);
  }
  header {
    display: flex;
    align-items: baseline;
    gap: 0.8rem;
    margin-bottom: 1.2rem;
  }
  .order {
    color: var(--muted);
  }
  h3 {
    font-size: 1.6rem;
  }
  .status {
    margin-left: auto;
    font-size: 0.78rem;
    color: var(--ok);
  }
  .complete .status::before {
    content: '✓ ';
  }

  .q {
    margin-bottom: 1.4rem;
  }
  .q:last-child {
    margin-bottom: 0;
  }
  .q > label:first-child,
  .qlabel {
    display: block;
    font-size: 0.95rem;
    color: var(--ink);
    margin-bottom: 0.6rem;
  }
  .stepper {
    display: inline-flex;
    border: 1px solid var(--line);
    border-radius: var(--radius);
    overflow: hidden;
    transition: border-color 0.15s;
  }
  .stepper:focus-within {
    border-color: var(--red-ink);
    box-shadow: 0 0 0 3px rgba(196, 27, 30, 0.12);
  }
  .stepper button {
    width: 2.75rem;
    border: none;
    background: var(--paper);
    color: var(--ink);
    font-size: 1.15rem;
  }
  .stepper button:hover:not(:disabled) {
    background: var(--mist);
  }
  .stepper button:disabled {
    color: #c4c4c1;
    cursor: default;
  }
  .stepper input {
    width: 4rem;
    border: none;
    border-left: 1px solid var(--line);
    border-right: 1px solid var(--line);
    border-radius: 0;
    text-align: center;
    font-family: var(--serif);
    font-size: 1.5rem;
    font-weight: 600;
    padding: 0.3rem 0;
    color: var(--ink);
  }
  .stepper input:focus-visible {
    outline: none;
    box-shadow: none;
  }

  .notfound {
    display: flex;
    align-items: center;
    gap: 0.55rem;
    margin-top: 0.75rem;
    font-size: 0.88rem;
    color: var(--muted);
    cursor: pointer;
    width: fit-content;
  }

  .scale {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    border: 1px solid var(--line);
    border-radius: var(--radius);
    overflow: hidden;
  }
  .opt {
    position: relative;
    display: grid;
    place-items: center;
    height: 3rem;
    cursor: pointer;
    font-family: var(--serif);
    font-size: 1.35rem;
    font-weight: 600;
    color: var(--ink);
    background: var(--paper);
    transition: background 0.15s, color 0.15s;
  }
  .opt + .opt {
    border-left: 1px solid var(--line);
  }
  .opt:hover {
    background: var(--red-tint);
  }
  .opt.selected {
    background: var(--red-ink);
    color: #fff;
  }
  .opt input {
    position: absolute;
    inset: 0;
    opacity: 0;
    margin: 0;
    cursor: pointer;
  }
  .opt:has(input:focus-visible) {
    outline: 2px solid var(--red-ink);
    outline-offset: -4px;
  }
  .opt.selected:has(input:focus-visible) {
    outline-color: #fff;
  }
  .ends {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    gap: 0.5rem;
    margin-top: 0.45rem;
    font-size: 0.75rem;
    color: var(--muted);
  }
  .ends span:last-child {
    text-align: right;
  }
  .chosen {
    color: var(--red-ink);
    font-weight: 500;
  }
</style>
