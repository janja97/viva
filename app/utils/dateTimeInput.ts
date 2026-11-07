// Polje datetime-local radi s lokalnim vremenom bez zone, a baza čuva točan trenutak.
export function toDateTimeInput(iso: string | null) {
  if (!iso) return ''
  const date = new Date(iso)
  return new Date(date.getTime() - date.getTimezoneOffset() * 60_000).toISOString().slice(0, 16)
}

export const fromDateTimeInput = (value: string) => new Date(value).toISOString()
