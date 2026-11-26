package opapolicychecker_test

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/beckn-one/beckn-onix/pkg/model"
	checker "github.com/beckn-one/beckn-onix/pkg/plugin/implementation/opapolicychecker"
)

const integrationNetworkID = "ion.id"

func TestIONRelease2Integration(t *testing.T) {
	root := os.Getenv("ION_SPECS_ROOT")
	if root == "" {
		t.Fatal("ION_SPECS_ROOT is required")
	}

	bundlePath := filepath.Join(root, "releases/release2/rules/bundles/ion-release2-policy.tar.gz")
	publicKeyPath := filepath.Join(root, "releases/release2/rules/bundles/ion-release2-policy-public.pem")
	bundle := readFile(t, bundlePath)

	t.Run("accepts valid fixtures", func(t *testing.T) {
		enforcer := newEnforcer(t, bundlePath, publicKeyPath, "data.ion.release2.result")
		defer enforcer.Close()
		assertAllowed(t, enforcer, readFixture(t, root, "common/payment-paid-valid.json"))
		assertAllowed(t, enforcer, readFixture(t, root, "trade/provider-valid.json"))
	})

	t.Run("returns structured rule diagnostics", func(t *testing.T) {
		enforcer := newEnforcer(t, bundlePath, publicKeyPath, "data.ion.release2.result")
		defer enforcer.Close()
		assertRejected(t, enforcer, readFixture(t, root, "common/payment-paid-missing-paid-at.json"), "POL_ELIGIBILITY_NOT_MET", "ION-R2-COM-0001")
		assertRejected(t, enforcer, readFixture(t, root, "trade/provider-temporarily-closed-missing-until.json"), "POL_ELIGIBILITY_NOT_MET", "ION-R2-TRD-0001")
		assertRejected(t, enforcer, readFixture(t, root, "trade/provider-central-missing-entity.json"), "POL_ELIGIBILITY_NOT_MET", "ION-R2-TRD-0002")
	})

	t.Run("allows unrelated actions", func(t *testing.T) {
		enforcer := newEnforcer(t, bundlePath, publicKeyPath, "data.ion.release2.result")
		defer enforcer.Close()
		body := readFixture(t, root, "common/payment-paid-missing-paid-at.json")
		body = updateContext(t, body, "action", "search")
		assertAllowed(t, enforcer, body)
	})

	t.Run("selects exact network and skips no-match", func(t *testing.T) {
		enforcer := newEnforcer(t, bundlePath, publicKeyPath, "data.ion.release2.result")
		defer enforcer.Close()
		body := readFixture(t, root, "common/payment-paid-missing-paid-at.json")
		body = updateContext(t, body, "networkId", "unconfigured.example/network")
		assertAllowed(t, enforcer, body)
	})

	t.Run("reports multiple violations", func(t *testing.T) {
		enforcer := newEnforcer(t, bundlePath, publicKeyPath, "data.ion.release2.result")
		defer enforcer.Close()
		body := readFixture(t, root, "trade/provider-temporarily-closed-missing-until.json")
		var document map[string]any
		mustJSON(t, body, &document)
		catalogs := document["message"].(map[string]any)["catalogs"].([]any)
		attributes := catalogs[0].(map[string]any)["provider"].(map[string]any)["providerAttributes"].(map[string]any)
		attributes["invoicing"] = map[string]any{"model": "CENTRAL"}
		body = marshalJSON(t, document)
		assertRejected(t, enforcer, body, "POL_ELIGIBILITY_NOT_MET", "ION-R2-TRD-0001", "ION-R2-TRD-0002")
	})

	t.Run("fails closed for wrong query", func(t *testing.T) {
		enforcer := newEnforcer(t, bundlePath, publicKeyPath, "data.ion.release2.missing")
		defer enforcer.Close()
		assertRejected(t, enforcer, readFixture(t, root, "common/payment-paid-valid.json"), "POL_GENERIC_ERROR", "returned no result (undefined)")
	})

	t.Run("rejects wrong verification key at startup", func(t *testing.T) {
		wrongKeyPath := filepath.Join(t.TempDir(), "wrong-public-key.pem")
		writeFile(t, wrongKeyPath, generatePublicKey(t))
		assertStartupRejected(t, bundlePath, wrongKeyPath, "invalid ECDSA signature")
	})

	t.Run("rejects tampered bundle at startup", func(t *testing.T) {
		tampered := append([]byte(nil), bundle...)
		tampered[len(tampered)/2] ^= 0xff
		tamperedPath := filepath.Join(t.TempDir(), "tampered-bundle.tar.gz")
		writeFile(t, tamperedPath, tampered)
		assertStartupRejected(t, tamperedPath, publicKeyPath, "failed to read bundle")
	})
}

func newEnforcer(t *testing.T, bundlePath, publicKeyPath, query string) *checker.PolicyEnforcer {
	t.Helper()
	configPath := writePolicyConfig(t, bundlePath, publicKeyPath, query)
	enforcer, err := checker.New(context.Background(), map[string]string{"networkPolicyConfig": configPath})
	if err != nil {
		t.Fatalf("initialize ONIX policy checker: %v", err)
	}
	return enforcer
}

func writePolicyConfig(t *testing.T, bundlePath, publicKeyPath, query string) string {
	t.Helper()
	content := fmt.Sprintf(`networkPolicies:
  %s:
    type: bundle
    location: %s
    query: %s
    verification:
      enabled: true
      publicKeyLookupUrl: %s
      algorithm: ES256
`, integrationNetworkID, bundlePath, query, publicKeyPath)
	path := filepath.Join(t.TempDir(), "network-policies.yaml")
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatalf("write network policy config: %v", err)
	}
	return path
}

func assertStartupRejected(t *testing.T, bundlePath, publicKeyPath, message string) {
	t.Helper()
	_, err := checker.New(context.Background(), map[string]string{"networkPolicyConfig": writePolicyConfig(t, bundlePath, publicKeyPath, "data.ion.release2.result")})
	if err == nil || !strings.Contains(err.Error(), message) {
		t.Fatalf("expected startup error containing %q, got %v", message, err)
	}
	t.Logf("observed expected startup rejection: %v", err)
}

func assertAllowed(t *testing.T, enforcer *checker.PolicyEnforcer, body []byte) {
	t.Helper()
	if err := enforcer.CheckPolicy(stepContext(body)); err != nil {
		t.Fatalf("expected policy allow, got %v", err)
	}
}

func assertRejected(t *testing.T, enforcer *checker.PolicyEnforcer, body []byte, code string, messages ...string) {
	t.Helper()
	err := enforcer.CheckPolicy(stepContext(body))
	var coded *model.CodedErr
	if !errors.As(err, &coded) {
		t.Fatalf("expected ONIX coded rejection, got %T: %v", err, err)
	}
	if coded.HTTPStatus() != http.StatusBadRequest {
		t.Fatalf("expected HTTP 400, got %d", coded.HTTPStatus())
	}
	becknError := coded.BecknError()
	if becknError.Code != code {
		t.Fatalf("expected code %q, got %q", code, becknError.Code)
	}
	for _, message := range messages {
		if !strings.Contains(becknError.Message, message) {
			t.Fatalf("expected diagnostic to contain %q, got %q", message, becknError.Message)
		}
	}
}

func stepContext(body []byte) *model.StepContext {
	request, _ := http.NewRequest(http.MethodPost, "/bpp/receiver/test", nil)
	return &model.StepContext{Context: context.Background(), Request: request, Body: body}
}

func readFixture(t *testing.T, root, relative string) []byte {
	t.Helper()
	return readFile(t, filepath.Join(root, "releases/release2/rules/tests/fixtures", relative))
}

func readFile(t *testing.T, path string) []byte {
	t.Helper()
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	return content
}

func writeFile(t *testing.T, path string, content []byte) {
	t.Helper()
	if err := os.WriteFile(path, content, 0o600); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

func updateContext(t *testing.T, body []byte, key string, value any) []byte {
	t.Helper()
	var document map[string]any
	mustJSON(t, body, &document)
	document["context"].(map[string]any)[key] = value
	return marshalJSON(t, document)
}

func mustJSON(t *testing.T, body []byte, target any) {
	t.Helper()
	if err := json.Unmarshal(body, target); err != nil {
		t.Fatalf("decode fixture: %v", err)
	}
}

func marshalJSON(t *testing.T, value any) []byte {
	t.Helper()
	body, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("encode fixture: %v", err)
	}
	return body
}

func generatePublicKey(t *testing.T) []byte {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate wrong verification key: %v", err)
	}
	der, err := x509.MarshalPKIXPublicKey(&key.PublicKey)
	if err != nil {
		t.Fatalf("marshal wrong verification key: %v", err)
	}
	return pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: der})
}
