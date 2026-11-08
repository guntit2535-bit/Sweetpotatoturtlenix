# Jobs only the developer can do

Claude keeps working while these wait. Tick them when done and tell Claude.

## Now (needed for the saves to work in Studio and live)
- [x] Game Settings -> Security -> **Enable Studio Access to API Services** = on, then Save. (checked 2026-11-08)
- [ ] Game Settings -> Places / Basic Info: **Max players = 8** (a Studio Play still showed 60: please check and publish).
- [ ] File -> Publish to Roblox once the milestone 1 test build is ready (the live game uses the published place).

## Later (milestone 2)
- [ ] Game passes and developer products in the group's experience; send the ids.
- [ ] Sound ids (Claude sends a list to fill in), including the Secret event music (Config.Events.MusicId).
- [ ] Phone test of the HUD and the whole loop, and a test with 2+ players (Test tab -> Clients and Servers -> 2 players):
  like the other player's pen sign -> toast + faster walking for 5 min; a second like the same day is refused;
  both fish the same cat (first full bar wins, the other is dropped); hit the carrier with the bat outside the
  lobby -> the cat drops and they fly; no hits inside the lobby or on someone fishing.
- [ ] 2-player trade test (milestone 2): Trade -> Ask -> the other taps Accept; put cats in; both Ready -> after 5 s
  the cats swap and stay after rejoining; changing an offer clears Ready; a locked cat cannot be added; leaving
  mid-trade cancels it.
