# ⚡ Secure Messaging System // One-Time Pad Cryptosystem

An information-theoretically secure, client-side cryptosystem implementing the **One-Time Pad (Vernam Cipher)** with browser hardware-backed CSPRNG.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Security](https://img.shields.io/badge/security-information--theoretic-success.svg)
![Platform](https://img.shields.io/badge/platform-browser--only-fuchsia.svg)

---

## 🔒 Overview

The **Secure Messaging System** provides unbreakable, mathematically proven secrecy based on Claude Shannon's 1949 theorem of Perfect Secrecy. 

All operations (key generation, bitwise XOR encryption, and decryption) execute **100% locally in volatile browser memory** using the W3C Web Cryptography API (`crypto.getRandomValues`). Zero data is sent to external servers or logged to persistent storage.

---

## ✨ Features

- **🔑 Hardware-Backed CSPRNG Generator:** Generates truly random cryptographic pads using operating system entropy pools.
- **⚡ Reactive Buffer Matching:** Live validation badges immediately notify the operator if a key is too short or ready for XOR processing.
- **🔄 Multi-Format Encoding:** Seamless support for Hexadecimal (0-9, a-f), Base64, and Raw UTF-8 binary streams.
- **💾 Key Management:** One-click clipboard copy and `.key` file generation.
- **🛡️ Binary Fallback Recovery:** Decryption engine safely decodes non-UTF8 binary data using byte escape notation without throwing runtime errors.
- **🎨 Cyberpunk UI:** Responsive, dark-mode terminal aesthetic styled with Tailwind CSS and interactive canvas particle animations.

---

## 🚀 Quick Start

### Option 1: Direct File
Simply double-click [`index.html`](index.html) to open the application in any modern web browser.

### Option 2: Local HTTP Server
Run a local static server using Python:
```powershell
# In the project directory:
py -m http.server 8000
```
Then visit:
- **Local:** [http://localhost:8000](http://localhost:8000)
- **Network Devices:** `http://<your-lan-ip>:8000`

---

## 📐 How It Works (Vernam XOR Cipher)

1. **Key Generation:** A random pad $K$ is generated with length $|K| \ge |M|$.
2. **Encryption:** Plaintext bytes $M$ are XOR-combined bitwise with $K$:
   $$C = M \oplus K$$
3. **Decryption:** Ciphertext bytes $C$ are XOR-combined bitwise with the same $K$:
   $$M = C \oplus K$$

### The 4 Rules for Perfect Secrecy
1. **True Randomness:** Key bytes must be uniformly distributed across $\{0, \dots, 255\}$.
2. **Length Parity:** Key must be at least as long as the plaintext message.
3. **Strict Single-Use:** Never reuse a pad (reusing produces the two-time pad vulnerability: $C_1 \oplus C_2 = M_1 \oplus M_2$).
4. **Out-of-Band Exchange:** Share the key through a separate secure physical/authenticated channel.

---

## 📖 Technical Documentation

For an in-depth breakdown of the architecture, Shannon's entropy proofs, threat modeling, and known-answer test vectors (KAT), refer to:
👉 [**TECHNICAL_DOCUMENTATION.md**](TECHNICAL_DOCUMENTATION.md)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
