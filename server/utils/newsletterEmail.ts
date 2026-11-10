import type { H3Event } from 'h3'

type NewsletterCode = { code: string; percent: number; expires_at: string; unsubscribe_token: string }

const escapeHtml = (text: string) => text.replace(/[&<>"']/g, (char) => `&#${char.charCodeAt(0)};`)

function codeEmailHtml({ code, percent, expires_at: expiresAt }: NewsletterCode, siteName: string, siteUrl: string, unsubscribeUrl: string) {
  const until = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'long', timeZone: 'Europe/Sarajevo' }).format(new Date(expiresAt))
  return `<div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; color: #1c1915;">
  <h2 style="font-weight: normal;">Hvala na prijavi</h2>
  <p>Drago nam je što ste s nama. Za vašu prvu kupnju poklanjamo vam ${percent} % popusta.</p>
  <p style="font-size: 24px; letter-spacing: 3px; border: 1px solid #c99a45; padding: 12px; text-align: center;">${escapeHtml(code)}</p>
  <p>Kod upišite u košarici prije slanja narudžbe. Vrijedi za jednu narudžbu, do ${until}.</p>
  ${siteUrl ? `<p><a href="${escapeHtml(siteUrl)}/proizvodi" style="display: inline-block; background: #1c1915; color: #ffffff; padding: 12px 24px; text-decoration: none;">Pogledaj kolekciju</a></p>` : ''}
  <p style="color: #6b6358; font-size: 14px;">${escapeHtml(siteName)}, Mepas Mall, Mostar</p>
  <p style="color: #6b6358; font-size: 12px;">Ovaj e-mail ste dobili jer ste se prijavili na naš newsletter. <a href="${escapeHtml(unsubscribeUrl)}" style="color: #6b6358;">Odjava</a></p>
</div>`
}

// Šalje kod kroz Resend. Bez NUXT_RESEND_API_KEY i NUXT_NEWSLETTER_FROM prijava se ipak spremi, a e-mail se ne šalje.
export async function sendNewsletterCode(event: H3Event, email: string, code: NewsletterCode) {
  const config = useRuntimeConfig(event)
  if (!config.resendApiKey || !config.newsletterFrom) {
    console.warn('Newsletter: e-mail s kodom nije poslan, jer nisu postavljeni NUXT_RESEND_API_KEY i NUXT_NEWSLETTER_FROM.')
    return false
  }

  const siteName = config.public.siteName || 'Viva'
  const siteUrl = (config.public.siteUrl || getRequestURL(event).origin).replace(/\/$/, '')
  // Poveznica vodi na /odjava, gdje se odjava potvrđuje gumbom, pa je skeneri poveznica u e-mailu ne pokrenu sami.
  const unsubscribeUrl = `${siteUrl}/odjava?token=${encodeURIComponent(code.unsubscribe_token)}`

  await $fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${config.resendApiKey}` },
    body: {
      from: config.newsletterFrom,
      to: [email],
      subject: `Vaš kod za ${code.percent} % popusta`,
      html: codeEmailHtml(code, siteName, siteUrl, unsubscribeUrl),
      headers: { 'List-Unsubscribe': `<${unsubscribeUrl}>` },
    },
  })
  return true
}
