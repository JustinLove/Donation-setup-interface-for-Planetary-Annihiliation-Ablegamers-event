var _user$project$Native_Nacl = function() {
  var nacl
  nacl_factory.instantiate(function(n) {nacl = n})

  var uint8array = function(array) {
    return {
      ctor: '_UInt8Array',
      value: array,
    }
  }

  var to_hex = function(array) {
    return nacl.to_hex(array.value)
  }

  var from_hex = function(string) {
    return uint8array(nacl.from_hex(string))
  }

  var decode_utf8 = function(array) {
    return nacl.decode_utf8(array.value)
  }

  var encode_utf8 = function(string) {
    return uint8array(nacl.encode_utf8(string))
  }

  var crypto_sign = function(msgBin, signerSecretKey) {
    return uint8array(nacl.crypto_sign(msgBin.value, signerSecretKey.value))
  }

  var crypto_sign_open = function(packetBin, signerPublicKey) {
    var msg = nacl.crypto_sign_open(packetBin.value, signerPublicKey.value)
    if (msg) {
      _elm_lang$core$Maybe$Just(uint8array(msg))
    } else {
      _elm_lang$core$Maybe$Nothing
    }
  }

  return {
    to_hex: to_hex,
    from_hex: from_hex,
    encode_utf8: encode_utf8,
    decode_utf8: decode_utf8,
    crypto_sign: F2(crypto_sign),
    crypto_sign_open: F2(crypto_sign_open),
  };
}();
