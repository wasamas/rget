# rget

Downloading newest radio programs on the web. Supported radio stations are hibiki, animate, onsen, seaside communications and niconico.

If you want to save files as MP3, needs `ffmpeg` command.

For customize radio programs, copy `rget.yaml` to `~/.rget` or current work directory and edit it.

## Installation

    $ gem install rget

## Usage

    rget imas_cg            # download and convert to mp3 THE iDOLM@STER Cinderella Girls Radio
    rget imastudio --no-mp3 # download imastudio only (saved .m4a file)
    rget trysail --path=/home/hoge/radio
                            # srore mp3 file to specified directory
    rget suzakinishi --path=dropbpx://radio
	                         # store mp3 file to radio folder of Dropbox
