# rget

Downloading newest radio programs on the web. Supported radio stations are:

* hibiki
* animate
* onsen
* niconico
* freshlive.tv

If you want to save files as MP3, needs `ffmpeg` command.

For customize radio programs, copy `rget.yaml` to `~/.rget` or current work directory and edit it. config file search paths are:

* RGET\_CONFIG environment variable
* ./rget.yaml
* ~/.rget
* <command path>/../rget.yaml (for gem)

## Installation

    $ gem install rget

## Usage

	 # download and convert to mp3 THE iDOLM@STER Cinderella Girls Radio
    rget imas_cg

	 # download imastudio only (saved .m4a file)
    rget imastudio --no-mp3

    # srore mp3 file to specified directory
    rget trysail --path=/home/hoge/radio

	 # store mp3 file to radio folder of Dropbox
    rget suzakinishi --path=dropbpx://radio

	 # show a template of the radio program configration
    rget yaml http://example.com/radio

    # download nicovideo live program by nicodl command
	 nicodl http://live.nicovideo.jp/watch/lv999999999
