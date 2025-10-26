<h3 align="center">
    <a href="https://tcgpocket.pokemon.com/en-us/" target="_blank">
        <img src="./images/header.png"/>
    </a>
</h3>

<br>
<br>

### phone

<br>

* [Galaxy A16 5G](https://www.telcel.com/tienda/producto/telefonos-y-smartphones/galaxy-a16-gris-128gb/71001512)

<br>

```bash
screen_size: 1080x2340
```

<br>
<br>

### references

<br>

* limitless tcg deck builder

```bash
https://my.limitlesstcg.com/builder
```

* scrape all card data

```bash
# GET
https://api.dotgg.gg/cgfw/getcards?game=pokepocket&mode=indexed&cache={cache_idx}
```

* scrape all card image data

```bash
https://ptcgpocket.gg/cards/
```

* static URL for card images

```bash
https://static.dotgg.gg/pokepocket/card/{card_number}.webp
```

* name of app

```bash
jp.pokemon.pokemontcgp
```

<br>
<br>

### openai models

<br>

```bash
# (if share, increased free token limits)
# ** - supports image upload
o3-2025-04-16** -> (10 per 1M)
o4-mini-2025-04-16 -> (1.1 per 1M)
gpt-4.1-nano-2025-04-14** -> (0.1 per 1M)
gpt-4.1-mini-2025-04-14** -> (0.4 per 1M)
gpt-4o** -> (10 per 1M)
gpt-4o-mini** -> (0.60 per 1M))
o3-mini -> (4.40 per 1M)
```

<br>
<br>

### scrcpy

<br>

* [install scrcpy](https://github.com/Genymobile/scrcpy/blob/master/doc/linux.md)

```bash
./scrcpy --start-app=jp.pokemon.pokemontcgp
```

```bash
-Sw # stay-awake + turn-screen-off = prevent device from sleeping

--show-touches         # show touches
```

<br>
<br>

### adb

<br>

```bash
adb shell pidof -s jp.pokemon.pokemontcgp # get pid
adb logcat --pid=<pid> # get logcat for pid

adb shell getevent -lt > touches.log # get touch events

adb shell ls # list files in device
adb shell rm # remove files in device

# screenshots
adb exec-out screencap -p > screen.png
adb shell screencap /sdcard/test.png
adb pull /sdcard/test.png test.png

adb shell wm size # get current resolution
adb shell input tap <X> <Y>           # tap
adb shell input swipe <X1> <Y1> <X2> <Y2> <duration> # swipe
adb shell input text 'Charmander' # type text

adb shell settings get system show_touches # get show_touches values
```

<br>
<br>

### configuration

<br>

* runtime settings are loaded from `config/bluestacks.json` by default.
* set `POKEBOT_CONFIG=/path/to/your-config.json` to load a different profile.
* copy `config/bluestacks.sample.json` and adjust it for your environment (ADB path, screen size, UI overrides, etc.).
* `ui_overrides` let you provide per-button coordinates when BlueStacks is using a custom layout. The bot automatically scales the stock coordinates for other resolutions.

<br>
<br>

### bluestacks emulator

<br>

1. enable **Android Debug Bridge (ADB)** inside BlueStacks advanced settings.
2. confirm you can connect from your host machine with `adb connect 127.0.0.1:5555`.
3. update `config/bluestacks.json` with the ADB binary path you are using (for Windows the bundled `HD-Adb.exe`, for macOS/Linux the Android platform tools).
4. set the `device.serial` field to `127.0.0.1:5555` (or your chosen port) so every tap and screenshot targets the emulator instance.
5. tweak the `screen` resolution section to match the portrait resolution configured inside BlueStacks. If you play in landscape, add explicit `ui_overrides` for the main battle controls to keep the PvP flow reliable.
6. optionally provide `scrcpy_path` and set `start_scrcpy` to `true` if you still want the mirrored window on a physical Android device.

These steps make the automation loop stable for queuing PvP matches through BlueStacks without manual rewiring each time the emulator is launched.

<br>
<br>
