# Plan: `epd-pools-disaggregation` deployment guide

## Context

A new llm-d-benchmark deployment guide called **`epd-pools-disaggregation`** modeled after the existing [`pd-disaggregation`](config/scenarios/guides/pd-disaggregation.yaml), but with **three independent single-vLLM pools** instead of one combined prefill+decode pool. Each pool stands alone — its own EPP, InferencePool, vLLM workload, and HTTPRoute.

Target topology:

```
Gateway (infra-llmdbench, shared)
├── HTTPRoute #1 → InferencePool (epp-encode)  → 1 vLLM (encode role)
├── HTTPRoute #2 → InferencePool (epp-prefill) → 1 vLLM (prefill role)
└── HTTPRoute #3 → InferencePool (epp-decode)  → 1 vLLM (decode role)
```

**Why a multi-stack scenario:** the codebase already has a multi-stack pattern (canonical example: [`config/scenarios/examples/multi-model-wva.yaml`](config/scenarios/examples/multi-model-wva.yaml)). The renderer (`render_plans._process_stack`) merges a `shared:` block into each stack and produces one `{model_id_label}-ms` + one `{model_id_label}-gaie` Helm release per stack. This gives 3 EPPs, 3 InferencePools, and 3 HTTPRoutes with **zero changes to Python orchestrator code**.

**Constraint that drove the design:** the `llm-d-modelservice` Helm chart hardcodes only `prefill` and `decode` roles ([`config/templates/jinja/13_ms-values.yaml.j2`](config/templates/jinja/13_ms-values.yaml.j2) — no `encode` block exists). And [`step_09_deploy_modelservice.py:127`](llmdbenchmark/standup/steps/step_09_deploy_modelservice.py#L127) unconditionally waits for `llm-d.ai/role=decode` pods. So each stack's single vLLM is deployed via the chart's `decode` block (with `decode.replicas=1, prefill.replicas=0`) — semantic role names (Encode/Prefill/Decode) live only in the user-facing `name` and `model.name` fields. This is acceptable because the task is **3 independent pools**, not chained PD-style routing — the routing-proxy sidecar that the chart attaches to decode pods is harmless overhead in single-pod mode.

## Files to create

### 1. Spec template — minimal pointer file

**Path:** `config/specification/guides/epd-pools-disaggregation.yaml.j2`

Mirror [`config/specification/guides/pd-disaggregation.yaml.j2`](config/specification/guides/pd-disaggregation.yaml.j2) verbatim except change `scenario_file.path` to point at the new scenario file:

```yaml
{% set base_dir = base_dir | default('../') -%}
base_dir: {{ base_dir }}

values_file:
  path: {{ base_dir }}/config/templates/values/defaults.yaml

template_dir:
  path: {{ base_dir }}/config/templates/jinja

scenario_file:
  path: {{ base_dir }}/config/scenarios/guides/epd-pools-disaggregation.yaml
```

### 2. Scenario file — 3-stack `shared: + scenario:` layout

**Path:** `config/scenarios/guides/epd-pools-disaggregation.yaml`

Use the multi-stack pattern from [`config/scenarios/examples/multi-model-wva.yaml`](config/scenarios/examples/multi-model-wva.yaml) as the structural template, adapted for these requirements.

**Top-level structure:**

```yaml
shared:
  # ... applied to every stack BEFORE per-stack overrides
scenario:
  - name: epd-encode  # stack 1
    ...
  - name: epd-prefill  # stack 2
    ...
  - name: epd-decode  # stack 3
    ...
```

**`shared:` block contents** (copy-adapt from `pd-disaggregation.yaml`):

- `modelservice.enabled: true`, `standalone.enabled: false`
- `routing.connector: nixlv2` (same as pd-disaggregation)
- `storage.modelPvc.size: 1Ti` — **single shared PVC** for all three stacks (model weights downloaded once, reused)
- `vllmCommon` block: identical to pd-disaggregation's (`volumes`, `volumeMounts`, etc.)
- `prefill: { enabled: false, replicas: 0 }` — prefill block disabled across all stacks
- `harness.name: vllm-benchmark`, `workDir: "~/data/epd-pools-disaggregation"`
- `timeouts` and `annotations` as in pd-disaggregation
- **No** `inferenceExtension.pluginsCustomConfig` here — that goes per-stack so each EPP gets its own EndpointPickerConfig (per the requirement "one of each EPP")
- **No** `httpRoute.mode` here — letting it default produces per-stack HTTPRoutes (3 separate route objects — exactly what the task asks for)

**Per-stack contents** — three nearly-identical entries.

For each stack `<role>` ∈ {`encode`, `prefill`, `decode`}:

```yaml
- name: epd-<role>
  model:
    name: Qwen/Qwen3-32B-<role>      # role-suffixed → distinct model_id_label
    shortName: qwen-qwen3-32b-<role>
    path: models/Qwen/Qwen3-32B      # SAME path → shared weights download
    huggingfaceId: Qwen/Qwen3-32B    # SAME HF ID → single download Job
    size: 1Ti
    maxModelLen: 32768
    blockSize: 128
    gpuMemoryUtilization: 0.95       # carries over the prior fix for KV-cache headroom

  decode:
    replicas: 1
    vllm:
      customCommand: |
        # copy verbatim from pd-disaggregation.yaml's decode.vllm.customCommand
        # (vllm serve … with NixlConnector kv_role="kv_both" …)
    initContainers:
      # copy verbatim from pd-disaggregation.yaml's decode.initContainers
    parallelism:
      tensor: 1                      # single GPU per pool
      data: 1
      dataLocal: 1
      workers: 1
    resources:                       # same as pd-disaggregation decode
      limits:    { memory: 128Gi, cpu: "32" }
      requests:  { memory: 128Gi, cpu: "32" }
    extraEnvVars:                    # copy from pd-disaggregation
    extraContainerConfig:            # copy from pd-disaggregation (securityContext + capabilities)
    additionalVolumeMounts: []
    additionalVolumes: []

  inferenceExtension:
    pluginsConfigFile: "epd-<role>-config.yaml"
    pluginsCustomConfig:
      epd-<role>-config.yaml: |
        apiVersion: inference.networking.x-k8s.io/v1alpha1
        kind: EndpointPickerConfig
        plugins:
        - type: prefix-cache-scorer
        - type: queue-scorer
        - type: kv-cache-utilization-scorer
        - type: max-score-picker
        schedulingProfiles:
        - name: default
          plugins:
          - pluginRef: prefix-cache-scorer
            weight: 3
          - pluginRef: queue-scorer
            weight: 2
          - pluginRef: kv-cache-utilization-scorer
            weight: 2
          - pluginRef: max-score-picker
```

**Why the role-suffix in `model.name`:** the renderer computes `model_id_label = model_id_label_filter(model.name, namespace.name)` (verified by [step_09_deploy_modelservice.py:362-367](llmdbenchmark/standup/steps/step_09_deploy_modelservice.py#L362)). Distinct `model.name` values → distinct labels → distinct Helm releases (`<label>-ms`, `<label>-gaie`), distinct InferencePool selectors (`llm-d.ai/model: <label>` per [12_gaie-values.yaml.j2:127-130](config/templates/jinja/12_gaie-values.yaml.j2#L127)), distinct HTTPRoutes (`{model_id_label}` is the route name in [08_httproute.yaml.j2:72](config/templates/jinja/08_httproute.yaml.j2#L72)).

The `model.path` and `model.huggingfaceId` stay identical across stacks so the model is downloaded **once** to the shared PVC — saves disk space and download time.

**Trade-off:** clients calling the API will need to use `"model": "Qwen/Qwen3-32B-encode"` (etc.) in their request body, since vLLM's `--served-model-name` is set from `model.name`. If undesirable, the alternative is using 3 actually-different small models — but that requires more GPU/disk for a POC.

## Files reused as-is (no changes)

All Jinja templates in [`config/templates/jinja/`](config/templates/jinja/) — the 29 templates already render correctly per stack:

- [`13_ms-values.yaml.j2`](config/templates/jinja/13_ms-values.yaml.j2) — renders one ms-values.yaml per stack with that stack's `decode` block (prefill block omitted because `prefill_create=false` when `prefill.replicas=0`)
- [`12_gaie-values.yaml.j2`](config/templates/jinja/12_gaie-values.yaml.j2) — renders one gaie-values.yaml per stack with that stack's `pluginsCustomConfig`
- [`10_helmfile-main.yaml.j2`](config/templates/jinja/10_helmfile-main.yaml.j2) — declares `{model_id_label}-ms` and `{model_id_label}-gaie` releases with shared `infra-llmdbench` (only first stack installs the gateway)
- [`08_httproute.yaml.j2`](config/templates/jinja/08_httproute.yaml.j2) — per-stack mode (default) renders one HTTPRoute per stack at path `/<model_id_label>/`

All Python orchestrator code (`llmdbenchmark/standup/steps/`) — no edits needed. `step_09` is `per_stack=True` and runs once per stack with namespace-scoped waits.

## Verification

### Phase 1: Render-time validation (no cluster needed)

```bash
llmdbenchmark --spec guides/epd-pools-disaggregation standup --namespace <my-ns> --dry-run
```

Inspect the workspace at `~/data/epd-pools-disaggregation/<user>-<timestamp>/`:

- **3 stack subdirs** under `plan/`: `epd-encode/`, `epd-prefill/`, `epd-decode/` — each with full set of 29 rendered templates
- **3 distinct `model_id_label`s** — verify by `grep -r "model_id_label" plan/` shows three distinct hashed labels
- **3 helmfiles** with `{label}-ms` and `{label}-gaie` releases — verify with `grep "name:" plan/*/10_helmfile-main.yaml`
- **3 HTTPRoute YAMLs** rendered with `kind: HTTPRoute` — verify with `grep -l 'kind: HTTPRoute' plan/*/08_httproute.yaml`
- **3 distinct EndpointPickerConfigs** in each stack's `12_gaie-values.yaml`
- The dry-run log should show `oc wait --for=condition=Ready pod -l inferencepool=<label>-gaie-epp` for each of the three labels

### Phase 2: Smoke test on cluster

```bash
llmdbenchmark --spec guides/epd-pools-disaggregation standup --namespace <my-ns>
```

Expected on-cluster state:

```bash
oc get inferencepool -n <my-ns>
# 3 InferencePools, names like:
#   qwen-qwe-<hash1>-encode-gaie
#   qwen-qwe-<hash2>-prefill-gaie
#   qwen-qwe-<hash3>-decode-gaie

oc get httproute -n <my-ns>
# 3 HTTPRoutes (route names = model_id_labels)

oc get pods -n <my-ns> -l llm-d.ai/role=decode
# 3 vLLM pods (one per stack, all labeled role=decode by chart)

oc get deployment -n <my-ns> | grep -E "epp|gaie"
# 3 EPP deployments (one per InferencePool), each with its own EndpointPickerConfig ConfigMap

oc get cm -n <my-ns> | grep gaie-epp
# 3 EPP ConfigMaps, each containing the EndpointPickerConfig
```

The auto-chained smoketests should pass per stack (3× `health_check`, 3× `inference_test`, 3× `validate_config`).

### Phase 3: Manual end-to-end inference probe

For each role:

```bash
ROUTE=$(oc get route -n <my-ns> llmdbench-inference-gateway-route -o jsonpath='{.spec.host}')

curl -X POST "http://${ROUTE}/<encode-model_id_label>/v1/completions" \
  -H 'Content-Type: application/json' \
  -d '{"model": "Qwen/Qwen3-32B-encode", "prompt": "Hello", "max_tokens": 5}'

# Repeat for -prefill and -decode
```

Each call must return a valid OpenAI-compatible response from the corresponding pool, proving the EPP routes correctly.

## Cluster prerequisites

- **3 GPUs available** (one per stack, `tensor=1, dataLocal=1`). If only 1–2 free, drop replicas/parallelism or use a smaller `Qwen3-0.6B` model.
- HuggingFace token in env (`HF_TOKEN`) — same as pd-disaggregation
- Existing fixes from current session (helm-diff plugin upgrade, `gpuMemoryUtilization: 0.95`) carry over because we copy verbatim from pd-disaggregation

## Out of scope (explicitly not doing)

- Editing the `llm-d-modelservice` Helm chart to add a real `encode` role — that's an upstream change
- Adding chained encode→prefill→decode routing in EPP plugins — there is no `epd-decider` plugin today; the task asks for 3 independent pools, not chained routing
- Patching `step_09_deploy_modelservice.py` to support prefill-only stacks — chose `decode` block to avoid this code change
- Per-EPP plugin specialization (encode-flavored vs decode-flavored weights) — chose identical simple config across all three EPPs
