from pathlib import Path
import os

root = Path("android")
if not root.exists():
    raise SystemExit("Android host project is missing")

props = root / "key.properties"
keystore = root / "app" / "nexo-release.jks"
if not os.environ.get("NEXO_KEYSTORE_BASE64"):
    print("No NEXO release keystore secrets configured; using CI debug signing for test builds.")
    raise SystemExit(0)

import base64
keystore.write_bytes(base64.b64decode(os.environ["NEXO_KEYSTORE_BASE64"]))
props.write_text(
    "storePassword=" + os.environ.get("NEXO_STORE_PASSWORD", "") + "\n" +
    "keyPassword=" + os.environ.get("NEXO_KEY_PASSWORD", "") + "\n" +
    "keyAlias=" + os.environ.get("NEXO_KEY_ALIAS", "") + "\n" +
    "storeFile=nexo-release.jks\n"
)

p = root / "app" / "build.gradle"
if p.exists():
    s = p.read_text()
    if "keystorePropertiesFile" not in s:
        prefix = '''def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) { keystoreProperties.load(new FileInputStream(keystorePropertiesFile)) }
'''
        s = prefix + s
    if "signingConfigs {" not in s:
        s = s.replace("android {", '''android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }''', 1)
    s = s.replace(
        "signingConfig signingConfigs.debug",
        "signingConfig (keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug)"
    )
    p.write_text(s)
    raise SystemExit(0)

p = root / "app" / "build.gradle.kts"
if p.exists():
    s = p.read_text()
    if "keystorePropertiesFile" not in s:
        prefix = '''import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
        s = prefix + s
    if 'create("release")' not in s:
        s = s.replace("    buildTypes {", '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {''', 1)
    s = s.replace(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")'
    )
    p.write_text(s)
    raise SystemExit(0)

raise SystemExit("No Android Gradle build file found")
