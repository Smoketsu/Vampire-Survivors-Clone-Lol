## Rules for what a Web page's address may switch on (adversarial review, Fix 4).
##
## GameState._web_args() turns the page's `?necro_autotest=` into autotest flags,
## so the headless Chromium tools (tools/mobile_web_perf.js, coop_web_perf.js,
## coop_web_lockstep.js) can start a test run on an exported build. A link is
## something anyone can send to a player, so no flag that reaches the player's
## save, or sends data anywhere, may come from it: those are read only from the
## real command line. Data only, no logic.
class_name WebLinkData
extends RefCounted

## Autotest flags the page address may never set. An entry ending in "=" matches
## every value of that flag. --meta-save would let the bot run write the player's
## real save; --feedback-url= would point the Feedback form at another site;
## --relay= would pick the co-op relay (test runs use ?relay= instead, CoopNet).
const FORBIDDEN_ARGS: Array[String] = ["--meta-save", "--feedback-url=", "--relay="]  # TUNING (not in GDD)
