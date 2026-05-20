Base on this command:
llmdbenchmark --spec guides/pd-disaggregation standup --namespace <my-ns>
plan a new deplyment guide called 'epd-pools-disaggregation' which implements:
- three EPPs: epp-encode, epp-prefill and epp-decode
- three inference pools for the EPPs above
- epp-encode is connected to epp-encode-inference-pool, that has 1 Encode vllm
- epp-prefill is connected to epp-prefill-inference-pool, that has 1 Prefill vllm
- epp-decode is connected to epp-decode-inference-pool, that has 1 Decode vllm
- create HTTPRoutes of all three EPPs.

EndpointPickerConfig - one of each EPP
