## static website generator

a simple static website generator written with a bash script and pandoc.
it requires [pandoc](https://pandoc.org/installing.html) and [imagemagick](https://imagemagick.org/script/download.php).

### configs

create the `routes.conf` and `configs.conf` files in the `/bin` directory.

```sh
touch ./bin/routes.conf && touch ./bin/configs.conf
```

##### routes.conf

```
about=single
blog=multiple
portfolio=multiple
```

set the menu type to either **single** or **multiple**.

##### configs.conf

```
TITLE="Website title"
BASE_URL="https://whatever.com"
MD_DIRECTORY="Local directory where markdown files are located."

BUILD_DIRECTORY="./build"
ASSETS_DIRECTORY="../build/assets"
TEMPLATES_DIRECTORY="./templates"
ROUTES_CONF="./routes.conf"
ASSET_EXTENSIONS="jpg|jpeg|png|gif|mp4|webm|ogg|mp3"
```

### posting

```
---
title: lorem ipsum
menu: blog
---

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Nulla maximus bibendum augue vel efficitur.
...
```

make sure to specify `title` and `menu` (check [routes.conf](#routesconf)).
if the post file is still a draft, put `draft: true` or `draft: draft` below the `menu`. the program will skip converting the file.

when you are ready to publish, simply delete the draft line and move the file to `MD_DIRECTORY`. the markdown filename will be changed automatically based on the `title` (e.g., `filename.md` -> `lorem-ipsum.md`).

to edit the main home page ("/"), create an `index.md` file in the `MD_DIRECTORY`, and make sure to set `title` and `menu` to **index**.

```
---
title: index
menu: index
---
...
```

run

```bash
bash ./bin/build_macos.sh
```

or

```bash
bash ./bin/build_linux.sh
```

based on your os. (only tested on **ubuntu** and **macos**)
