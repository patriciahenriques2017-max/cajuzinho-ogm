#!/bin/bash
# Monta o APK do Professor Léo a partir da pasta ../professor-leo.
# Uso: ./build.sh FONTES_DIR KEYSTORE SAIDA.apk
#   FONTES_DIR: pasta com baloo-2-latin-600-normal.woff2 e baloo-2-latin-800-normal.woff2 (pacote npm @fontsource/baloo-2)
# Requer: aapt, dalvik-exchange, zipalign, apksigner, libandroid-23-java, JDK, python3 com Pillow.
set -euo pipefail
AQUI="$(cd "$(dirname "$0")" && pwd)"; WEB="$AQUI/../professor-leo"
FONTES="$1"; CHAVE="$2"; SAIDA="$3"
JAR=/usr/lib/android-sdk/platforms/android-23/android.jar
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/assets/lib" "$T/assets/fontes" "$T/classes" "$T/res"

# conteúdo do app
cp -r "$WEB"/v1 "$WEB"/v2 "$WEB"/v3 "$WEB"/v4 "$T/assets/"
cp "$WEB"/lib/*.js "$T/assets/lib/"; cp "$WEB/modelo.js" "$T/assets/"
cp "$FONTES"/baloo-2-latin-600-normal.woff2 "$FONTES"/baloo-2-latin-800-normal.woff2 "$T/assets/fontes/"
python3 - "$WEB/index.html" "$T/assets/index.html" <<'PY'
import re,sys
h=open(sys.argv[1],encoding='utf-8').read()
fonte='''<style>
@font-face{font-family:"Baloo 2";font-weight:600;font-display:swap;src:url(fontes/baloo-2-latin-600-normal.woff2) format("woff2")}
@font-face{font-family:"Baloo 2";font-weight:800;font-display:swap;src:url(fontes/baloo-2-latin-800-normal.woff2) format("woff2")}
</style>'''
h,n1=re.subn(r'<link href="https://fonts\.googleapis\.com[^>]*>',fonte,h)
h,n2=re.subn(r"\nif\('serviceWorker' in navigator\)[^\n]*",'',h)
h=re.sub(r'<link rel="(manifest|icon|apple-touch-icon)"[^>]*>\n','',h)
assert n1==1 and n2==1,(n1,n2)
open(sys.argv[2],'w',encoding='utf-8').write(h)
PY

# ícones
cp -r "$AQUI/res/values" "$T/res/"
python3 - "$WEB/icons/icone-512.png" "$T/res" <<'PY'
import sys,os
from PIL import Image
im=Image.open(sys.argv[1]).convert('RGBA')
for d,px in dict(mdpi=48,hdpi=72,xhdpi=96,xxhdpi=144,xxxhdpi=192).items():
    p=f'{sys.argv[2]}/mipmap-{d}'; os.makedirs(p,exist_ok=True)
    im.resize((px,px),Image.LANCZOS).save(f'{p}/ic_launcher.png')
PY

# código
javac -nowarn --release 8 -cp "$JAR" -d "$T/classes" "$AQUI"/src/br/app/professorleo/*.java 2>&1 | grep -v "^warning\|^Note\|warnings$" || true
dalvik-exchange --dex --output="$T/classes.dex" "$T/classes"

# pacote
aapt package -f -0 mp3 -0 woff2 -M "$AQUI/AndroidManifest.xml" -S "$T/res" -A "$T/assets" -I "$JAR" -F "$T/a.apk"
(cd "$T" && aapt add a.apk classes.dex >/dev/null)
zipalign -f 4 "$T/a.apk" "$T/b.apk"
apksigner sign --ks "$CHAVE" --ks-pass pass:professorleo --out "$SAIDA" "$T/b.apk"
apksigner verify --verbose "$SAIDA" | head -4
