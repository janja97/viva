// Zaštita newslettera od botova koji upisuju tuđe adrese ("subscription bombing").
// Isto pravilo za adresu ima i baza (newsletter_email_ok, migracija 0050).

// Forma poslana brže od ovoga (od učitavanja) je bot.
export const NEWSLETTER_MIN_FILL_MS = 2500

const GMAIL_DOMAINS = ['gmail.com', 'googlemail.com']

// Adrese koje e-mail pretvaraju u SMS na nečiji mobitel.
const SMS_GATEWAY_DOMAINS = [
  'vtext.com', 'vzwpix.com', 'txt.att.net', 'mms.att.net', 'tmomail.net',
  'messaging.sprintpcs.com', 'pm.sprint.com', 'msg.fi.google.com',
  'sms.myboostmobile.com', 'mymetropcs.com', 'email.uscc.net', 'vmobl.com',
]

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i
const INVALID = 'Upišite ispravnu e-mail adresu.'

export function checkNewsletterEmail(raw: unknown): { ok: true; email: string } | { ok: false; message: string } {
  const email = String(raw ?? '').trim().toLowerCase()
  if (email.length > 200 || !EMAIL_RE.test(email)) return { ok: false, message: INVALID }

  const [local = '', domain = ''] = email.split('@')
  if (SMS_GATEWAY_DOMAINS.includes(domain)) return { ok: false, message: INVALID }

  // Gmail zanemaruje točkice, pa ih botovi dodaju da zaobiđu provjeru iste adrese.
  if (GMAIL_DOMAINS.includes(domain) && (local.split('+')[0] ?? '').split('.').length - 1 >= 3) {
    return { ok: false, message: 'Gmail adresu upišite bez točkica (npr. imeprezime@gmail.com).' }
  }
  return { ok: true, email }
}
