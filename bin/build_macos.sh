#!/usr/bin/env bash

source "./configs.conf"

start_time=$(date +%s)

rm -rf "$BUILD_DIRECTORY"

mkdir "$BUILD_DIRECTORY"
mkdir "${BUILD_DIRECTORY}/assets"
cp -r "./styles" "${BUILD_DIRECTORY}"

echo "------------------------------------------------------------------"

function generateMenusList() {
    local -a menus_list=()

    while IFS='=' read -r route_menu route_type || [[ -n "$route_menu" ]]; do
        route_menu="${route_menu// /}"
        route_type="${route_type// /}"
        route_url="/build/${route_menu}/" 

        if [[ ! "${menus_list[@]}" =~ "${route_menu}" ]]; then
            menus_list+=("$route_menu=$route_type")
        fi
    done < "$ROUTES_CONF"

    echo "${menus_list[@]}"
}

function generateHeaderMenu() {
    header_menu="<h2><a href='/' style='text-decoration: none; color: black'>$TITLE</a></h2>"
    header_menu+="<nav><ul>"
    while IFS='=,' read -r route_menu route_type || [[ -n "$route_menu" ]]; do
        route_menu="${route_menu// /}"
        route_type="${route_type// /}"
        route_url="${route_menu}/" 
        menu_name=$(basename "$route_menu")
        header_menu+="<li><a href=\"/${route_url}\">${menu_name}</a></li>"
    done < "$ROUTES_CONF"
    # rss menu
    header_menu+="<li><a href=\"/rss.xml\">feed</a></li>"
    header_menu+="</ul>"
    header_menu+="</nav>"
    header_menu+="<hr>"
    echo "$header_menu"
}

function handleAssets () {
    asset_files=$(sed -nE 's|.*<(img\|video\|audio)[^>]+src="([^"]+).*|\2|p' "$1")
    echo "    • $1"
    
    for asset_file in $asset_files; do        
        echo "      •  ${asset_file}"
        if [[ "$asset_file" != http* ]]; then
            cp "$asset_file" "$ASSETS_DIRECTORY"
            local filename=$(basename $asset_file)
            copied_file="$ASSETS_DIRECTORY/$filename"
            echo "        $copied_file"

            shopt -s nocasematch

            if [[ "$asset_file" =~ \.(jpg|jpeg|png|gif)$ ]]; then
                convert $asset_file -trim -resize 20%  $copied_file
            fi

            sed -i "" "s|$asset_file|../assets/$filename|g" "$1"
        fi
    done
}

function initialDirectories() {
    while IFS='=' read -r route_menu route_type || [[ -n "$route_menu" ]]; do
        local route_menu="${route_menu// /}" 
        local route_type="${route_type// /}" 
        local route_url="/build/${route_menu}/" 
        local represent_md_file="${BUILD_DIRECTORY}/${route_menu}/${route_menu}.md"
        local output_html="${BUILD_DIRECTORY}/${route_menu}/index.html"
        local template_html="${TEMPLATES_DIRECTORY}/${route_type}.html"

        mkdir "${BUILD_DIRECTORY}/${route_menu}"
        
        # represent files every menu folders
        if [[ ! -f $represent_md_file ]]; then
            echo "---" > "${represent_md_file}"
            echo "title: ${route_menu}" >> "${represent_md_file}"
            echo "menu: ${route_menu}" >> "${represent_md_file}"
            echo "---" >> "${represent_md_file}"

            if [[ -f $represent_md_file ]]; then
                pandoc "$represent_md_file" --template="${template_html}" --css="./styles.css" --output="$output_html"
                local modification_date=$(stat -f "%Sm" -t "%s" "$output_html")
                local modified=$(date -r "${modification_date}" "+%Y-%m-%d %H:%M:%S")
                find "${BUILD_DIRECTORY}" -name "*.html" -exec sed -i '' -e "s/\whatmenu/$(printf '%s\n' "$(echo $route_menu)" | sed -e 's/[\/&]/\\&/g')/g" {} \;
                find "${BUILD_DIRECTORY}" -name "*.html" -exec sed -i '' -e "s/\modificationdate/$(printf '%s\n' "Last modified ${modified}" | sed -e 's/[\/&]/\\&/g')/g" {} \;
            fi
        fi
        
    done < "$ROUTES_CONF"

    # home
    home_html="$BUILD_DIRECTORY/index.html"
    cp -p "$TEMPLATES_DIRECTORY/index.html" "$BUILD_DIRECTORY"
    local modification_date=$(stat -f "%Sm" -t "%s" "$home_html")
    local modified=$(date -r "${modification_date}" "+%Y-%m-%d %H:%M:%S")
    find "${BUILD_DIRECTORY}" -name "*.html" -exec sed -i '' -e "s/\whatmenu/$(printf '%s\n' "$(echo $TITLE)" | sed -e 's/[\/&]/\\&/g')/g" {} \;
    find "${home_html}" -exec sed -i '' -e "s/\modificationdate/$(printf '%s\n' "Last modified ${modified}" | sed -e 's/[\/&]/\\&/g')/g" {} \;
    handleAssets $home_html
}

function getSummary() {
    local slug=$1
    local md_file=$(find $BUILD_DIRECTORY -type f -name "$slug.md")
    summary=$(sed -n '/---/,/---/!p' "$md_file" | tr -d '\n' | cut -c 1-80 | sed 's/$/.../')
    echo "$summary"
}

function getThumbnail() {
    local slug=$1
    local title=$(echo $slug | tr "-" " ")
    local html_file=$(find $BUILD_DIRECTORY -type f -name "$slug.html")
    local asset_files=$(sed -n -r '/<img/s/.*src="([^"]*)".*/\1/p' $html_file)
    local filename=$(basename "${asset_files[0]}")
    echo $filename
}

function getMenuType() {
    local menu=$1
    local menu_type=$(grep -E "^$menu=" "$ROUTES_CONF" | cut -d= -f2)
    echo $menu_type
}


function generateHTMLPages() {
    header_menu=$(generateHeaderMenu)

    IFS=$(echo -en "\n\b")
    md_files=( $(find "${MD_DIRECTORY}" -maxdepth 1 -type f -name "*.md") )
    unset IFS

    for file in "${md_files[@]}"; do
        local menu=$(sed -n 's/^menu: //p' <<< "$(cat "${file}")")
        local title=$(sed -n 's/^title: //p' <<< "$(cat "${file}")")
        local slug=$(echo "$title" | tr " " "-")
        local creation_date=$(stat -f "%SB" -t "%s" "$file")
        local modification_date=$(stat -f "%Sm" -t "%s" "$file")
        local filename=$(basename "$file")
        local name="${filename%.*}"
        unsorted_posts+=("$slug $menu $creation_date $modification_date")

        MENU_DIRECTORY="${BUILD_DIRECTORY}/${menu}"

        mv "$file" "${MD_DIRECTORY}/$slug.md"

        local md_file="${MD_DIRECTORY}/$slug.md"

        cp -p "${md_file}" "${MENU_DIRECTORY}"

        if [ -d "$MENU_DIRECTORY" ]; then
            echo " "
            echo -e "\x1b[1m  • '$slug.md -->> $slug.html'\x1b[m"

            if [[ "${slug}" == "${menu}" ]]; then
                local menu_type=$(grep -E "^$menu=" "$ROUTES_CONF" | cut -d= -f2)
                local output_html="${MENU_DIRECTORY}/index.html"
                pandoc "$md_file" --template="${TEMPLATES_DIRECTORY}/${menu_type}.html" --css="./styles.css" --output="$output_html"
                handleAssets "$output_html"
            else 
                local output_html="${MENU_DIRECTORY}/${slug}.html"
                pandoc "$md_file" --template="${TEMPLATES_DIRECTORY}/post.html" --css="./styles.css" --output="$output_html"
                handleAssets "$output_html"
            fi

            local created=$(date -r "${creation_date}" "+%Y-%m-%d %H:%M:%S")
            local modified=$(date -r "${modification_date}" "+%Y-%m-%d %H:%M:%S")

            find "${BUILD_DIRECTORY}" -name "*.html" -exec sed -i '' -e "s/\whatmenu/$(printf '%s\n' "$(echo "$menu")" | sed -e 's/[\/&]/\\&/g')/g" {} \;
            find "${BUILD_DIRECTORY}" -name "*.html" -exec sed -i '' -e "s/\creationdate/$(printf '%s\n' "$(echo "$created" | tr "/" " ")" | sed -e 's/[\/&]/\\&/g')/g" {} \;
            find "${BUILD_DIRECTORY}" -name "*.html" -exec sed -i '' -e "s/\modificationdate/$(printf '%s\n' "Last modified ${modified}" | sed -e 's/[\/&]/\\&/g')/g" {} \;
            find "${BUILD_DIRECTORY}" -name "*.html" -exec sed -i '' -e "s/\headermenu/$(printf '%s\n' "${header_menu}" | sed -e 's/[\/&]/\\&/g')/g" {} \;
        else
            echo "      Can't generate HTML File for ${md_file}, Check the 'routes.conf'."
        fi
    done
    
    echo "------------------------------------------------------------------"
    echo -e "\x1b[1m2) Checking menus...\x1b[m"

    IFS=$'\n' sorted_posts=($(sort -k3 -r <<<"${unsorted_posts[*]}")); 
    unset IFS
}



function generateRSS() {
    items=""
    for post in "${sorted_posts[@]}"; do
        read -r -a parts <<< "$post"
        local slug="${parts[0]}"
        local menu="${parts[1]}"
        local title=$(echo "$slug" | tr "-" " ")
        local creation_date="${parts[2]}"
        local link="${BASE_URL}/${menu}/${slug}.html"
        local date=$(date -r "${creation_date}")
        local menu_type=$(grep -E "^$menu=" "$ROUTES_CONF" | cut -d= -f2)

        if [[ $slug != $menu && $menu_type == "multiple" ]]; then 
            local summary=$(getSummary "$slug")
            local src="${BUILD_DIRECTORY}/assets/$(getThumbnail "$slug")"

            description="<![CDATA[$summary]]>"

            if [[ -f "$src" ]]; then
                description="<![CDATA[<img src='${BASE_URL}/$(getThumbnail "$slug")' alt='이미지' />$summary]]>"
            fi

            item=$(echo "$ITEM_TEMPLATE" | sed -e "s#{{TITLE}}#$title#g" \
                                                -e "s#{{LINK}}#$link#g" \
                                                -e "s#{{THUMBNAIL}}#$thumbnail#g" \
                                                -e "s#{{DESCRIPTION}}#$description#g" \
                                                -e "s#{{DATE}}#$date#g" \
                                                -e "s#{{CATEGORY}}#$menu#g" \
                                                -e "s#{{GUID}}#$link#g" \
                                                -e "s#{{ATOM_LINK}}#$link#g")
            items+="$item\n"
        fi
    done

    RESULT=$(echo "$RSS_TEMPLATE" | sed "s#{{ITEMS}}#$items#g")
    
    echo "$RESULT" > "${BUILD_DIRECTORY}/rss.xml"
}


function getCreationDate() {
    for line in "${sorted_posts[@]}"; do
        read -r -a parts <<< "$line"
        local slug="${parts[0]}"
        local creation_date="${parts[2]}"
        
        if [[ $slug == $1 ]]; then
            echo $creation_date
        fi
    done
}

function getModificationDate() {
    for line in "${sorted_posts[@]}"; do
        read -r -a parts <<< "$line"
        local slug="${parts[0]}"
        local modification_date="${parts[3]}"
        
        if [[ $slug == $1 ]]; then
            echo $modification_date
        fi
    done
}

function generatePostsList() {
    read -r -a menus_list <<< "$(generateMenusList)"
    for menu_info in "${menus_list[@]}"; do
        IFS='=' read -r menu type <<< "$menu_info"

        local post_count=0

        if [[ $type == "multiple" ]]; then 
            build_menu_folder="${BUILD_DIRECTORY}/${menu}"

            posts_ul="<ul class="$menu-list">"
            for each in "${sorted_posts[@]}"; do
                read -r -a parts <<< "$each"
                local md_slug="${parts[0]}"
                local md_title=$(echo "$md_slug" | tr "-" " ")
                local md_menu="${parts[1]}"
                local md_creation_date="${parts[2]}"
                local md_file="${md_slug}.md"
                
                if [[ $menu == $md_menu && $menu != $md_slug ]]; then
                    date=$(date -r "${md_creation_date}" "+%Y-%m-%d %H:%M:%S")
                    posts_ul+="<li data-date="$md_creation_date"><a class="title" href=\"./${md_slug}.html\">${md_title}</a><span class="date"> - ${date}</span></li>"
                    ((post_count++))
                fi
            done
            posts_ul+="</ul>"

            echo "  • $menu - total $post_count"

            if [[ $post_count != 0 ]]; then
                sed -i '' -e "s/\postslist/$(printf '%s\n' "$posts_ul" | sed -e 's/[\/&]/\\&/g')/g" "${build_menu_folder}/index.html"
            else 
                sed -i '' -e "s/\postslist/$(printf '%s\n' "<p><i>nothing posted yet</i></p>" | sed -e 's/[\/&]/\\&/g')/g" "${build_menu_folder}/index.html"
            fi
        fi
    done
}

initialDirectories
generateHTMLPages
generateRSS
generatePostsList


end_time=$(date +%s)
duration=$((end_time - start_time))

echo "------------------------------------------------------------------"
echo ""
echo "done!"
echo " "
echo "------------------------------------------------------------------"
echo " "
echo -e "\x1b[1mFollowing files are generated:\x1b[m"
echo " "
find $BUILD_DIRECTORY
echo " "
echo -e "\x1b[1mIt took about ${duration} seconds 👀\x1b[m"
echo " "
echo -e "Check directory '\x1b[1m"${BUILD_DIRECTORY}"\x1b[m' to start your blog. Enjoy 🤟"
echo ""
echo "------------------------------------------------------------------"
