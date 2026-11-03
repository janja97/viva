// Bez znakova koji se lako zamijene pri prepisivanju (l, 1, O, 0).
const CHARACTERS = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'

export function generatePassword(length = 16) {
  const limit = 256 - (256 % CHARACTERS.length)
  let password = ''
  while (password.length < length) {
    const [value] = crypto.getRandomValues(new Uint8Array(1))
    if (value! < limit) password += CHARACTERS[value! % CHARACTERS.length]
  }
  return password
}
