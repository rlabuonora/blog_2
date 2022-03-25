---
title: Barrios ricos y pobres de Montevideo
author: ''
date: '2019-04-13'
slug: []
categories: []
tags: []
images: []
---


Todas las ciudades tienen zonas ricas y zonas pobres. En Montevideo, las zonas costeras concentran los hogares de mayores ingresos (Carrasco, Punta Gorda, Malvín, Pocitos, etc.). 

En este post armo un mapa para visualizar cuáles son los barrios con mayores ingresos en las ciudades de Uruguay. 


```
## OGR data source with driver: ESRI Shapefile 
## Source: "C:\Users\rlabuonora\Documents\blog_2\content\posts\2019-04-13-barrios-ricos-y-pobres-de-montevideo\ine_seg_11", layer: "ine_seg_11"
## with 4313 features
## It has 13 fields
```

```
## [1] ""
```



<!-- En este post quiero visualizar la distribución del ingreso en las ciudades de Uruguay. En Montevideo sabemos que la zona costera es donde se concentran los hogares de mayores ingresos  -->

<!-- Para visualizar esta estructura, linkeo los datos de la [Encuesta Continua de Hogares](http://ine.gub.uy/web/guest/encuesta-continua-de-hogares1) con un mapa de los segmentos censales del país. -->

<!-- TODO: Refactor using chunk names -->
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-1-1.png" width="672" />

# Las Zonas Censales
La información geográfica puede venir en formato `raster` o en formato `shapefile`. Un objeto `raster` es una grilla de números, y cada celda de la grilla está georeferenciada a una parte de la superficie de la tierra. Los shapefiles son una forma de almacenar datos de formas, que pueden representar entidades geográficas físicas o imaginarias (ríos, países, etc.)

El INE [publica shapefiles](http://ine.gub.uy/mapas-vectoriales) con las formas de los segmentos censales que usa para muestrear la Encuesta de Hogares. En Uruguay hay `nrow(ine_seg_11_sf)` segmentos censales.

La librería sf tiene un montón de herramientas para trabajar con datos geográficos. La mejor fuente que conozco para aprender más es [Geocomputation with R](https://geocompr.robinlovelace.net/). 


```r
library(sf)

# Cargar mapa
ine_seg_11_sf <- st_read('./ine_seg_11/ine_seg_11.shp')
```

```
## Reading layer `ine_seg_11' from data source 
##   `C:\Users\rlabuonora\Documents\blog_2\content\posts\2019-04-13-barrios-ricos-y-pobres-de-montevideo\ine_seg_11\ine_seg_11.shp' 
##   using driver `ESRI Shapefile'
## Simple feature collection with 4313 features and 13 fields
## Geometry type: MULTIPOLYGON
## Dimension:     XY
## Bounding box:  xmin: 366582.2 ymin: 6127919 xmax: 858252.1 ymax: 6671738
## CRS:           NA
```

```r
# asignar crs
st_crs(ine_seg_11_sf) <- "+proj=utm +zone=21 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
ine_seg_11_sf <- st_transform(ine_seg_11_sf, crs=4326)
class(ine_seg_11_sf)
```

```
## [1] "sf"         "data.frame"
```


```r
plot(st_geometry(ine_seg_11_sf))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-3-1.png" width="672" />

## Calculamos las medianas
Para calcular el ingreso en cada segmento censal, usamos los datos de la Encuesta Continua de Hogares. Los microdatos incluyen el segmento censal de cada hogar y una estimación de su ingreso. `dplyr` hace muy fácil calcular la mediana del ingreso de los hogares encuestados:

```r
Sys.setlocale("LC_ALL", "UTF-8")
```

```
## [1] ""
```

```r
medianas <- ingresos_ech %>% 
  group_by(depto_id, seccion_id, segmento_id) %>% 
  summarize(mediana = median(ingreso))
```

## Linkear los datos al mapa

Para visualizar todo en un mapa, hay que linkear los datos con el dataframe de los segmentos censales. Agregarle atributos no espaciales a un objeto `sf` es simple, ya que se comportan como `data.frames` y soportan las funciones del `tidyverse`, por lo que podemos usar `left_join` con `depto_id`, `seccion_id` y `segmento_id` como identificadores:


```r
ine_seg_11_sf <- ine_seg_11_sf %>% 
  left_join(medianas, by=c("DEPTO" = "depto_id",
                           "SECCION" = "seccion_id",
                           "SEGMENTO" = "segmento_id"))
```


## Elegir una localidad

Como queremos mapear los ingresos en cada ciudad, tenemos que encontrar una forma de seleccionar una zona del mapa. Para esto podemos usar `filter` y seleccionar los polígonos que pertenecen a cierta localidad`:


```r
# Montevideo es la localidad 1020
cod_loc <- "1020"
mapa_loc <- filter(ine_seg_11_sf, CODLOC==cod_loc)
plot(st_geometry(mapa_loc))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-6-1.png" width="672" />

## Agregar mapa de fondo

Este mapa funciona bien si conocemos la ciudad, pero para zonas geográficas no tan familiares puede ser conveniente agregar referencias como calles importantes o cuerpos de agua. 

Para eso podemos usar google maps, que publica una API con mapas basadas en imágenes satelitales.Para consumir la API, es necesario registrarse y darles una tarjeta de crédito 👎 para obtener una clave. [Acá](https://cran.r-project.org/web/packages/httr/vignettes/secrets.html). hay más info sobre como trabajar con API keys en R.


```r
library(ggmap)
# Leer la API key de variable de environment
API_KEY <- Sys.getenv("GOOGLE_API")
# Loguearse a la API
register_google(API_KEY)
```
Para bajar el mapa de Google Maps, necesitamos las coordenadas del mapa que vamos a dibujar. Para obtener estas coordenadas, subseteo el mapa original con el código de la localidad que quiero mapear y obtengo las coordenadas del mapa subseteado.


```r
cod_loc <- "1020"
mapa_loc <- filter(ine_seg_11_sf, CODLOC==cod_loc)

bbox <- st_bbox(mapa_loc) %>%
   setNames(c("left", "bottom", "right", "top"))

mapa <- get_map(location=bbox)
```
Para poder dibujar este mapa con `tmap`, tengo que convertirlo a un `Raster` con la función `ggmap_rast`.


```r
# https://gis.stackexchange.com/questions/155334/ggmap-clip-a-map
library(raster)
library(tmap)

ggmap_rast <- function(map) {
  map_bbox <- attr(map, 'bb')
  .extent <- extent(as.numeric(map_bbox[c(2,4,1,3)]))
  my_map <- raster(.extent, nrow= nrow(map), ncol = ncol(map))
  rgb_cols <- setNames(as.data.frame(t(col2rgb(map))), c('red','green','blue'))
  red <- my_map
  values(red) <- rgb_cols[['red']]
  green <- my_map
  values(green) <- rgb_cols[['green']]
  blue <- my_map
  values(blue) <- rgb_cols[['blue']]
  stack(red,green,blue)
}

mapa_raster <- ggmap_rast(mapa)
```

Ahora que tengo el `Raster`, los polígonos de los segmentos censales y la estimación de las medianas, podemos hacer un mapa en capas con `tmap`:

```r
tmap_options(check.and.fix = TRUE)

tm_shape(mapa_raster) +
  tm_rgb() +
  tm_shape(mapa_loc) +
  tm_fill(col="mediana",
          style="quantile",
          title = "Ingreso",
          textNA = "S/D",
          alpha = 0.75) +
  tm_layout("Montevideo",
            frame = FALSE,
            legend.position = c("right", "bottom"),
            legend.format = list(
              "text.separator" = "-"
            )) +
  tm_legend(show=FALSE)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-10-1.png" width="672" />


<!-- # Otras localidades -->

<!-- `tmap` nos permite dibujar un mapa con todos los elementos que vinimos desarrollando en distintas capas. También tiene una función que permite armar grillas de mapas. -->

<!-- Podemos hacer el mismo mapa para otras localidades: -->

<!-- ```{r} -->

<!-- # salto: 15120 -->
<!-- mapa_loc <- filter(ine_seg_11_sf, CODLOC=="15120") -->
<!-- bbox <- st_bbox(mapa_loc) %>% -->
<!--     setNames(c("left", "bottom", "right", "top")) -->

<!-- mapa_raster <- get_map(location=bbox) %>% -->
<!--     ggmap_rast() -->

<!-- mapa_salto <- tm_shape(mapa_raster) + -->
<!--     tm_rgb() + -->
<!--     tm_shape(mapa_loc) + -->
<!--     tm_fill(col="mediana", -->
<!--           style="quantile", -->
<!--           title = "Ingreso", -->
<!--           textNA = "S/D", -->
<!--           alpha = 0.75) + -->
<!--   tm_layout("Salto", -->
<!--             frame = FALSE, -->
<!--             legend.position = legend_pos, -->
<!--             legend.format = list( -->
<!--               "text.separator" = "-" -->
<!--             )) -->
<!-- ``` -->

<!-- ```{r} -->
<!-- # Durazno: 6220 -->
<!-- mapa_loc <- filter(ine_seg_11_sf, CODLOC=="6220") -->
<!-- bbox <- st_bbox(mapa_loc) %>% -->
<!--     setNames(c("left", "bottom", "right", "top")) -->

<!-- mapa_raster <- get_map(location=bbox) %>% -->
<!--     ggmap_rast() -->

<!-- mapa_durazno <- tm_shape(mapa_raster) + -->
<!--     tm_rgb() + -->
<!--     tm_shape(mapa_loc) + -->
<!--     tm_fill(col="mediana", -->
<!--           style="quantile", -->
<!--           title = "Ingreso", -->
<!--           textNA = "S/D", -->
<!--           alpha = 0.75) + -->
<!--   tm_layout("Durazno", -->
<!--             frame = FALSE, -->
<!--             legend.position = legend_pos, -->
<!--             legend.format = list( -->
<!--               "text.separator" = "-" -->
<!--             )) -->
<!-- ``` -->
<!-- Para sacar varios mapas a la vez podemos combinar `tmap_arrange` con esta función: -->
<!-- ```{r} -->
<!-- tmap_arrange( -->
<!--             mapa_salto, -->
<!--             mapa_durazno, -->
<!--             ncol = 1) -->
<!-- ``` -->

