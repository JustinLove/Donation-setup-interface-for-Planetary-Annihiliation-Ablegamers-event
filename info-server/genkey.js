require('js-nacl').instantiate(function(nacl) {
  var pair = nacl.crypto_sign_keypair()
  console.log("signPk", nacl.to_hex(pair.signPk))
  console.log("signSk", nacl.to_hex(pair.signSk))
})
