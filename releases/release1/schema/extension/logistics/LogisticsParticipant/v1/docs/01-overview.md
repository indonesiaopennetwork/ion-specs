# LogisticsParticipant v1 overview

`LogisticsParticipant` is a thin extension of the core Participant. It identifies
whether a participant acts as a courier, driver, or customs broker without
duplicating the participant's core identity or runtime assignment.

The ION layer groups Indonesian SIM and PPJK fields into `DriverLicence` and
`CustomsBrokerLicence`. Flow rules determine when each licence is required.
