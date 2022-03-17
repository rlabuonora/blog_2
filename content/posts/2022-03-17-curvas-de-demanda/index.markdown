---
title: Curvas de Demanda
author: ''
date: '2022-03-17'
slug: []
categories: []
tags: []
images: []
draft: true
---




Estoy tratando de replicar este gráfico en `ggplot`:

![](grafico_bezier.png)

El problema es similar a [este](https://stackoverflow.com/questions/39820118/how-can-i-view-the-computed-varialbles-computed-by-ggplot2-geom-boxplot), pero no entiendo bien la solucion.

El principal problema que tengo es dibujar las curvas de demanda. Estas curvas pasan por ciertos puntos en el plano `(Q, P)`. Esto sugiere usar `geom_segment`, pero las curvas del segundo y tercer gráfico no son rectas.

La segunda idea es usar una función que interpole un polinomio a los dos puntos. La diferencia entre interpolar y aproximar es que si aproximamos el polinomio no pasa exactamente por esos puntos por lo que no nos sirve.

Para interpolar un polinomio entre dos puntos tuve dos problemas. La interpolación de Lagrange que hace `splinefun` por dos puntos es una recta. No sé cómo interpolar un modelo cuadrático a dos puntos, todos me dan una recta.

La solución final es usar una curva bezier. `ggforce` tiene `geom_bezier` para esto. Esta solución tiene la desventaja que tenemos que elegir los puntos de control a mano, pero los resultados finales se ven bien. 

Para dibujar una curva bezier precisamos dos endpoints y uno o dos puntos de control. La línea une los dos endpoints, y la curvatura viene dada por los puntos de control. [Acá está bien explicado](https://ggforce.data-imaginist.com/reference/geom_bezier.html).

Para dibujar la primera curva de demanda, los dos endpoints son `\((1, 1000)\)` y `\((3, 500)\)`. La curva tiene una curvatura leve hacia el orígen, así que elegí `\((1.5, 750)\)`.


```r
library(ggforce)
```

```
## Warning: package 'ggforce' was built under R version 4.0.5
```

```r
library(tibble)
```

```
## Warning: package 'tibble' was built under R version 4.0.5
```

```r
x1 <- c(1, 1.5, 3)
y1 <- c(1e3, 750, 5e2)

df <- tibble(x=x1, y=y1, point_type=c("end", "control", "end"))


plt <- ggplot(df, aes(x, y)) + 
  geom_point(data=dplyr::filter(df, point_type=="end")) +
  geom_bezier() 

plt
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-1-1.png" width="672" />

El problema ahora es que la curva no se extiende más allá de los endpoints, y que no tengo una representación que sea fácil de manipular (por ejemplo, para encontrar donde se corta con otra curva). Este punto no es relevante para este ejemplo pero es clave en otros gráficos que estoy tratando de dibujar.

Para solucionar esto, lo que hago es acceder a los datos de la curva bezier que dibuja `geom_bezier`, y usarlos para interpolar un modelo cuadrático (ahora si puedo porque tengo más de dos puntos).


```r
plt <- ggplot(df, aes(x, y)) + 
  geom_point(data=dplyr::filter(df, point_type=="end")) +
  geom_bezier() 

bezier_data <- layer_data(plt, 2)
curva <- splinefun(bezier_data$x, bezier_data$y)

plt + 
  geom_function(fun=curva) + 
  scale_x_continuous(limits = c(0, 3.5)) + 
  scale_y_continuous(limits = c(0, 1100))
```

```
## Warning: Removed 24 row(s) containing missing values (geom_path).
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-2-1.png" width="672" />

Ahora si puedo hacer el gráfico completo:


```r
x1 <- c(1, 1.5, 3)
y1 <- c(1e3, 750, 5e2)

df <- tibble(x=x1, y=y1, point_type=c("end", "control", "end"))

plt <- ggplot(df, aes(x, y)) + 
  geom_point(data=dplyr::filter(df, point_type=="end")) +
  geom_bezier() 

bezier_data <- layer_data(plt, 2)
curve <- splinefun(bezier_data$x, bezier_data$y)

plt + 
  geom_function(fun=curve, xlim=c(.75, 3.25), size=.5, linetype="solid") + 
  geom_segment(x=0, y=0, xend=0, yend=1200) + 
  geom_segment(x=0, y=0, xend=3.5, yend=0) + 
  annotate("text", label="P", x=0, y=1300, size=5) +
  annotate("text", label="Q", x=3.75, y=0, size=5) +
  scale_x_continuous(breaks=1:3,
                     expand = expansion(mult=0, add=c(0, .5))) + 
  scale_y_continuous(breaks=c(0, 500, 1000),
                     expand=expansion(mult=0, add=c(0, 200))) + 
  labs(x="Quantity (millions)", y="Price (dollars)") + 
  coord_cartesian(xlim=c(0, 3.5),
                  ylim=c(0, 1200), clip="off") +
  theme(axis.ticks = element_blank()) + 
  theme_minimal(base_size=14)
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-3-1.png" width="672" />

