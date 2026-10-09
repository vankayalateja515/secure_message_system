# Secure Messaging System // One-Time Pad Cryptosystem
## Technical Specification & System Architecture Document

| Document Metadata | Value |
| :--- | :--- |
| **System Name** | Secure Messaging System (One-Time Pad Cryptosystem) |
| **Project Repository** | `Team-6` |
| **Classification** | Cryptographic System Specification & Implementation Guide |
| **Version** | 1.0.0 |
| **Security Paradigm** | Information-Theoretically Secure Symmetric Stream Cipher |
| **Execution Environment** | Client-Side / Zero-Telemetry Web Application |
| **Date** | October 2026 |

---

## 1. Executive Summary & Purpose

The **Secure Messaging System** is a zero-knowledge, zero-telemetry web cryptosystem implementing the **One-Time Pad (OTP)** cipher. It provides end-to-end information-theoretic security directly in the user's browser, eliminating reliance on computational hardness assumptions (such as RSA, ECC, or lattice-based cryptography).

All key generation, encryption, and decryption routines execute exclusively in volatile client memory (`RAM`) using browser hardware-backed Cryptographically Secure Pseudorandom Number Generators (**CSPRNG** via the W3C Web Cryptography API). No plaintext, ciphertext, or keying material is transmitted across the network, logged, or written to disk unless explicitly downloaded by the operator.

---

## 2. Theoretical Cryptographic Foundations

### 2.1 The One-Time Pad (Vernam Cipher)
Invented conceptually by Frank Miller (1882) and patented by Gilbert Vernam (1917), the One-Time Pad is a symmetric cipher where plaintext is paired bitwise or bytewise with a random key pad of equal or greater length.

Given:
* Plaintext byte array: $M = (m_0, m_1, \dots, m_{n-1}) \in \{0, \dots, 255\}^n$
* Secret key byte array: $K = (k_0, k_1, \dots, k_{n-1}) \in \{0, \dots, 255\}^n$
* Ciphertext byte array: $C = (c_0, c_1, \dots, c_{n-1}) \in \{0, \dots, 255\}^n$

#### Encryption Transformation:
$$c_i = m_i \oplus k_i \quad (\text{for } 0 \le i < n)$$

#### Decryption Transformation:
$$m_i = c_i \oplus k_i = (m_i \oplus k_i) \oplus k_i = m_i \oplus (k_i \oplus k_i) = m_i \oplus 0 = m_i$$

Where $\oplus$ represents the bitwise exclusive-OR (XOR) operation.

### 2.2 Shannon's Theorem of Perfect Secrecy
In 1949, Claude Shannon proved in *"Communication Theory of Secrecy Systems"* that the One-Time Pad provides **unconditional / perfect secrecy** if and only if four fundamental axioms are strictly met:

$$\mathbb{P}(M = m \mid C = c) = \mathbb{P}(M = m) \quad \forall m, c$$

Or equivalently in information entropy terms:
$$H(M \mid C) = H(M)$$

### 2.3 Cardinal Rules for Perfect Secrecy
1. **True Uniform Randomness:** The key pad bytes must be uniformly distributed across $\{0, \dots, 255\}$. Any bias or predictability collapses the entropy budget.
2. **Key Length Parity:** $|K| \ge |M|$. The key length must be at least as long as the plaintext message in raw bytes.
3. **Strict Single-Use (No Reuse):** A pad must never be reused. If $K$ is used to encrypt two messages $M_1$ and $M_2$:
   $$C_1 \oplus C_2 = (M_1 \oplus K) \oplus (M_2 \oplus K) = M_1 \oplus M_2$$
   This eliminates the key and leaves a relative frequency XOR combination vulnerable to statistical crib-dragging and natural language frequency analysis.
4. **Secure Pre-Shared Distribution:** The key must be distributed across an authenticated, physically secure, or trusted out-of-band channel.

---

## 3. High-Level Architecture & Workflow

```
+-----------------------------------------------------------------------------------------+
|                                    CLIENT BROWSER                                       |
|                                                                                         |
|  [Hardware Entropy Engine] ---> window.crypto.getRandomValues()                         |
|                                         |                                               |
|                                         v                                               |
|                             +-----------------------+                                   |
|                             | Key Generator Module  |                                   |
|                             | - Hex / Base64 / Raw  |                                   |
|                             +-----------------------+                                   |
|                                         |                                               |
|              +--------------------------+-------------------------+                     |
|              | (In-Memory Key Transfer)                           |                     |
|              v                                                    v                     |
|  +-----------------------+                            +-----------------------+         |
|  |   Encryption Tool     |                            |   Decryption Tool     |         |
|  | - TextEncoder (UTF-8) |                            | - Hex/B64 Parser      |         |
|  | - XOR Engine          |                            | - XOR Engine          |         |
|  | - Output Formatter    |                            | - TextDecoder (UTF-8) |         |
|  +-----------------------+                            +-----------------------+         |
|              |                                                    ^                     |
|              +-------------- [Ciphertext Relay] ------------------+                     |
+-----------------------------------------------------------------------------------------+
```

### Architectural Principles:
* **Zero Backend Dependency:** Pure client-side single page execution. All computational routines run in the local V8/SpiderMonkey JavaScript runtime.
* **Transient Memory Footprint:** State is stored in isolated JavaScript variables and DOM elements, never persisted in `localStorage` or `sessionStorage` to mitigate forensic disk recovery.
* **Modern Reactive UI:** Real-time character/byte metrics and key-length validation badges update dynamically on each keystroke or buffer modification.

---

## 4. Subsystem Specifications

### 4.1 CSPRNG Pad Generator Subsystem
* **Source of Entropy:** `window.crypto.getRandomValues(new Uint8Array(length))`
* **Supported Buffer Scales:**
  * `Bytes`: $1 \text{ B}$ to $1,048,576 \text{ B}$ ($1 \text{ MB}$)
  * `KB`: Multiplied by $1024$
  * `MB`: Multiplied by $1024 \times 1024$ (Upper safety boundary: $10 \text{ MB}$)
* **Serialization Encodings:**
  * **Hexadecimal:** $\forall b \in \text{bytes}, \quad b \mapsto \text{padLeft}(\text{hex}(b), 2)$
  * **Base64:** Binary string translation via `btoa(String.fromCharCode(...))`
  * **Raw Binary:** Direct byte string mapped via ASCII / Unicode character codes
* **Portability:**
  * One-click clipboard copy (`navigator.clipboard.writeText`)
  * Local file export (`Blob([keyVal], { type: 'text/plain' })` $\rightarrow$ `onetime_pad_<timestamp>.key`)

### 4.2 Data Normalization & Parsing Engine (`parseKeyToBytes`)
The cryptographic core accepts arbitrary key encodings and sanitizes them into deterministic typed byte arrays (`Uint8Array`):
1. **Hex Parsing Branch:**
   * Removes all whitespace (`/\s+/g`).
   * Validates regex `/^[0-9a-fA-F]+$/` and checks for even length.
   * Parses pairs of nibbles using `parseInt(chunk, 16)`.
2. **Base64 Parsing Branch:**
   * Validates base64 grammar `/^[0-9a-zA-Z+/]+={0,2}$/` and modulus 4 length.
   * Decodes via `atob()` into binary character bytes.
3. **UTF-8 Fallback Branch:**
   * Raw strings are serialized into byte arrays via `new TextEncoder().encode(keyStr)`.

### 4.3 Encryption Engine
* **Input Stage:** Plaintext message transformed to byte buffer via UTF-8 standard encoding:
  $$\text{plainBytes} = \text{TextEncoder.encode}(M)$$
* **Validation Guard:** Checks whether $|\text{keyBytes}| \ge |\text{plainBytes}|$. If the key buffer is smaller than the plaintext buffer, encryption is blocked and a warning indicator triggers.
* **Auto-Pad Assistance:** Provides an instantaneous fallback generator that produces a strictly matching random pad of length $\max(|\text{plainBytes}|, 32)$.
* **Cipher Execution:**
  ```javascript
  const cipherBytes = new Uint8Array(plainBytes.length);
  for (let i = 0; i < plainBytes.length; i++) {
      cipherBytes[i] = plainBytes[i] ^ keyBytes[i];
  }
  ```
* **Output Formats:** Hex string or Base64 encoded ciphertext.

### 4.4 Decryption Engine
* **Input Stage:** Ingests Hex or Base64 ciphertext representation.
* **Decoding Stage:** Decodes ciphertext back to raw `Uint8Array`.
* **Validation Stage:** Verifies that $|\text{keyBytes}| \ge |\text{cipherBytes}|$.
* **Reversal Transformation:**
  ```javascript
  const plainBytes = new Uint8Array(cipherBytes.length);
  for (let i = 0; i < cipherBytes.length; i++) {
      plainBytes[i] = cipherBytes[i] ^ keyBytes[i];
  }
  ```
* **UTF-8 Stream Reconstruction & Fallback:**
  * Primary: `new TextDecoder('utf-8', { fatal: true }).decode(plainBytes)`
  * Robust Binary Fallback: If decrypted bytes violate UTF-8 framing rules, non-printable bytes are rendered as hex escape sequences (`\xNN`) while printable ASCII characters remain legible.

---

## 5. Security & Threat Model

| Threat / Attack Vector | Risk Level | Mitigation & Implementation Defense |
| :--- | :--- | :--- |
| **Two-Time Pad (Crib Dragging)** | Critical | Educational badges and validation alerts warn the operator. Keys are designed to be generated per-session and discarded. |
| **Insufficient Entropy** | Critical | Rejection of non-cryptographic PRNGs (`Math.random()`). Exclusively utilizes OS-level kernel entropy pools via `crypto.getRandomValues()`. |
| **Network Interception (Eavesdropping)** | None | Zero telemetry. No network API calls, webhooks, or analytics endpoints exist in the system. |
| **Client-Side Storage Scraping** | Low | Pads and messages exist solely in volatile DOM memory. No usage of persistent browser stores (`localStorage`, `IndexedDB`, or cookies). |
| **Cross-Site Scripting (XSS)** | Medium | System utilizes static vanilla JS without external untrusted dependencies; recommended hosting under strict Content Security Policy (`CSP`). |
| **UTF-8 Malformed Byte Crashes** | Low | Implemented strict `fatal: true` try-catch blocks with binary escape fallback formatting to prevent DOM exceptions. |

---

## 6. Mathematical Verification & Test Vectors

### Test Vector 1: Standard ASCII XOR Verification
* **Plaintext ($M$):** `"HELLO"`
* **Hex ($M$):** `48 45 4C 4C 4F`
* **Key Pad ($K$):** `A3 F1 02 C8 91`
* **Ciphertext ($C = M \oplus K$):**
  * Byte 0: `0x48 ^ 0xA3 = 0xEB`
  * Byte 1: `0x45 ^ 0xF1 = 0xB4`
  * Byte 2: `0x4C ^ 0x02 = 0x4E`
  * Byte 3: `0x4C ^ 0xC8 = 0x84`
  * Byte 4: `0x4F ^ 0x91 = 0xDE`
  * **Resulting Cipher Hex:** `ebb44e84de`
* **Decryption ($C \oplus K$):**
  * `0xEB ^ 0xA3 = 0x48` (`'H'`)
  * `0xB4 ^ 0xF1 = 0x45` (`'E'`)
  * `0x4E ^ 0x02 = 0x4C` (`'L'`)
  * `0x84 ^ 0xC8 = 0x4C` (`'L'`)
  * `0xDE ^ 0x91 = 0x4F` (`'O'`)
  * **Recovered Output:** `"HELLO"`

---

## 7. Hosting & Deployment Guidelines

### 7.1 Local Development Server
The application can be served through any static HTTP server. When hosted with Python 3:
```powershell
# Navigate to project directory
cd E:\Team-6

# Launch HTTP server on designated port
py -m http.server 8000
```

#### Access Endpoints:
* **Loopback:** `http://localhost:8000` / `http://127.0.0.1:8000`
* **Local Area Network (LAN):** `http://<Host-IP>:8000` (e.g., `http://192.168.6.215:8000`)

### 7.2 Production Hosting Requirements
* **Secure Context (HTTPS):** Modern web browsers enforce **Secure Contexts** (`HTTPS` or `localhost`) for full access to the Web Cryptography API (`window.crypto`).
* **Recommended Content Security Policy (CSP):**
  ```http
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com;
  ```

---

## 8. File Structure & Component Mapping

| File | Purpose / Role |
| :--- | :--- |
| [`index.html`](file:///e:/Team-6/index.html) | Main production single-page application with dark cyberpunk UI, interactive particle canvas background, tab controller, CSPRNG pad generator, and XOR encryption/decryption tools. |
| [`517.html`](file:///e:/Team-6/517.html) | Alternative glassmorphism styled release of the cryptosystem. |
| [`one_time_pad_cryptosystemorg.html`](file:///e:/Team-6/one_time_pad_cryptosystemorg.html) | Original cryptographic suite baseline implementation. |
| [`TECHNICAL_DOCUMENTATION.md`](file:///e:/Team-6/TECHNICAL_DOCUMENTATION.md) | Comprehensive system architecture, cryptographic specifications, and engineering documentation. |

---

## 9. Operational Best Practices Checklist

1. [ ] **Never Reuse Keys:** Generate a fresh one-time pad for every message transmitted.
2. [ ] **Match or Exceed Message Length:** Ensure the key byte count matches or exceeds the UTF-8 encoded byte length of the plaintext.
3. [ ] **Destroy Used Pads:** Immediately delete or shred pad files after encryption and decryption cycles.
4. [ ] **Out-of-Band Key Exchange:** Transmit pad keys via a secure secondary medium (e.g., physical hardware token, encrypted air-gapped drive) separate from the ciphertext transmission channel.
