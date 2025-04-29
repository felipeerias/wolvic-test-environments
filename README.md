# wolvic-test-environments

Test environments for the Wolvic Web browser for VR.

## Procedure

To get started, you will need a set of 6 PNG images forming a cubemap.

If instead of a cubemap you have one large panorama image, you can convert it with this tool:https://jaxry.github.io/panorama-to-cubemap/

The source files must have the following names: `negx.png`, `negy.png`, `negz.png`, `posx.png`, `posy.png`, `posz.png`.


```shell
# Define the environment's id
ENVNAME=myenvironment

# Clean up
rm *.ktx *_srgb.png *.zip

# Resize and zip the original PNG images
mogrify -resize 1024x1024! *.png
zip ${ENVNAME}_misc.zip *.png 

# KTX textures
for f in *.png; do mipgen -f ktx -m 1 -c etc_rgb8_rgba_100 --strip-alpha "$f" "$(basename "${f%.*}").ktx"; done
zip "${ENVNAME}.zip" *.ktx

# KTX textures in sRGB color format
for f in *.png; do mipgen -f ktx -m 1 -c etc_srgb8_rgba_100 --strip-alpha "$f" "$(basename "${f%.*}")_srgb.ktx"; done
zip ${ENVNAME}_ktx_srgb.zip *_srgb.ktx

# PNG images in sRGB color format
for file in *.png; do convert "$file" -colorspace sRGB "${file%.png}_srgb.png"; done
zip ${ENVNAME}_misc_srgb.zip *_srgb.png

# Thumbnail
convert posx.png -resize 512x512 -gravity Center -crop 256x256+0+0 ${ENVNAME}.png

# Copy to a new folder in this project
mkdir ../wolvic-test-environments/${ENVNAME}
cp ${ENVNAME}.png *.zip ../wolvic-test-environments/${ENVNAME}

# Finally, remember to update props.json
```

## Environments

### Shipped

|    | ID | Title | Author | License |
| -- | -- | ----- | ------ | ------- |
| ![](myzithres/myzithres.png) | `myzithres` | [Myzithres rocks](https://www.flickr.com/photos/herbraab/53768758722/) | **H. Raab** | CC BY-NC-ND | 
| ![](arkongel/arkongel.png) | `arkongel` | [Kleiner Ankogel](https://www.flickr.com/photos/herbraab/53864577512/) | **H. Raab** | CC BY-NC-ND |
| ![](kaiwi/kaiwi.png) | `kaiwi` | [Ka'iwi Coast](https://www.flickr.com/photos/kanalu/31192933158/) | **Kaleomokuokanalu Chock** | CC BY-NC-SA |
| ![](valleyoffire/valleyoffire.png) | `valleyoffire` | [Valley of Fire State Park](https://www.flickr.com/photos/54144402@N03/31271410664) | **Bob Cass** | CC BY |
| ![](lobos/lobos.png) | `lobos` |  [Lobos, Fuerteventura](https://www.flickr.com/photos/simonwaldherr/51638698181/) | **Simon Waldherr** | CC BY-NC-SA |
| ![](nostalgiablue/nostalgiablue.png) | `nostalgiablue` |  [Colors of Nostalgia (Blue)](https://www.flickr.com/photos/thelastminute/52426821655/) | **Duncan Rawlinson** | CC BY-NC |
| ![](nostalgiaorange/nostalgiaorange.png) | `nostalgiaorange` |  [Colors of Nostalgia (Orange)](https://www.flickr.com/photos/thelastminute/52425863182) | **Duncan Rawlinson** | CC BY-NC |
| ![](fantasylandscape3/fantasylandscape3.png) | `fantasylandscape3` |  [Fantasy Landscape 2](https://sketchfab.com/3d-models/fantasy-landscape-3-ded6e2bb0cfd4ef785b81fed2178c2fd) | Giimann | CC BY |
| ![](goatrock/goatrock.png) | `goatrock` | [Goat Rock State Beach](https://www.flickr.com/photos/54144402@N03/49263489461/) | **Bob Dass** | CC BY |
| ![](kinderdijk/kinderdijk.png) | `kinderdijk` | [Kinderdijk](https://flickr.com/photos/aldo/4584265973/) | **Aldo Hoeben** | CC BY-NC | 
| ![](wadakura/wadakura.png) | `wadakura` | [Wadakura fountain park](https://www.flickr.com/photos/heiwa4126/4231022562/) | **heiwa4126** | CC BY |
| ![](notredameparis/notredameparis.png) | `notredameparis` | [ Notre-Dame de Paris](https://www.flickr.com/photos/gadl/403173357/) | **Alexandre Duret-Lutz** at Flickr | CC BY-SA |  
| ![](japanesegarden/japanesegarden.png) | `japanesegarden` | [Japanese Garden](https://www.flickr.com/photos/vitroids/48868845128/) | **Masakazu Matsumoto** at Flickr | CC BY |  
| ![](doublearch/doublearch.png) | `doublearch` | [Double Arch](https://www.flickr.com/photos/vitroids/48822338172/) | **Masakazu Matsumoto** at Flickr | CC BY |  
| ![](ploumanach/ploumanach.png) | `ploumanach` | [Ploumanac'h](https://www.flickr.com/photos/gadl/22026335904/) | **Alexandre Duret-Lutz** at Flickr | CC BY-NC-SA |  
| ![](tullinge/tullinge.png) | `tullinge` | [Tullinge](https://www.flickr.com/photos/simoninns/24120710880/) | **Simon Inns** at Flickr | CC BY | 
| ![](meadow/meadow.png) | `meadow` | [_Meadow_](https://polyhaven.com/a/meadow_2) | **Sergej Majboroda** at Poly Haven | CC0 |
| ![](abovetheclouds/abovetheclouds.png) | `abovetheclouds` | [_Above The Clouds_](https://sketchfab.com/3d-models/free-skybox-above-the-clouds-77e196f5089040ffb7b4d32c6a3fc035) | **Paul** at Sketchfab | CC BY |
| ![](milkyway2020/milkyway2020.png) | `milkyway2020` | [_Milky Way (2020)_](https://svs.gsfc.nasa.gov/3895) | **NASA/Goddard Space Flight Center** |  |
| ![](autumnforest/autumnforest.png) | `autumnforest` | [_Autumn Forest_](https://sketchfab.com/3d-models/free-skybox-autumn-forest-3ba29976640c4b26a66d6cea0556b7d6) | **Paul** at Sketchfab | CC BY |
| ![](basicsky/basicsky.png) | `basicsky` | [_Basic Sky_](https://sketchfab.com/3d-models/free-skybox-basic-sky-b2a4fd1b92c248abaae31975c9ea79e2) | **Paul** at Sketchfab | CC BY |
| ![](bcnrooftop/bcnrooftop.png) | `bcnrooftop` | [_Barcelona Rooftops_](https://sketchfab.com/3d-models/sky-pano-barcelona-rooftops-0f836cdac86441ec93593620c71ec3d6) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](nightforest/nightforest.png) | `nightforest` | [_Night Forest With Aurora Sky_](https://sketchfab.com/3d-models/sky-box-8k-night-forest-scene-with-aurora-sky-a626c2f3eda14177b07f9c345a17df60) | **Architecture_Interior** at Sketchfab | CC BY |
| ![](pretvillecinema/pretvillecinema.png) | `pretvillecinema` | [_Pretville Cinema_](https://polyhaven.com/a/pretville_cinema) | **D. Savva and J. Guest** at Poly Haven | CC0 |
| ![](winternight/winternight.png) | `winternight` | [_Winter Night_](https://sketchfab.com/3d-models/free-skybox-winter-night-9cf1663e9a8647b987ce4f439c22ff50) | **Paul** at Sketchfab | CC BY |

### Candidates

|    | ID | Title | Author | License |
| -- | -- | ----- | ------ | ------- |
| ![](kingstheatre/kingstheatre.png) | `kingstheatre` | [_Kings Theatre_](https://www.flickr.com/photos/jamescastle/29745666664/) | **jeremy Seto** | CC BY-NC-SA |
| ![](klippenrandweg/klippenrandweg.png) | `klippenrandweg` | [_Klippenrandweg_04_](https://www.flickr.com/photos/165401243@N04/45103062855) | **j.nagel** | CC BY-NC |
| ![](lakeside/lakeside.png) | `lakeside` | [_Lakeside Night_](https://polyhaven.com/a/lakeside_night) | **Greg Zaal, Jarod Guest** | CC0 |
| ![](rogland/rogland.png) | `rogland` | [_Rogland Clear Night_](https://polyhaven.com/a/rogland_clear_night) | **Greg Zaal** | CC0 |
| ![](unitedpalace/unitedpalace.png) | `unitedpalace` | [_United Palace_](https://www.flickr.com/photos/jamescastle/30358909365/) | **jeremy Seto** | CC BY-NC-SA |
| ![](infrareddunes/infrareddunes.png) | `infrareddunes` | [Infrared dunes](https://flickr.com/photos/aldo/2632881467/) | **Aldo Hoeben** | CC BY-NC |
| ![](morningsun/morningsun.png) | `morningsun` | [Morning sun in the trees](https://flickr.com/photos/aldo/2129900916/) | **Aldo Hoeben** | CC BY-NC |
| ![](navagio/navagio.png) | `navagio` | [Navagio](https://www.flickr.com/photos/herbraab/53760633242/) | **H. Raab** | CC BY-NC-ND | 
| ![](sauofen/sauofen.png) | `sauofen` | [Kleiner Sauofen](https://www.flickr.com/photos/herbraab/53487123953/) | **H. Raab** | CC BY-NC-ND | 
| ![](schiermonnikoogsunset/schiermonnikoogsunset.png) | `schiermonnikoogsunset` | [Sunset](https://flickr.com/photos/aldo/2645748198/) | **Aldo Hoeben** | CC BY-NC | 
| ![](zakynthos/zakynthos.png) | `zakynthos` | [Zakynthos rock cliff](https://www.flickr.com/photos/herbraab/53766860256/) | **H. Raab** | CC BY-NC-ND | 
| ![](winterforest/winterforest.png) | `winterforest` | [_Winter Forest_](https://sketchfab.com/3d-models/sky-pano-winter-forest-b42c27358ab04e8885ffb2ecf69c352c) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](malibuoverlook/malibuoverlook.png) | `malibuoverlook` | [_Malibu Overlook_](https://sketchfab.com/3d-models/sky-pano-malibu-overlook-8ef3cf8d717d4598a661e41fc2a7097f) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](monumentvalley/monumentvalley.png) | `monumentvalley` | [_Monument Valley Lookout_](https://sketchfab.com/3d-models/sky-pano-monument-valley-lookout-b9ead322f9bd40ec8eb6a2d33908e592) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](milkyway/milkyway.png) | `milkyway` | [_Milkyway_](https://sketchfab.com/3d-models/sky-pano-milkyway-0016725c047a4ea18cd0b5e5ef2fe441) | **MozillaHubs** at Sketchfab | CC BY-NC-SA |
| ![](animesky/animesky.png) | `animesky` | [_Anime Sky_](https://sketchfab.com/3d-models/free-skybox-anime-sky-56a60c1d1e8b44eabff138374f996d8f) | **Paul** at Sketchfab | CC BY |
| ![](snowycabin/snowycabin.png) | `snowycabin` | [_Snowy Cabin_](https://sketchfab.com/3d-models/free-skybox-snowy-cabin-c672c14f6aa64af89b1f52d6d1ac8b24) | **Paul** at Sketchfab | CC BY |
| ![](futuristiccity/futuristiccity.png) | `futuristiccity` | [_Rooftops Futuristic City_](https://sketchfab.com/3d-models/free-skybox-rooftops-futuristic-city-9b65d7f199a74f1dadef76a438244502) | **Paul** at Sketchfab | CC BY |
| ![](fairytalegarden/fairytalegarden.png) | `fairytalegarden` | [_Fairytale_Garden_](https://sketchfab.com/3d-models/fairytale-garden-bc4b1df99f764a7384870dd64ed47313) | **Giimann** at Sketchfab | CC BY |
| ![](fantasylandscape3/fantasylandscape3.png) | `fantasylandscape3` | [_Fantasy Landscape 3_](https://sketchfab.com/3d-models/fantasy-landscape-3-ded6e2bb0cfd4ef785b81fed2178c2fd) | **Giimann** at Sketchfab | CC BY |
| ![](lowpolyroom/lowpolyroom.png) | `lowpolyroom` | [_Stylized Room_](https://sketchfab.com/3d-models/skybox-stylized-room-41f386740dbb4de7af2724734f98151f) | **Van_Twinkle** at Sketchfab | CC BY |
| ![](tychoskymap/tychoskymap.png) | `tychoskymap` | [_Tycho Catalog Skymap_](https://svs.gsfc.nasa.gov/3895) | **NASA/Goddard Space Flight Center** |  |
| ![](hayloft/hayloft.png) | `hayloft` | [_Hayloft_](https://polyhaven.com/a/hayloft) | **Adrian Kubasa** at Poly Haven | CC0 |
| ![](dolceaqua/dolceaqua.png) | `dolceaqua` | [Dolceacqua, Impera, Italia](https://www.flickr.com/photos/sitoo/36240831915/) | **Sitoo** at Flickr | CC BY-NC-ND |  
| ![](gruyeres/gruyeres.png) | `gruyeres` | [Château de Gruyères](https://www.flickr.com/photos/gadl/11210239776/) | **Alexandre Duret-Lutz** at Flickr | CC BY-NC-SA |  
| ![](ricefields/ricefields.png) | `ricefields` | [Rice Fields of Japan](https://www.flickr.com/photos/heiwa4126/3662789054/) | **heiwa4126** at Flickr | CC BY |  
| ![](traintracks/traintracks.png) | `traintracks` | [Train Tracks](https://www.flickr.com/photos/eminbiole/36565746090/) | **Eric Minbiole** at Flickr | CC BY-NC |  

## Testing

To test these environments on Wolvic 1.5.1, replace the value of the build variable `PROPS_ENDPOINT` in `app/build.gradle` with `"https://darker.ink/wolvic-test-environments/props.json"` and recompile.

```
buildConfigField 'String', 'PROPS_ENDPOINT', '"https://darker.ink/wolvic-test-environments/props.json"'
```

