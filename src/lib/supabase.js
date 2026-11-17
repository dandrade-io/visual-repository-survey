import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabaseConfigured = Boolean(url && key);

export const supabase = supabaseConfigured
  ? createClient(url, key, { auth: { persistSession: false } })
  : null;

const isDuplicate = (error) => error?.code === '23505';

/**
 * Saves the participant and all their answers. Safe to retry: rows that
 * were already stored by a previous attempt are ignored.
 */
export async function submitSurvey(participant, answers) {
  if (!supabase) throw new Error('Supabase no está configurado (revisa las variables VITE_SUPABASE_*).');

  const p = await supabase.from('participants').insert({
    id: participant.id,
    name: participant.name,
    email: participant.email,
    career: participant.career,
    user_agent: navigator.userAgent,
  });
  if (p.error && !isDuplicate(p.error)) throw p.error;

  const rows = answers.map((a, i) => ({
    participant_id: participant.id,
    position: i + 1,
    image_id: a.image.id,
    image_original: a.image.original,
    jina_queries: a.jina.queries,
    jina_found: a.jina.found,
    jina_satisfaction: a.jina.satisfaction,
    siglip_queries: a.siglip.queries,
    siglip_found: a.siglip.found,
    siglip_satisfaction: a.siglip.satisfaction,
  }));

  const r = await supabase.from('responses').insert(rows);
  if (r.error && !isDuplicate(r.error)) throw r.error;
}
