#yifydown

## Synopsis

This bash script downloads YIFY movies using YTS.ag Web API.

## Usage

```bash
yifydown.sh [options] [search query]
```

There aren't problems in writing the movie name (or string to search) with spaces.

The script will show a movie, and ask for confirmation, which can be <code>y</code> (yes, continues with that movie), <code>n</code> (no, shows the next movie), <code>s</code> (summary, prints the movie's summary and asks again), or <code>q</code> (quit, stops the script). This can be skipped with the <code>-f</code> option, which selects the first result in chronological order.

Then, the scripts shows the movie qualities available to download (eg. <code>(720p/1080p/3D)</code>), and it can be answer with one of those (eg <code>720p</code>), or <code>quit</code> the script. However, if the option <code>-q [quality]</code> is passed, the script will try to download such quality, and if it isn't available, will show the available ones.

Finally, the script uses aria2 to download the movie through torrent, to the current directory. Everything inside the command line.

## Installation

First, you'll need to get the **dependencies**, which are <code>jshon</code> and <code>aria2</code>.

macOS:
```bash
brew install jshon aria2
```

Download that yifydown.sh script in the repo, and run it in your bash console (well, just open it with Terminal)

## API Reference

Obviously, yts.ag/api. Just remember that not every YIFY movie is indexed at yts.ag... yet.

## Tests

```bash
$ yifydown Full Metal Jacket
1 movie found.
Is this the correct movie? (y/yes)(n/no)(s/summary)(q/quit)
Full Metal Jacket (1987)
$ y
Available qualities:
(720p)(quit)
$ 720p
File size: 750.66 MB
Now downloading...
```

```bash
$ yifydown -fq 720p angry
12 Angry Men (1957)
File size: 700.07 MB
Now downloading...
```

## Contributors

If you want to help cleaning that rubbish of script (that, at least, works as intended), or add a new functionality, you're welcome here ;)

## License

GNU General Public License v3. If you take this to make something better (well, this is too poor to be useful for someone else), would you tell me about it? I would like it more than this. Thank you!
