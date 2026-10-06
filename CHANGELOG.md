# Changelog

## 0.1.0

- Guarantee a geographically valid event on every successful shelter exit into a game zone, with a large map/event announcement after it spawns.
- Include Punisher, Airdrops, Attack Helicopters, Helicopter Crash Sites, Bogeyman, Driver, and Nomad Gatherings at their stock locations.
- Remove non-BTR day, weekday, night, reputation, chance, and random-delay gates. Remove Fighter Jets.
- Preserve stock BTR unlocks, selection probability, spawn roll, and timing independently, allowing BTR to accompany the guaranteed event.
- Retain ordinary zone-travel scheduling, stationary trader progression, story events, and random AI group behavior.
- Validate spawn prerequisites, retry another eligible encounter after a failed spawn, and clear announcements and pending mod scheduling during travel.
- Tested against game 0.2.0.5, Steam build 25710663, Metro 3.4.1, and Godot 4.6.3. Player testing confirms repeated shelter exits; automated announcement, scheduler, and event/hook integration checks pass. Broader event/map gameplay coverage remains ongoing.
