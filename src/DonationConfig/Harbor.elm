port module DonationConfig.Harbor exposing (select, focus)

port select : String -> Cmd msg
port focus : String -> Cmd msg
