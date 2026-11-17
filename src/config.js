// Survey settings — edit here.

/** How many images each participant evaluates. */
export const IMAGES_PER_PARTICIPANT = 12;

/**
 * Accepted email domains (the part after "@", subdomains included).
 * Leave the array empty to accept any email.
 */
export const ALLOWED_EMAIL_DOMAINS = ['usfq.edu.ec'];

/** The search engine participants use. */
export const SEARCH_ENGINE_URL = 'https://visual-repository.dandrade.io/';

/** Contact shown on every page in case something goes wrong. */
export const CONTACT = {
  whatsappDisplay: '+593 99 601 2797',
  whatsappUrl:
    'https://wa.me/593996012797?text=' +
    encodeURIComponent('Hola, tengo un problema con la encuesta del buscador visual.'),
  instagramDisplay: '@dandrade.ig',
  instagramUrl: 'https://instagram.com/dandrade.ig',
};

/** The two embedding models, in the order they appear in each question. */
export const MODELS = [
  { key: 'jina', label: 'JinaCLIP v2' },
  { key: 'siglip', label: 'SigLIP 2' },
];

/** Labels for the 1–5 satisfaction scale. */
export const SATISFACTION_LABELS = {
  1: 'Nada satisfecho/a',
  2: 'Poco satisfecho/a',
  3: 'Neutral',
  4: 'Satisfecho/a',
  5: 'Muy satisfecho/a',
};
