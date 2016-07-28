module Nacl exposing (..)

import Native.Nacl

type UInt8Array = UInt8Array

to_hex : UInt8Array -> String
to_hex =
  Native.Nacl.to_hex

from_hex : String -> UInt8Array
from_hex =
  Native.Nacl.from_hex

decode_utf8 : UInt8Array -> String
decode_utf8 =
  Native.Nacl.decode_utf8

encode_utf8 : String -> UInt8Array
encode_utf8 =
  Native.Nacl.encode_utf8

crypto_sign : UInt8Array -> UInt8Array -> UInt8Array
crypto_sign =
  Native.Nacl.crypto_sign

crypto_sign_open : UInt8Array -> UInt8Array -> Maybe UInt8Array
crypto_sign_open =
  Native.Nacl.crypto_sign_open
