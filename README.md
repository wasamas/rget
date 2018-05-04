# rget

Downloading newest radio programs on the web. Supported radio stations are:

* hibiki
* onsen
* niconico
* freshlive.tv
* himalaya.fm

If you want to save files as MP3, needs `ffmpeg` command.

For customize radio programs, copy `rget.yaml` to `~/.rget` or current work directory and edit it. config file search paths are:

* RGET\_CONFIG environment variable
* ./rget.yaml
* ~/.rget
* <command path>/../rget.yaml (for gem)

## Installation

  $ gem install rget

## Usage
### rget command

  # save a template of the radio program configration
  rget yaml http://example.com/radio >> ~/.rget

  # download and convert to mp3 THE iDOLM@STER Cinderella Girls Radio
  rget imas_cg

  # download takamori only (saved movie file)
  rget takamori --no-mp3

  # srore mp3 file to specified directory
  rget suzakinishi --path=/home/hoge/radio

  # store mp3 file to radio folder of Dropbox
  rget matsui --path=dropbpx://radio

### nicodl command

  # download nicovideo live program
  nicodl http://live.nicovideo.jp/watch/lv999999999

### add\_mp3info

  # set cover photo into mp3 file
  add_mp3info sample.mp3 cover.jpg
