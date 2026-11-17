<script>
  import { CONTACT } from '../config.js';

  /** compact: one-line version for the footer */
  let { compact = false } = $props();
</script>

{#if compact}
  <p class="compact">
    ¿Algo no funciona?
    <a href={CONTACT.whatsappUrl} target="_blank" rel="noopener">WhatsApp {CONTACT.whatsappDisplay}</a>
    <span aria-hidden="true">·</span>
    <a href={CONTACT.instagramUrl} target="_blank" rel="noopener">Instagram {CONTACT.instagramDisplay}</a>
  </p>
{:else}
  <div class="contact">
    <p class="caps label">¿Algo no funciona?</p>
    <p class="note">
      Si la página o el buscador presentan algún error, escríbeme y lo resolvemos.
    </p>
    <ul>
      <li>
        <a href={CONTACT.whatsappUrl} target="_blank" rel="noopener">
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2a8.2 8.2 0 0 1-4.2-1.2l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8s-.4-.1-.6.1-.7.8-.8 1-.3.2-.5.1a6.7 6.7 0 0 1-3.3-2.9c-.3-.4.3-.4.7-1.3.1-.2 0-.3 0-.4l-.8-1.8c-.2-.5-.4-.4-.6-.4h-.5a1 1 0 0 0-.7.3 3 3 0 0 0-.9 2.2 5.2 5.2 0 0 0 1.1 2.7 11.8 11.8 0 0 0 4.5 4c1.7.7 2.3.8 3.2.6a2.7 2.7 0 0 0 1.8-1.2 2.2 2.2 0 0 0 .1-1.3c0-.1-.2-.2-.5-.3Z"/></svg>
          <span>
            <span class="kind">WhatsApp</span>
            <span class="value">{CONTACT.whatsappDisplay}</span>
          </span>
        </a>
      </li>
      <li>
        <a href={CONTACT.instagramUrl} target="_blank" rel="noopener">
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10Zm0 8.2a3.2 3.2 0 1 1 0-6.4 3.2 3.2 0 0 1 0 6.4Zm6.4-8.4a1.2 1.2 0 1 1-2.4 0 1.2 1.2 0 0 1 2.4 0ZM21.9 8a5.8 5.8 0 0 0-1.6-4.1A5.8 5.8 0 0 0 16.2 2.3C14.6 2.2 9.4 2.2 7.8 2.3a5.8 5.8 0 0 0-4.1 1.6A5.8 5.8 0 0 0 2.1 8c-.1 1.6-.1 6.8 0 8.4a5.8 5.8 0 0 0 1.6 4.1 5.8 5.8 0 0 0 4.1 1.6c1.6.1 6.8.1 8.4 0a5.8 5.8 0 0 0 4.1-1.6 5.8 5.8 0 0 0 1.6-4.1c.1-1.6.1-6.8 0-8.4Zm-2.1 10.2a3.3 3.3 0 0 1-1.9 1.9c-1.3.5-4.4.4-5.9.4s-4.6.1-5.9-.4a3.3 3.3 0 0 1-1.9-1.9c-.5-1.3-.4-4.4-.4-5.9s-.1-4.6.4-5.9A3.3 3.3 0 0 1 6.1 4.5c1.3-.5 4.4-.4 5.9-.4s4.6-.1 5.9.4a3.3 3.3 0 0 1 1.9 1.9c.5 1.3.4 4.4.4 5.9s.1 4.6-.4 5.9Z"/></svg>
          <span>
            <span class="kind">Instagram</span>
            <span class="value">{CONTACT.instagramDisplay}</span>
          </span>
        </a>
      </li>
    </ul>
  </div>
{/if}

<style>
  .label {
    color: var(--muted);
    margin-bottom: 0.4rem;
  }
  .note {
    font-size: 0.92rem;
    color: var(--muted);
    margin-bottom: 0.9rem;
  }
  ul {
    list-style: none;
    margin: 0;
    padding: 0;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.6rem;
  }
  li a {
    display: flex;
    align-items: center;
    gap: 0.7rem;
    padding: 0.7rem 0.8rem;
    border: 1px solid var(--line);
    border-radius: var(--radius);
    text-decoration: none;
    color: var(--ink);
    transition: border-color 0.15s;
  }
  li a:hover {
    border-color: var(--ink);
    color: var(--ink);
  }
  svg {
    width: 22px;
    height: 22px;
    fill: var(--red-ink);
    flex: none;
  }
  .kind {
    display: block;
    font-size: 0.75rem;
    color: var(--muted);
    line-height: 1.2;
  }
  .value {
    display: block;
    font-weight: 500;
    font-size: 0.92rem;
    white-space: nowrap;
  }
  .compact {
    font-size: 0.85rem;
    color: var(--muted);
  }
  .compact a {
    white-space: nowrap;
  }
  @media (max-width: 420px) {
    ul {
      grid-template-columns: 1fr;
    }
  }
</style>
