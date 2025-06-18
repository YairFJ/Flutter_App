#!/bin/bash

echo "🔍 Verificando existencia de Pods-Runner.xcconfig..."

CONFIG_PATH="ios/Pods/Target Support Files/Pods-Runner/Pods-Runner.xcconfig"

if [ -f "$CONFIG_PATH" ]; then
    echo "✅ Archivo encontrado: $CONFIG_PATH"
    echo "Podés asignarlo en Xcode en la sección 'Base Configuration'."
else
    echo "❌ No se encontró el archivo:"
    echo "$CONFIG_PATH"
    echo ""
    echo "🔁 Ejecutá los siguientes comandos para regenerarlo:"
    echo ""
    echo "flutter clean"
    echo "cd ios"
    echo "rm -rf Pods Podfile.lock"
    echo "pod install"
    echo "cd .."
    echo "flutter pub get"
    echo ""
    echo "🧩 Luego abrí el proyecto con:"
    echo "open ios/Runner.xcworkspace"
fi

