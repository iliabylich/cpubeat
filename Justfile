project := "cpubeat.xcodeproj"
app := "build/Release/cpubeat.app"
icon_source := "icon_512x512.png"
iconset := "Assets.xcassets/AppIcon.appiconset"

default: run

gen:
    xcodegen generate --use-cache

icon:
    @just _icon 16 16x16
    @just _icon 32 16x16@2x
    @just _icon 32 32x32
    @just _icon 64 32x32@2x
    @just _icon 128 128x128
    @just _icon 256 128x128@2x
    @just _icon 256 256x256
    @just _icon 512 256x256@2x
    @just _icon 512 512x512

_icon pixels name:
    sips -z {{pixels}} {{pixels}} {{icon_source}} --out {{iconset}}/icon_{{name}}.png >/dev/null

build: gen
    @just _build

release-dmg version: clean gen
    @just _build MARKETING_VERSION={{version}}
    mkdir -p build/dmg-root
    cp -R {{app}} build/dmg-root/
    ln -s /Applications build/dmg-root/Applications
    hdiutil create \
        -volname cpubeat \
        -srcfolder build/dmg-root \
        -ov \
        -format UDZO \
        cpubeat_{{version}}_arm64.dmg

_build *settings:
    xcodebuild \
        -project {{project}} \
        -target cpubeat \
        -configuration Release \
        -quiet \
        {{settings}} \
        build

run: build stop
    open {{app}}

dev: build stop
    {{app}}/Contents/MacOS/cpubeat

dummy: build stop
    CPUBEAT_SAMPLER=dummy {{app}}/Contents/MacOS/cpubeat

empty: build stop
    CPUBEAT_SAMPLER=empty {{app}}/Contents/MacOS/cpubeat

stop:
    -pkill -x cpubeat

open: gen
    open {{project}}

clean:
    rm -rf build {{project}}

format:
    swift-format format --recursive --in-place src

burn threads="8" seconds="0":
    mkdir -p build
    cc -O2 -Wall -o build/burn tools/burn.c
    build/burn {{threads}} {{seconds}}
