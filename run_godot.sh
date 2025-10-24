#!/bin/bash

# Quick start script for Godot project
# Usage: ./run_godot.sh

if command -v godot4 &> /dev/null; then
    godot4 project.godot
elif command -v godot &> /dev/null; then
    godot project.godot
elif flatpak list | grep -q "org.godotengine.Godot"; then
    flatpak run org.godotengine.Godot project.godot
else
    echo "Godot not found. Please install Godot 4.x"
    echo "Visit: https://godotengine.org/download"
    echo "Or install via flatpak: flatpak install flathub org.godotengine.Godot"
    exit 1
fi
