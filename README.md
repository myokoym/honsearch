# Honsearch - 書誌情報検索

The book searcher from bibliographic informations in [openBD](https://openbd.jp/) by [Groonga](http://groonga.org/ja/).

## Usage

### Prepare

    $ git clone https://github.com/myokoym/honsearch
    $ bundle install

### Load data

    $ bundle exec ruby -I lib bin/honsearch load

### Run web server

    $ bundle exec ruby -I lib bin/honsearch start

## License

* Ruby Code (.rb): LGPL 2.1 or later. See LICENSE.txt for details.
* Data from openBD: See [https://openbd.jp/](https://openbd.jp/).
