// Godina sljedeće mature: od rujna se već traže haljine za maturu iduće godine (npr. u studenom 2026. to je 2027.).
export function seasonYear(date = new Date()) {
  return date.getMonth() >= 8 ? date.getFullYear() + 1 : date.getFullYear()
}

// Zamjenjuje {godina} u tekstovima kategorija, kako se naslovi ne bi morali mijenjati svake godine.
export function fillYear(text: string, date = new Date()) {
  return text.replaceAll('{godina}', String(seasonYear(date)))
}
