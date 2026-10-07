# Changelog

## 0.1.1

- Zone-to-zone travel now gets the same guaranteed, announced event as leaving a shelter. Entering a shelter, tutorial travel, and loading a saved game keep stock scheduling.
- Driver can appear on any map with usable vehicle paths: Highway, Outpost, School, Village, Airfield, Apartments, and Terminal. The bus is larger than the Punisher car, so roads outside Highway are untested for clipping.
- Tested against game 0.2.0.5, Steam build 25710663, Metro 3.4.2, and Godot 4.6.3 with automated scheduler and hook integration checks. In-game testing of both changes is pending.

## 0.1.0

- Guarantee a geographically valid event on every successful shelter exit into a game zone, with a large map/event announcement after it spawns.
- Include Punisher, Airdrops, Attack Helicopters, Helicopter Crash Sites, Bogeyman, Driver, and Nomad Gatherings at their stock locations.
- Remove non-BTR day, weekday, night, reputation, chance, and random-delay gates. Remove Fighter Jets.
- Preserve stock BTR unlocks, selection probability, spawn roll, and timing independently, allowing BTR to accompany the guaranteed event.
- Retain ordinary zone-travel scheduling, stationary trader progression, story events, and random AI group behavior.
- Validate spawn prerequisites, retry another eligible encounter after a failed spawn, and clear announcements and pending mod scheduling during travel.
- Tested against game 0.2.0.5, Steam build 25710663, Metro 3.4.1, and Godot 4.6.3. Player testing confirms repeated shelter exits; automated announcement, scheduler, and event/hook integration checks pass. Broader event/map gameplay coverage remains ongoing.
