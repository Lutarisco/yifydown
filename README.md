#yifydown

## Synopsis

This bash script downloads YIFY movies using YTS.ag Web API.

## Code Example

```bash
yifydown.sh [movie name]
```

There aren't problems in writing the movie name with spaces; the script takes everything to the right as the movie name.

After launching the script, it will show a movie, and ask if it is the one that you want. You can answer <code>y</code> (yes, continues with that movie), <code>n</code> (no, stops the script), or <code>s</code> (summary, prints the movie's summary and asks again).

Then, the scripts shows the movie qualities available to download (eg. <code>(720p/1080p/3D)</code>) and you can answer with one of those (eg <code>720p</code>).

Finally, the scripts uses aria2 to download the movie through torrent, to the current directory. Everything inside the command line.

## Motivation

Erhh... Freedom sense? Copyright makes Internet illegal?

## Installation

First, you'll need to get the **dependencies**, which are <code>jshon</code> and <code>aria2</code>.

macOS:
```bash
brew install jshon aria2
```

Download that yifydown.sh script in the repo, and run it in your bash console (well, just open it with Terminal):

```bash
path/to/yifydown.sh
```

## API Reference

Obviously, yts.ag/api. Just remember that not every YIFY movie is indexed at yts.ag... yet.

## Tests

```bash
$ yifydown Full Metal Jacket
1 movie found.
Is this movie correct? (y/yes)(n/no)(s/summary)
Full Metal Jacket (1987)
$ y
Available qualities:
(720p/1080p/3D)
$ 720p
Now downloading...
```

## Contributors

If you want to help cleaning that rubbish of script that, at least, works as intended, or add a new functionality, you're welcome here ;)

## License

GNU General Public License v3. If you take this to make something better (well, this is too poor to be useful for someone else), would you tell me about it? I would like it more than this.
