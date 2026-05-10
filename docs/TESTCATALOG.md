# Testkatalog — Was gibt es für Tests?

## 1. Unit Tests (Isolation)
**Was:** Einzelne Funktion/Component, isoliert. Mock für alles andere.
**Tool:** pytest, vitest, jest, JUnit
**Beispiel:** "Prüft add(a,b) korrekt addiert"

## 2. Integration Tests (Zusammenspiel)
**Was:** Mehrere Komponenten zusammen, echte DB/API.
**Tool:** pytest + testcontainers, supertest, Playwright
**Beispiel:** "API → DB → Response roundtrip"

## 3. End-to-End Tests (User Flow)
**Was:** Kompletter User-Workflow, Browser-basiert.
**Tool:** Playwright, Cypress, Selenium, gstack-browse
**Beispiel:** "Login → Form ausfüllen → abschicken → Erfolg prüfen"

## 4. Smoke Tests (Sanity Check)
**Was:** Nach Deploy: startet die App? Lädt die Startseite? Keine 500er?
**Tool:** curl, gstack-browse, health-check endpoints
**Beispiel:** `curl -f https://app.com/health`

## 5. Regression Tests (Nothing Broke)
**Was:** Alte Bugs kommen nicht zurück. Jeder Bugfix = neuer Test.
**Tool:** Gleiche Tools wie Unit/Integration
**Beispiel:** "Fix für Null-Pointer → Test dass null nicht crasht"

## 6. Security Tests (Safety)

| Untertyp | Tool | Prüft |
|----------|------|-------|
| **SAST** (Static) | semgrep, bandit, shellcheck | Code-Patterns ohne Ausführung |
| **DAST** (Dynamic) | OWASP ZAP, Burp Suite | Laufende App auf XSS/SQLi |
| **Secret Scanning** | gitleaks, truffleHog, git-secrets | API-keys, tokens im Code/History |
| **Dependency Audit** | npm audit, pip-audit, Snyk | CVE in dependencies |
| **Prompt Injection** | grep + regex patterns | Agent-Dateien auf Jailbreak |
| **Gate Testing** | Custom (stam-os) | Blockiert gates.json Angriffe? |

## 7. Performance Tests

| Untertyp | Tool | Fragestellung |
|----------|------|---------------|
| **Benchmark** | autocannon, k6, wrk | "1000 req/s → P95 Latency?" |
| **Load Test** | k6, locust, Artillery | "Wie viele User gleichzeitig?" |
| **Stress Test** | k6, Chaos Mesh | "Wo bricht es? Recovery?" |
| **Bundle Size** | webpack-bundle-analyzer | "Wie groß ist der JS-Bundle?" |
| **Lighthouse** | lighthouse, gstack-benchmark | Core Web Vitals |

## 8. Robustness Tests (Edge Cases)

| Untertyp | Tool | Fragestellung |
|----------|------|---------------|
| **Fuzzing** | AFL, libFuzzer, jsfuzz | Zufalls-Input → Crash? |
| **Property-based** | Hypothesis (Py), fast-check (JS) | "Für ALLE Inputs gilt: f(g(x)) = x" |
| **Chaos Engineering** | Chaos Mesh, Gremlin | Kill random Pod → App survived? |
| **Boundary Testing** | Manuell + parametrized tests | Min/Max/Null/Empty/Unicode |
| **Race Conditions** | tsan, thread-sanitizer | Parallel-Zugriff → Data race? |

## 9. Mutation Tests (Test die Tests)
**Was:** Mutiert Code (ändert `>` zu `<`, `+` zu `-`). Prüft ob Tests den Fehler finden.
**Tool:** mutmut (Py), Stryker (JS)
**Beispiel:** "Ich ändere `if x > 0` zu `if x < 0`. Fällt ein Test durch? Nein = Testlücke."

## 10. Compatibility Tests
**Was:** Funktioniert es auf allen Ziel-Plattformen?
**Tool:** BrowserStack, Sauce Labs, Docker multi-arch
**Beispiel:** macOS + Linux + Windows, Chrome + Firefox + Safari

## 11. Accessibility Tests (a11y)
**Was:** WCAG 2.1 AA konform?
**Tool:** axe-core, pa11y, Lighthouse a11y, screen-reader
**Beispiel:** "Alle Buttons haben aria-label, Kontrast ≥ 4.5:1"

## 12. Code Quality (Static)

| Tool | Prüft |
|------|-------|
| **Linter** (eslint, ruff, shellcheck) | Stil, potentielle Bugs |
| **Type Checker** (mypy, tsc) | Typ-Korrektheit |
| **Formatter** (prettier, black) | Einheitlicher Stil |
| **Complexity** (radon, codeclimate) | Zyklomatische Komplexität |
| **Dead Code** (vulture, ts-prune) | Ungenutzte Funktionen/Variablen |

---

## Was braucht stam-os?

| Testtyp | Priorität | Tool |
|---------|-----------|------|
| ShellCheck | 🔴 P0 | shellcheck (alle .sh) |
| Gate Testing | 🔴 P0 | pytest mit regex-Matching |
| Secret Scanning | 🔴 P0 | gitleaks (pre-commit hook) |
| Prompt Injection | 🟡 P1 | grep auf agents/*.md |
| Hook Testing | 🟡 P1 | pytest — Hooks laufen in Docker |
| Setup Smoke Test | 🟡 P1 | Docker: frisches macOS-Image → setup.sh → prüfen |
| Fuzzing gates.json | 🟢 P2 | Fuzz-Test gegen Regex-Patterns |
| Mutation Testing | 🟢 P2 | Stryker auf gate-logic |

## Was braucht ein Workflow-Projekt (n8n + Agent)?

| Testtyp | Priorität | Tool |
|---------|-----------|------|
| Integration (LLM-Call) | 🔴 P0 | pytest mit Mock-Anthropic-API |
| Output Validation | 🔴 P0 | Schema-Check der Agent-Outputs |
| Prompt Injection | 🔴 P0 | gates.json Muster + Agent-Prompts |
| Multi-LLM Benchmark | 🔴 P0 | Gleicher Input → 3 APIs → Diff |
| Gate Testing | 🟡 P1 | gates.json gegen n8n-Output |
| Rate Limiting | 🟢 P2 | k6: 10 parallele API-Calls |
