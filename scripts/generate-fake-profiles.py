#!/usr/bin/env python3
"""Generate fake provisioning profiles for the WinterGram dev bundle id."""

import datetime
import json
import os
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.serialization import pkcs12, pkcs7

REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = REPO_ROOT / "build-system/wintergram-development-configuration.json"
SOURCE_PROFILES_DIR = REPO_ROOT / "build-system/fake-codesigning/profiles"
SOURCE_CERTS_DIR = REPO_ROOT / "build-system/fake-codesigning/certs"
SELF_SIGNED_P12 = SOURCE_CERTS_DIR / "SelfSigned.p12"

# mapping from application-identifier suffix -> output file name (without .mobileprovision)
PROFILE_NAME_MAPPING = {
    ".SiriIntents": "Intents",
    ".NotificationContent": "NotificationContent",
    ".NotificationService": "NotificationService",
    ".Share": "Share",
    "": "Telegram",
    ".watchkitapp": "WatchApp",
    ".watchkitapp.watchkitextension": "WatchExtension",
    ".Widget": "Widget",
    ".BroadcastUpload": "BroadcastUpload",
}


def load_self_signed_cert_and_key():
    with open(SELF_SIGNED_P12, "rb") as f:
        key, cert, _ = pkcs12.load_key_and_certificates(f.read(), password=b"")
    if key is None or cert is None:
        raise RuntimeError("Could not load key/cert from SelfSigned.p12")
    return key, cert


def extract_plist(profile_path: Path) -> dict:
    result = subprocess.run(
        ["openssl", "smime", "-inform", "der", "-verify", "-noverify", "-in", str(profile_path)],
        capture_output=True,
        check=True,
    )
    return plistlib.loads(result.stdout)


def replace_in_string(s: str, old_team: str, new_team: str, old_bundle: str, new_bundle: str) -> str:
    s = s.replace(old_team + "." + old_bundle, new_team + "." + new_bundle)
    s = s.replace(old_bundle, new_bundle)
    s = s.replace(old_team, new_team)
    return s


def replace_in_value(value, old_team: str, new_team: str, old_bundle: str, new_bundle: str):
    if isinstance(value, str):
        return replace_in_string(value, old_team, new_team, old_bundle, new_bundle)
    if isinstance(value, list):
        return [replace_in_value(v, old_team, new_team, old_bundle, new_bundle) for v in value]
    if isinstance(value, dict):
        return {k: replace_in_value(v, old_team, new_team, old_bundle, new_bundle) for k, v in value.items()}
    if isinstance(value, bytes):
        try:
            text = value.decode("utf-8")
            replaced = replace_in_string(text, old_team, new_team, old_bundle, new_bundle)
            return replaced.encode("utf-8")
        except UnicodeDecodeError:
            return value
    return value


def profile_suffix_for(plist_data: dict) -> str:
    app_id = plist_data["Entitlements"]["application-identifier"]
    # We expect <old_team>.<old_bundle><suffix>
    return app_id.split(".", 2)[2] if "." in app_id else ""


def generate_profile(source_path: Path, new_team: str, new_bundle: str, key, cert) -> tuple[str, bytes]:
    plist_data = extract_plist(source_path)

    old_team = plist_data["TeamIdentifier"][0]
    old_bundle = plist_data["Entitlements"]["application-identifier"][len(old_team) + 1 :]
    # strip known suffixes to find the base bundle id
    old_bundle_base = old_bundle
    for suffix in sorted(PROFILE_NAME_MAPPING.keys(), key=len, reverse=True):
        if suffix and old_bundle.endswith(suffix):
            old_bundle_base = old_bundle[: -len(suffix)]
            break

    new_bundle_base = new_bundle

    plist_data = replace_in_value(plist_data, old_team, new_team, old_bundle_base, new_bundle_base)

    # Some fields can't be string-replaced blindly; set them explicitly.
    plist_data["ApplicationIdentifierPrefix"] = [new_team]
    plist_data["TeamIdentifier"] = [new_team]
    plist_data["UUID"] = str(uuid.uuid4()).upper()
    plist_data["Name"] = f"WinterGram {source_path.stem}"
    plist_data["TeamName"] = "WinterGram Self-Signed"
    plist_data["IsXcodeManaged"] = False

    now = datetime.datetime.now(datetime.timezone.utc)
    plist_data["CreationDate"] = now
    plist_data["ExpirationDate"] = now + datetime.timedelta(days=365)

    # Replace embedded developer certificate with the self-signed one.
    cert_der = cert.public_bytes(serialization.Encoding.DER)
    plist_data["DeveloperCertificates"] = [cert_der]

    # Strip capabilities we don't want/need for a sideload dev build.
    entitlements = plist_data.get("Entitlements", {})
    entitlements["get-task-allow"] = True
    entitlements.pop("beta-reports-active", None)
    entitlements["aps-environment"] = "development"
    plist_data["Entitlements"] = entitlements

    # Determine output name from the original suffix.
    original_suffix = ""
    for suffix in sorted(PROFILE_NAME_MAPPING.keys(), key=len, reverse=True):
        if suffix and old_bundle.endswith(suffix):
            original_suffix = suffix
            break
    output_name = PROFILE_NAME_MAPPING.get(original_suffix, source_path.stem) + ".mobileprovision"

    # Re-sign as CMS SignedData (DER) using the self-signed certificate.
    plist_bytes = plistlib.dumps(plist_data)
    builder = pkcs7.PKCS7SignatureBuilder(
        data=plist_bytes,
        signers=[(cert, key, hashes.SHA256(), None)],
        additional_certs=[cert],
    )
    signed = builder.sign(serialization.Encoding.DER, [pkcs7.PKCS7Options.Binary])

    return output_name, signed


def main():
    if len(sys.argv) > 1:
        output_dir = Path(sys.argv[1])
    else:
        output_dir = REPO_ROOT / "build-system/fake-codesigning-generated"

    output_profiles_dir = output_dir / "profiles"
    output_certs_dir = output_dir / "certs"
    output_profiles_dir.mkdir(parents=True, exist_ok=True)
    output_certs_dir.mkdir(parents=True, exist_ok=True)

    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        config = json.load(f)

    new_team = config["team_id"]
    new_bundle = config["bundle_id"]

    print(f"Generating fake profiles for team={new_team} bundle={new_bundle} ...")

    key, cert = load_self_signed_cert_and_key()

    # Copy the self-signed cert material so the output dir is self-contained.
    for src in SOURCE_CERTS_DIR.iterdir():
        if src.is_file():
            (output_certs_dir / src.name).write_bytes(src.read_bytes())

    generated = []
    for source_path in sorted(SOURCE_PROFILES_DIR.glob("*.mobileprovision")):
        output_name, signed = generate_profile(source_path, new_team, new_bundle, key, cert)
        out_path = output_profiles_dir / output_name
        out_path.write_bytes(signed)
        generated.append(output_name)
        print(f"  {source_path.name} -> {output_name}")

    print(f"Wrote {len(generated)} profiles to {output_profiles_dir}")


if __name__ == "__main__":
    main()
