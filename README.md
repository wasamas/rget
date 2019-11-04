# rget

Downloading newest radio programs on the web. Supported radio stations are:

* hibiki
* onsen
* niconico
* freshlive.tv
* himalaya.fm
* Asobi Store

If you want to save files as MP3, needs `ffmpeg` command.
To download niconico video, also needs latest `youtube-dl` command (you can get it from `https://yt-dl.org/`), then specify niconico user ID and password to `~/.netrc` as:

```
machine niconico
  login [your login]
  password [your password]
```

For customize radio programs, copy `rget.yaml` to `~/.rget` or current work directory and edit it. config file search paths are:

* `RGET_CONFIG` environment variable
* `./rget.yaml`
* `~/.rget`
* `<command path>/../rget.yaml` (for gem)

## Installation
```
  $ gem install rget
```

## Usage
### rget command
download a recent radio program to .MP3/.MP4 file.

```
# save a template of the radio program configration
rget yaml http://example.com/radio >> ~/.rget

# download and convert to mp3 THE iDOLM@STER Cinderella Girls Radio
rget imas_cg

# download takamori only (saving movie file as .MP4)
rget takamori --no-mp3

# srore mp3 file to specified directory
rget suzakinishi --path=/home/hoge/radio

# store mp3 file to radio folder of Dropbox
rget matsui --path=dropbpx://radio
```

### add\_mp3info command
set cover photo into mp3 file and set file name as the title
```
add_mp3info sample.mp3 cover.jpg
```
