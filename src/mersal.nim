#[
     _   __ ___  ___    ___   _   __
  / \,' // _/ / o | ,' _/ .' \ / /
 / \,' // _/ /  ,' _\ `. / o // /_
/_/ /_//___//_/`_\/___,'/_n_//___/
                 Built by FOXOMAN

Send SMS and Otp in nim, a wrapper for TextBelt's (`http://textbelt.com`) public API
Sultan Al Isaee ~ foxoman @2022
See MIT LICENSE.txt for details of the license.
]#

## Mersal is an SMS/OTP API Wrapper for `textbelt` (`http://textbelt.com`) public API,
## that is built for developers who just want to send and receive SMS in nim.

import httpclient, json, strutils

proc sendSms*(mobile, message: string, key: string = "textbelt"):
    tuple[success: bool, smsId: string, credit: int, error: string] =
  ## Send an SMS with the following parameters:
  ## - `Mobile`, A mobile number. It is best to send the mobile number in `E.164` format with country code.
  ##        Example: +447712345678:
  ##
  ##        Prefix      Country code      Subscriber number
  ##          +           44 (UK)           7712345678
  ##
  ## **See:**
  ##
  ## * https://docs.textbelt.com/faq#how-should-i-format-my-phone-numbers
  ##
  ## - `Message`, The content of your SMS.
  ## - `key`, Your API key ( Use `textbelt` to send one free message per day ).
  ##
  ## **See:**
  ##
  ## * https://textbelt.com/create-key/
  ##
  ## This proc will return the follwing tuple:
  ## - `success`, Whether the message was successfully sent (true/false).
  ## - `smsId`, The ID of the sent message, used for looking up its status.
  ##            Only present when success=true.
  ## - `credit`, The amount of credit remaining on your key.
  ## - `error`: A string describing the problem. Only present when success=false.

  let client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})

  let body = %*{"phone": mobile,
      "message": message,
      "key": key,
    }

  try:
    let response = client.request("https://textbelt.com/text",
        httpMethod = HttpPost, body = $body)

    let db = parseJson response.body
    client.close()

    if not db["success"].getBool():
      return (false, "", -1, db["error"].getStr())
    else:
      return (true, db["textId"].getStr(), db["quotaRemaining"].getInt(), "")

  except:
    echo getCurrentExceptionMsg()

proc smsStatus*(smsId: string): string =
  ## Checking SMS delivery status
  ## If you are given a smsId and want to check its delivery status.
  ## Possible return values include:
  ## - `DELIVERED`, Carrier has confirmed sending
  ## - `SENT`, Sent to carrier but confirmation receipt not available
  ## - `SENDING`, Queued or dispatched to carrier
  ## - `FAILED`, Not received
  ## - `UNKNOWN`, Could not determine status
  ##
  ## Delivery statuses are not standardized between mobile carriers.
  ## Some carriers will report SMS as `delivered` when they attempt
  ## transmission to the handset while other carriers actually report
  ## delivery receipts from the handsets.
  ## Some carriers do not have a way of tracking delivery,
  ## so all their messages will be marked `SENT`.

  let client = newHttpClient()

  try:
    let response = client.request("https://textbelt.com/status/$1" % [smsId],
        httpMethod = HttpGet)

    let db = parseJson response.body
    client.close()

    return db["status"].getStr()

  except:
    echo getCurrentExceptionMsg()

proc creditBalance*(key: string): int =
  ## You may want to know how much quota or credit you have left on a key.
  ## THe resposnse will contain the amount of SMS credit remaining on this key

  let client = newHttpClient()

  try:
    let response = client.request("https://textbelt.com/quota/$1" % [$key],
        httpMethod = HttpGet)

    let db = parseJson response.body
    client.close()

    return db["quotaRemaining"].getInt()

  except:
    echo getCurrentExceptionMsg()

proc sendOtp*(mobile, userId: string,
    message: string = "Your verification code is $OTP",
    key: string = "textbelt",
    lifetime: int = 180, length: int = 6):
    tuple[ok: bool, smsId: string, credit: int, otp: string] =
  ## Will create a one-time code and send it to the user's phone.
  ## requires the following parameters:
  ## - `mobile`, A mobile phone number.
  ## - `userId`, An id that is unique to your user.  This can be any string.
  ## - `message`, The content of your SMS.
  ##    Use the $OTP variable to include the OTP in your message.
  ## - `key`, Your Textbelt API key.
  ## - `lifetime`, Determines how many seconds the OTP is valid for.
  ##    Defaults to 180, or 3 minutes.
  ## - `length`, The number of digits in your OTP.
  ##    Defaults to 6.
  ##
  ## This proc will return the follwing tuple:
  ## - `success`, Whether the otp was successfully sent.
  ## - `smsId`, The ID of the text message sent, so you can track its delivery.
  ## - `credit`, The amount of credit left on your key.
  ## - `otp`, The one-time verification code sent to the user.

  let client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})

  let body = %*{"phone": mobile,
      "userid": userId,
      "key": key,
      "message": message,
      "lifetime": lifetime,
      "length": length,
    }

  try:
    let response = client.request("https://textbelt.com/otp/generate",
        httpMethod = HttpPost, body = $body)

    let db = parseJson response.body

    client.close()

    if not db["success"].getBool():
      return (false, "", db["quotaRemaining"].getInt(), db["otp"].getStr())
    else:
      return (true, db["textId"].getStr(), db["quotaRemaining"].getInt(), db[
          "otp"].getStr())

  except:
    echo getCurrentExceptionMsg()

proc isValidOtp *(otp, userId: string, key: string = "textbelt"): bool =
  ## Once you've sent the one-time code, your user will enter a code
  ## on your website or application.  You can use this proc to confirm
  ## that the code is valid.
  ##
  ## requires the following parameters:
  ## - `otp`, The code entered by the user.
  ## - `userid`, The ID of the user. Should match the id that you
  ##    used in the prior `sendOtp()` proc.
  ## - `key`, Your Textbelt API key.
  ##
  ## This proc will return the follwing bool:
  ## - `true`, if OTP is correct for the given userid, `false` if not.

  let client = newHttpClient()

  try:
    let response = client.request("https://textbelt.com/otp/verify?otp=$1&userid=$2&key=$3" %
        [otp, userId, key], httpMethod = HttpGet)

    let db = parseJson response.body
    client.close()

    return db["isValidOtp"].getBool()

  except:
    echo getCurrentExceptionMsg()
