# Static website generator

Simple static website generator written with bash script, pandoc.
it requires [pandoc](https://pandoc.org/installing.html) and [imagemagick](https://imagemagick.org/script/download.php).

## configs

`touch ./bin/routes.conf && touch ./bin/configs.conf`

##### routes.conf

```
about=single
blog=multiple
portfolio=multiple
```

##### configs.conf

```
MD_DIRECTORY=""
BUILD_DIRECTORY=""
TEMPLATES_DIRECTORY="./templates"
ASSETS_DIRECTORY="../build/assets"
ROUTES_CONF="./routes.conf"

BASE_URL="HTTPS://WHATEVER.COM"
TITLE="WEBSITE TITLE"

# rss feed template
RSS_TEMPLATE="<?xml version='1.0' encoding='UTF-8' ?>
                    <rss xmlns:atom='http://www.w3.org/2005/Atom' version='2.0'>
                        <channel>
                            <title>$TITLE</title>
                            <link>$BASE_URL</link>
                            <description>hi</description>
                            {{ITEMS}}
                        </channel>
                    </rss>"

ITEM_TEMPLATE='<item> \
                    <title>{{TITLE}}</title> \
                    <link>{{LINK}}</link> \
                    <description>{{DESCRIPTION}}</description>\
                    <pubDate>{{DATE}}</pubDate> \
                    <category>{{CATEGORY}}</category> \
                    <guid isPermaLink="false">{{GUID}}</guid> \
                    <atom:link href="{{ATOM_LINK}}" rel="self" type="application/rss+xml" /> \
                </item>'
```

`bash build_macos.sh` or `bash_linux.sh` based on your os.
