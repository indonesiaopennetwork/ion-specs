# Delivery attempts v1

Failed attempts are durable `LogisticsPerformance.attempts` entries. The branch
supports only the three reviewed re-attempt policies and resolves the shared
`delivery-attempts` flow ID used by the state registry.
