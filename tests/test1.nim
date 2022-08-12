# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import mersal

const fKey = "e4db6c429db10dc900f88af83e8a9dd08f5a3d46Qq3zJ2xF8DeT3FToynV1h3ZXZ"
const userId = "foxoman"
const userMobile = "+96896101015"
var
  smsid: string
  smsotp: string

test "Sending New Sms":
  let (ok, id, credit, err) = sendSms(userMobile,
      "Hello World From Nim and Mersal!", fKey)
  smsid = id
  check ok == true

test "sms status":
  let ok = smsStatus(smsid)
  echo ok

test "SendOtp":
  let (ok, id, credit, otp) = sendOtp(userMobile, userId,
      "Hello HI, $OTP", fKey)
  smsotp = otp
  check ok == true

test "Validate Otp":
  check isValidOtp(smsotp, userId, fKey) == true

test "Credit Balance":
  echo creditBalance(fKey)
