# Driver Android acceptance gates

U06 source-level resilience coverage is in
`apps/driver_app/test/driver_resilience_states_test.dart`.

The focused test covers:

- denied location permission copy and the Settings recovery action;
- reconnect/error state with a single retry action;
- long Arabic pickup/destination text and a large price at 2x text scaling;
- active-order restoration to the operational route.

Device acceptance remains pending until a real Android device/emulator is
available. Verify denied and denied-forever location permission flows, resume
after Settings, offline/reconnect behavior, and active-order restore on the
target Android API levels. Map rendering/navigation also requires a valid
Google Maps key and configured platform restrictions; this source-level test
does not claim Maps or GPS-device acceptance.
