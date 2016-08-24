#psforest

ps (procps) の ps uaxf と同様の出力を実現するためのスクリプトです。

ps (procps) ではオプション -f (--forest) を指定することによって、
プロセスの情報と一緒に、プロセスの親子関係をツリーで表示することができます。
しかし、Cygwin や Mac OS X、AIX などの ps には同様の機能はありません。
このスクリプトは ps の出力を加工することによってツリーを表示します。

##インストール
既定で `$HOME/.mwg/` 以下にインストールします。
```
$ cd psforest
$ make install
```

インストール先を指定するには `make install` 時に変数 `PREFIX` を指定します。
```
$ make install PREFIX=/opt/psforest
```

##使用例
```
$ alias p=$HOME/.mwg/bin/psforest
$ p
```
